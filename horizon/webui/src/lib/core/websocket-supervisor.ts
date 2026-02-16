import type { ConnectionState } from './schema';

type ConnectionListener = (state: ConnectionState) => void;
type MessageHandler = (data: any) => void;

interface SupervisorOptions {
    url: string;
    heartbeatInterval?: number;
    reconnectInterval?: number;
}

export class WebsocketSupervisor {
    private socket: WebSocket | null = null;
    private state: ConnectionState = 'DISCONNECTED';
    private listeners: Set<ConnectionListener> = new Set();
    private messageHandlers: Set<MessageHandler> = new Set();

    private url: string;
    private reconnectTimer: any = null;
    private heartbeatTimer: any = null;
    private reconnectAttempts = 0;

    // Config
    private readonly HEARTBEAT_MS = 5000;
    private readonly MAX_RECONNECT_DELAY = 10000;
    private readonly BASE_RECONNECT_DELAY = 1000;

    constructor(options: SupervisorOptions) {
        this.url = options.url;
    }

    public connect() {
        if (this.state === 'ONLINE' || this.state === 'CONNECTING') return;

        this.updateState('CONNECTING');
        try {
            console.log(`[Supervisor] Connecting to ${this.url}`);
            this.socket = new WebSocket(this.url);

            this.socket.onopen = this.onOpen.bind(this);
            this.socket.onclose = this.onClose.bind(this);
            this.socket.onerror = this.onError.bind(this);
            this.socket.onmessage = this.onMessage.bind(this);
        } catch (e) {
            console.error("[Supervisor] Connection failed immediately", e);
            this.handleDisconnect();
        }
    }

    public disconnect() {
        this.stopHeartbeat();
        if (this.reconnectTimer) clearTimeout(this.reconnectTimer);

        if (this.socket) {
            this.socket.close();
            this.socket = null;
        }
        this.updateState('DISCONNECTED');
    }

    public send(payload: any) {
        if (this.socket && this.socket.readyState === WebSocket.OPEN) {
            this.socket.send(JSON.stringify(payload));
        } else {
            console.warn("[Supervisor] Cannot send, socket not OPEN");
        }
    }

    public onStateChange(listener: ConnectionListener) {
        this.listeners.add(listener);
        listener(this.state); // Immediate sync
        return () => this.listeners.delete(listener);
    }

    public onMessageRaw(handler: MessageHandler) {
        this.messageHandlers.add(handler);
        return () => this.messageHandlers.delete(handler);
    }

    public getState(): ConnectionState {
        return this.state;
    }

    // --- Internals ---

    private updateState(newState: ConnectionState) {
        if (this.state !== newState) {
            this.state = newState;
            this.listeners.forEach(l => l(newState));
            console.log(`[Supervisor] State changed to ${newState}`);
        }
    }

    private onOpen() {
        this.updateState('ONLINE');
        this.reconnectAttempts = 0;
        this.startHeartbeat();
    }

    private onClose(ev: CloseEvent) {
        console.warn(`[Supervisor] Socket closed: ${ev.code} - ${ev.reason}`);
        this.handleDisconnect();
    }

    private onError(ev: Event) {
        console.error("[Supervisor] Socket error", ev);
        // Error usually leads to close, so we wait for close event or force it
        if (this.socket && this.socket.readyState === WebSocket.CLOSED) {
            this.handleDisconnect();
        }
    }

    private onMessage(ev: MessageEvent) {
        try {
            const data = JSON.parse(ev.data);
            this.messageHandlers.forEach(h => h(data));
        } catch (e) {
            console.error("[Supervisor] JSON Parse Error", e);
        }
    }

    private handleDisconnect() {
        this.stopHeartbeat();
        this.socket = null;

        if (this.state !== 'DISCONNECTED') {
            // If we were connecting or online, this is an unexpected drop
            // We go to DEGRADED first if it's a temp loss, but for implementation simplicity:
            // If we are hard disconnected, we are DISCONNECTED or we are in a retry loop.
            // Visual state: "Connecting..."
            this.updateState('CONNECTING'); // Visually we want to show we are trying
            this.scheduleReconnect();
        }
    }

    private scheduleReconnect() {
        if (this.reconnectTimer) return;

        const delay = Math.min(
            this.BASE_RECONNECT_DELAY * Math.pow(1.5, this.reconnectAttempts),
            this.MAX_RECONNECT_DELAY
        );

        // Jitter
        const jitter = Math.random() * 500;
        const totalDelay = delay + jitter;

        console.log(`[Supervisor] Reconnecting in ${Math.round(totalDelay)}ms (Attempt ${this.reconnectAttempts + 1})`);

        this.reconnectTimer = setTimeout(() => {
            this.reconnectTimer = null;
            this.reconnectAttempts++;
            this.connect();
        }, totalDelay);
    }

    private startHeartbeat() {
        this.stopHeartbeat();
        // Moonraker handles standard ping/pong, but we can verify app-level life
        this.heartbeatTimer = setInterval(() => {
            // Optional: Send application level ping if needed
            // this.send({jsonrpc: '2.0', method: 'server.info', id: 'ping'});
        }, this.HEARTBEAT_MS);
    }

    private stopHeartbeat() {
        if (this.heartbeatTimer) clearInterval(this.heartbeatTimer);
        this.heartbeatTimer = null;
    }
}
