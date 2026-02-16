import { z } from 'zod';
import { WebsocketSupervisor } from './websocket-supervisor';

// --- Schemas ---

export const ProcStatsSchema = z.object({
    cpu_usage: z.number().optional().default(0), // Percentage
    memory: z.object({
        total: z.number(),
        available: z.number(),
        used: z.number()
    }).optional(),
    system_cpu_usage: z.object({
        user: z.number(),
        system: z.number(),
        idle: z.number()
    }).optional()
});

export type ProcStats = z.infer<typeof ProcStatsSchema>;

export type SystemHealthStatus = 'OK' | 'WARN' | 'ERROR';

export interface SystemHealthState {
    status: SystemHealthStatus;
    cpu: {
        usage: number; // 0-100
        temp: number; // Celsius (if available)
    };
    memory: {
        total: number;
        used: number;
        free: number;
    };
    disk: {
        total: number;
        used: number;
        free: number;
    } | null;
    load: [number, number, number]; // 1, 5, 15 min
}

type HealthListener = (state: SystemHealthState) => void;

export class ServiceHealthStore {
    private state: SystemHealthState = {
        status: 'OK',
        cpu: { usage: 0, temp: 0 },
        memory: { total: 0, used: 0, free: 0 },
        disk: null,
        load: [0, 0, 0]
    };

    private listeners: Set<HealthListener> = new Set();
    private supervisor: WebsocketSupervisor;
    private pollTimer: any = null;

    // config
    private readonly POLL_INTERVAL = 2000;

    constructor(supervisor: WebsocketSupervisor) {
        this.supervisor = supervisor;

        // Start polling when connected
        this.supervisor.onStateChange((conn) => {
            if (conn === 'ONLINE') {
                this.startPolling();
            } else {
                this.stopPolling();
            }
        });
    }

    public subscribe(listener: HealthListener) {
        this.listeners.add(listener);
        listener(this.state);
        return () => this.listeners.delete(listener);
    }

    public getState() {
        return { ...this.state };
    }

    private startPolling() {
        this.stopPolling();
        this.poll();
        this.pollTimer = setInterval(() => this.poll(), this.POLL_INTERVAL);
    }

    private stopPolling() {
        if (this.pollTimer) clearInterval(this.pollTimer);
        this.pollTimer = null;
    }

    private async poll() {
        if (this.supervisor.getState() !== 'ONLINE') return;

        // 1. Proc Stats (CPU/Mem)
        this.supervisor.send({
            jsonrpc: "2.0",
            method: "machine.proc_stats",
            id: "health_proc_stats"
        });

        // 2. System Info (Disk/Temp - usually static but some dynamic?)
        // actually machine.system_info is static. Use specific endpoints if needed.
        // For now relying on proc_stats for dynamic.
    }

    public handleMessage(msg: any) {
        if (msg.id === "health_proc_stats" && msg.result) {
            const raw = msg.result;
            // Parse safe
            const parsed = ProcStatsSchema.safeParse(raw);

            if (parsed.success) {
                const data = parsed.data;

                // Update State
                this.state.cpu.usage = data.cpu_usage;
                if (data.memory) {
                    this.state.memory = {
                        total: data.memory.total,
                        used: data.memory.used,
                        free: data.memory.available
                    };
                }

                this.recalculateHealth();
                this.notify();
            }
        }
    }

    private recalculateHealth() {
        let status: SystemHealthStatus = 'OK';

        if (this.state.cpu.usage > 90) status = 'WARN';
        if (this.state.memory.free < 100000) status = 'WARN'; // Example

        this.state.status = status;
    }

    private notify() {
        this.listeners.forEach(l => l(this.state));
    }
}
