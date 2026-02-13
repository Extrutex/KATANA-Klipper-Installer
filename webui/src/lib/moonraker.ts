import { useState, useEffect } from 'react';
import { WebsocketSupervisor } from './core/websocket-supervisor';
import { PrinterStateMachine } from './core/printer-state-machine';
import type { ConnectionState, PrinterState } from './core/schema';
import { ServiceHealthStore } from './core/service-health';
import type { SystemHealthState } from './core/service-health';
import { DiagnosticsStore } from './core/diagnostics-store';
import type { DiagnosticAlert } from './core/diagnostics-store';

// Re-export types for consumers
export type { ConnectionState, PrinterState, SystemHealthState, DiagnosticAlert };

// --- Configuration ---
const getMoonrakerUrl = () => {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const hostname = window.location.hostname;
    const port = window.location.port ? window.location.port : '7125';

    // Check overrides
    const urlParams = new URLSearchParams(window.location.search);
    const overrideHost = urlParams.get('host');

    if (overrideHost) {
        return `${protocol}//${overrideHost}/websocket`;
    } else if (port === '5173' || port === '5174') {
        return `ws://${hostname}:7125/websocket`; // Dev
    } else {
        return `${protocol}//${hostname}:${window.location.port}/websocket`; // Prod
    }
};

class HorizonClient {
    public supervisor: WebsocketSupervisor;
    public store: PrinterStateMachine;
    public health: ServiceHealthStore;
    public diagnostics: DiagnosticsStore;

    constructor() {
        this.store = new PrinterStateMachine();
        this.supervisor = new WebsocketSupervisor({
            url: getMoonrakerUrl()
        });

        // Initialize Health Store (depends on Supervisor for polling)
        this.health = new ServiceHealthStore(this.supervisor);

        // Initialize Diagnostics (aggregates all)
        this.diagnostics = new DiagnosticsStore(this.supervisor, this.store, this.health);

        this.supervisor.onMessageRaw(this.handleMessage.bind(this));
        this.supervisor.onStateChange(this.handleConnectionChange.bind(this));
    }

    public connect() {
        this.supervisor.connect();
    }

    public sendGCode(script: string) {
        this.supervisor.send({
            jsonrpc: "2.0",
            method: "printer.gcode.script",
            params: { script },
            id: Math.floor(Date.now() / 1000)
        });
        // Optimistic log add? No, wait for response/event in strict mode.
        // For now we just send.
    }

    public send(payload: any) {
        this.supervisor.send(payload);
    }

    private handleConnectionChange(state: ConnectionState) {
        if (state === 'ONLINE') {
            // Subscribe to GCode responses
            this.supervisor.send({
                jsonrpc: "2.0",
                method: "printer.gcode.subscribe",
                params: {},
                id: 99
            });

            // Subscribe to objects on connect
            this.supervisor.send({
                jsonrpc: "2.0",
                method: "printer.objects.subscribe",
                params: {
                    objects: {
                        toolhead: ["position", "max_velocity", "max_accel", "status", "print_time", "estimated_print_time"],
                        heater_bed: ["temperature", "target", "power"],
                        extruder: ["temperature", "target", "power"],
                        webhooks: ["state", "state_message"],
                    }
                },
                id: 1
            });

            // Initial Query
            this.supervisor.send({
                jsonrpc: "2.0",
                method: "printer.objects.query",
                params: {
                    objects: {
                        toolhead: null,
                        heater_bed: null,
                        extruder: null,
                        webhooks: null
                    }
                },
                id: 2
            });
        }
    }

    private handleMessage(data: any) {
        // 1. Status Updates
        if (data.method === "notify_status_update") {
            this.store.handleStatusUpdate(data.params);
        }

        // 2. Query Responses
        if (data.id === 2 && data.result) {
            this.store.handleObjectsQuery(data.result);
        }

        // 3. GCode Response
        if (data.method === "notify_gcode_response") {
            const response = data.params[0];
            const isError = response.startsWith("!!") || response.toLowerCase().includes("error");
            addGCodeLog(response, isError ? 'error' : 'response');
        }

        // 4. Delegate to Health Store for proc_stats
        this.health.handleMessage(data);
    }
}

export const client = new HorizonClient();

// --- React Hooks ---

export const useKatanaLink = () => {
    // Legacy Hook Adapter
    const [state, setState] = useState<PrinterState>(client.store.getState());
    const [conn, setConn] = useState<ConnectionState>(client.supervisor.getState());
    // Also grab health for legacy system info mapping if needed?
    // For now we keep it simple.

    useEffect(() => {
        client.connect();
        const unsubStore = client.store.subscribe(setState);
        const unsubConn = client.supervisor.onStateChange(setConn);
        return () => { unsubStore(); unsubConn(); };
    }, []);

    // Merge Connection Status into Printer Status for backward compatibility with 'printer.status' checks
    // The old code expected printer.status to be 'offline' if disconnected.
    // Our new PrinterState has .status as 'startup'|'ready' etc.
    const legacyState: any = { ...state };

    // Inject webhooks info if legacy code looks for it elsewhere? No, old code checked top level.
    // We map legacy .status logic:
    if (conn !== 'ONLINE') {
        legacyState.status = 'offline';
    } else {
        // Map Klipper state to what UI expects if needed, strictly it matches 'startup', 'ready', 'shutdown', 'error'
        // which matches our Schema.
    }

    // Pass through webhooks explicitly for new components
    legacyState.webhooks = state.objects.webhooks;

    return legacyState;
};

export const useServiceHealth = () => {
    const [health, setHealth] = useState<SystemHealthState>(client.health.getState());
    useEffect(() => {
        const unsub = client.health.subscribe(setHealth);
        return () => { unsub(); };
    }, []);
    return health;
};

export const useDiagnostics = () => {
    const [alerts, setAlerts] = useState<DiagnosticAlert[]>(client.diagnostics.getAlerts());
    useEffect(() => {
        const unsub = client.diagnostics.subscribe(setAlerts);
        return () => { unsub(); };
    }, []);
    return alerts;
};

// Log Store for GCode Console
export interface GCodeLog {
    time: number;
    message: string;
    type: 'command' | 'response' | 'error';
}

let globalLogs: GCodeLog[] = [];
let logListeners: ((logs: GCodeLog[]) => void)[] = [];

function addGCodeLog(msg: string, type: 'command' | 'response' | 'error' = 'response') {
    const newEntry: GCodeLog = { time: Date.now(), message: msg, type };
    globalLogs = [...globalLogs.slice(-199), newEntry];
    logListeners.forEach(l => l(globalLogs));
}

export const useGCodeStore = () => {
    const [logs, setLogs] = useState<GCodeLog[]>(globalLogs);

    useEffect(() => {
        const handler = (newLogs: GCodeLog[]) => setLogs(newLogs);
        logListeners.push(handler);
        handler(globalLogs);
        return () => { logListeners = logListeners.filter(l => l !== handler); };
    }, []);

    const addLog = (msg: string, type: 'command' | 'response' | 'error' = 'command') => {
        addGCodeLog(msg, type);
    };

    return { logs, addLog };
};

// Export class usage for non-hook contexts
export class KatanaLink {
    sendGCode(script: string) {
        client.sendGCode(script);
    }
}

