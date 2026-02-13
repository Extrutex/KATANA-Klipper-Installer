import type { WebsocketSupervisor } from './websocket-supervisor';
import type { PrinterStateMachine } from './printer-state-machine';
import type { ServiceHealthStore } from './service-health';

export interface DiagnosticAlert {
    id: string;
    source: 'NETWORK' | 'PRINTER' | 'SYSTEM';
    level: 'INFO' | 'WARN' | 'ERROR';
    message: string;
    timestamp: number;
}

type DiagnosticsListener = (alerts: DiagnosticAlert[]) => void;

export class DiagnosticsStore {
    private alerts: DiagnosticAlert[] = [];
    private listeners: Set<DiagnosticsListener> = new Set();
    private supervisor: WebsocketSupervisor;
    private printer: PrinterStateMachine;
    private health: ServiceHealthStore;

    constructor(
        supervisor: WebsocketSupervisor,
        printer: PrinterStateMachine,
        health: ServiceHealthStore
    ) {
        this.supervisor = supervisor;
        this.printer = printer;
        this.health = health;
        this.init();
    }

    private init() {
        // 1. Network Monitoring
        this.supervisor.onStateChange((state) => {
            if (state === 'DISCONNECTED' || state === 'DEGRADED') {
                this.addAlert({
                    id: 'net_loss',
                    source: 'NETWORK',
                    level: 'ERROR',
                    message: 'Connection to Moonraker lost',
                    timestamp: Date.now()
                });
            } else {
                this.removeAlert('net_loss');
            }
        });

        // 2. Printer Monitoring
        this.printer.subscribe((state) => {
            if (state.status === 'error') {
                // Try to find the detailed message from webhooks
                const msg = state.objects.webhooks?.state_message || "Printer is in Error State";
                this.addAlert({
                    id: 'printer_err',
                    source: 'PRINTER',
                    level: 'ERROR',
                    message: msg,
                    timestamp: Date.now()
                });
            } else if (state.status === 'shutdown') {
                this.addAlert({
                    id: 'printer_shutdown',
                    source: 'PRINTER',
                    level: 'ERROR',
                    message: "MCU Shutdown",
                    timestamp: Date.now()
                });
            } else {
                this.removeAlert('printer_err');
                this.removeAlert('printer_shutdown');
            }
        });

        // 3. System Health Monitoring
        this.health.subscribe((state) => {
            if (state.status !== 'OK') {
                this.addAlert({
                    id: 'sys_warn',
                    source: 'SYSTEM',
                    level: 'WARN',
                    message: `System Logic Load High (CPU: ${state.cpu.usage.toFixed(1)}%)`,
                    timestamp: Date.now()
                });
            } else {
                this.removeAlert('sys_warn');
            }
        });
    }

    public subscribe(listener: DiagnosticsListener) {
        this.listeners.add(listener);
        listener(this.alerts);
        return () => this.listeners.delete(listener);
    }

    public getAlerts() {
        return [...this.alerts];
    }

    private addAlert(alert: DiagnosticAlert) {
        // Prevent dupes by ID
        const idx = this.alerts.findIndex(a => a.id === alert.id);
        if (idx >= 0) {
            // Update timestamp/msg if changed?
            if (this.alerts[idx].message !== alert.message) {
                this.alerts[idx] = alert;
                this.notify();
            }
        } else {
            this.alerts.push(alert);
            this.notify();
        }
    }

    private removeAlert(id: string) {
        const initialLen = this.alerts.length;
        this.alerts = this.alerts.filter(a => a.id !== id);
        if (this.alerts.length !== initialLen) {
            this.notify();
        }
    }

    private notify() {
        this.listeners.forEach(l => l(this.alerts));
    }
}
