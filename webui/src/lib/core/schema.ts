import { z } from 'zod';

// --- Primitive Schemas ---

export const ConnectionStateSchema = z.enum(['DISCONNECTED', 'CONNECTING', 'ONLINE', 'DEGRADED']);
export type ConnectionState = z.infer<typeof ConnectionStateSchema>;

export const PrinterStatusSchema = z.enum(['startup', 'ready', 'shutdown', 'error', 'printing', 'paused', 'complete', 'idle']);

// --- Object Schemas ---

export const ToolheadSchema = z.object({
    position: z.tuple([z.number(), z.number(), z.number(), z.number()]).default([0, 0, 0, 0]),
    max_velocity: z.number().default(0),
    max_accel: z.number().default(0),
    status: z.string().default('Unknown'),
    homed_axes: z.string().default(''),
    print_time: z.number().default(0),
    estimated_print_time: z.number().default(0)
});

export const HeaterSchema = z.object({
    temperature: z.number().default(0),
    target: z.number().default(0),
    power: z.number().default(0)
});

export const WebhooksSchema = z.object({
    state: z.string().default('startup'),
    state_message: z.string().default('Initializing...')
});

export const SystemStatsSchema = z.object({
    cpu_usage: z.number().optional(), // Normalized to 0-100 if possible, or raw
    memory_usage: z.number().optional(),
    sysload: z.number().optional(),
    cputime: z.number().optional(),
    memavail: z.number().optional()
});

// --- Composite State Schema ---

export const PrinterObjectsSchema = z.object({
    toolhead: ToolheadSchema.optional(),
    extruder: HeaterSchema.optional(),
    heater_bed: HeaterSchema.optional(),
    webhooks: WebhooksSchema.optional(),
    // Add other relevant objects as needed (fan, etc.)
});
export type PrinterObjects = z.infer<typeof PrinterObjectsSchema>;

export const PrinterStateSchema = z.object({
    status: PrinterStatusSchema.default('startup'),
    objects: PrinterObjectsSchema.default({}),
    system: SystemStatsSchema.optional().nullable()
});

export type PrinterState = z.infer<typeof PrinterStateSchema>;

// --- API Message Schemas ---

export const JsonRpcResponseSchema = z.object({
    jsonrpc: z.literal('2.0'),
    result: z.any().optional(),
    error: z.object({
        code: z.number(),
        message: z.string()
    }).optional(),
    id: z.number().or(z.string()).nullable()
});

export const NotifyStatusUpdateSchema = z.object({
    jsonrpc: z.literal('2.0'),
    method: z.literal('notify_status_update'),
    params: z.tuple([z.record(z.string(), z.any())]) // Dynamic partial object
});

