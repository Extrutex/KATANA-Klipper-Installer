import { PrinterStateSchema } from './schema';
import type { PrinterState } from './schema';
type StateListener = (state: PrinterState) => void;

export class PrinterStateMachine {
    private state: PrinterState;
    private listeners: Set<StateListener> = new Set();

    constructor() {
        // Initial clean state
        this.state = PrinterStateSchema.parse({
            status: 'startup',
            objects: {
                toolhead: { position: [0, 0, 0, 0], max_velocity: 0, max_accel: 0 },
                extruder: { temperature: 0, target: 0 },
                heater_bed: { temperature: 0, target: 0 },
                webhooks: { state: "startup", state_message: "Initializing..." }
            },
            system: null
        });
    }

    public getState(): PrinterState {
        return { ...this.state }; // Return copy
    }

    public subscribe(listener: StateListener) {
        this.listeners.add(listener);
        listener(this.getState());
        return () => this.listeners.delete(listener);
    }

    // --- Actions ---

    public handleObjectsQuery(result: any) {
        if (!result || !result.status) return; // Basic check

        // Deep merge logic (simplified for reliability)
        // In a real Redux setup we would have reducers
        // Batch update
        this.updateObjects(result.status, false); // No notify yet

        // Update top-level status if present
        if (result.status.webhooks) {
            this.updateStatusFromWebhooks(result.status.webhooks);
        }

        this.notify();
    }

    public handleStatusUpdate(params: any) {
        // Params is array [ { key: val, ... }, timestamp ]
        if (Array.isArray(params) && params.length > 0) {
            const updates = params[0];
            this.updateObjects(updates, false);

            if (updates.webhooks) {
                this.updateStatusFromWebhooks(updates.webhooks);
            }
            this.notify();
        }
    }

    public setSystemStats(stats: any) {
        // Validation could happen here or in schema
        this.state.system = {
            ...this.state.system,
            ...stats
        };
        this.notify();
    }

    // --- Internals ---

    private updateObjects(partialObjects: any, notify = true) {
        // Recursive merge for known objects
        // This effectively patches our local state with valid updates

        if (partialObjects.toolhead) {
            this.state.objects.toolhead = { ...this.state.objects.toolhead, ...partialObjects.toolhead };
        }
        if (partialObjects.extruder) {
            this.state.objects.extruder = { ...this.state.objects.extruder, ...partialObjects.extruder };
        }
        if (partialObjects.heater_bed) {
            this.state.objects.heater_bed = { ...this.state.objects.heater_bed, ...partialObjects.heater_bed };
        }
        if (partialObjects.webhooks) {
            this.state.objects.webhooks = { ...this.state.objects.webhooks, ...partialObjects.webhooks };
        }

        if (notify) this.notify();
    }

    private updateStatusFromWebhooks(webhooks: any) {
        if (webhooks.state) {
            // Align top level status with webhook state
            // Klipper states: startup, ready, shutdown, error
            // We map these to our PrinterStatus enum
            this.state.status = webhooks.state;
        }
    }

    private notify() {
        const snapshot = this.getState();
        this.listeners.forEach(l => l(snapshot));
    }
}
