import { useState, useEffect } from 'react';
import { client, useConnectionDiagnostics } from '../lib/moonraker';

interface SystemInfo {
    cpu_info?: {
        model?: string;
        cpu_count?: number;
        total_memory?: number;
    };
    distribution?: {
        name?: string;
        kernel_version?: string;
    };
    network?: Record<string, any>;
}

interface ProcStats {
    moonraker_stats?: Array<{ cpu_usage?: number; memory?: number }>;
    cpu_temp?: number;
    system_uptime?: number;
    system_memory?: {
        total?: number;
        available?: number;
        used?: number;
    };
    network?: Record<string, {
        rx_bytes?: number;
        tx_bytes?: number;
        bandwidth?: number;
    }>;
    system_cpu_usage?: {
        cpu?: number;
    };
}

interface ServerInfo {
    klippy_state?: string;
    moonraker_version?: string;
    klippy_connected?: boolean;
}

function formatUptime(seconds: number): string {
    if (!seconds) return '--';
    const d = Math.floor(seconds / 86400);
    const h = Math.floor((seconds % 86400) / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    if (d > 0) return `${d}d ${h}h`;
    if (h > 0) return `${h}h ${m}m`;
    return `${m}m`;
}

function formatBytes(bytes: number): string {
    if (!bytes) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

function HostSystemCard({ systemInfo, procStats }: { systemInfo: SystemInfo; procStats: ProcStats }) {
    const cpuInfo = systemInfo?.cpu_info || {};
    const dist = systemInfo?.distribution || {};
    const net = procStats?.network?.wlan0 || procStats?.network?.eth0 || {};
    
    const latestProc = procStats?.moonraker_stats?.[procStats.moonraker_stats.length - 1] || {};
    const cpuUsage = latestProc.cpu_usage || 0;
    const memUsedKB = procStats?.system_memory?.used || 0;
    const memTotalKB = procStats?.system_memory?.total || cpuInfo.total_memory || 1;
    const memPct = (memUsedKB / memTotalKB) * 100;
    const cpuTemp = procStats?.cpu_temp || 0;
    const uptime = procStats?.system_uptime || 0;

    return (
        <div className="loads-card">
            <div className="loads-card-header">
                <span className="loads-title">Host System</span>
                <span className="loads-subtitle">{cpuInfo.model || 'Unknown CPU'}</span>
            </div>
            <div className="loads-card-body">
                <div className="loads-row">
                    <span className="loads-label">OS</span>
                    <span className="loads-value">{dist.name || 'Unknown'}</span>
                </div>
                <div className="loads-row">
                    <span className="loads-label">Kernel</span>
                    <span className="loads-value">{dist.kernel_version || 'Unknown'}</span>
                </div>
                <div className="loads-row">
                    <span className="loads-label">Load</span>
                    <div className="loads-bar-container">
                        <div className="loads-bar" style={{ 
                            width: `${Math.min(100, cpuUsage)}%`,
                            background: cpuUsage > 80 ? '#ef4444' : cpuUsage > 50 ? '#f59e0b' : '#22c55e'
                        }} />
                    </div>
                    <span className="loads-value-num">{cpuUsage.toFixed(0)}%</span>
                </div>
                <div className="loads-row">
                    <span className="loads-label">CPU Temp</span>
                    <div className="loads-bar-container">
                        <div className="loads-bar" style={{ 
                            width: `${Math.min(100, cpuTemp / 80 * 100)}%`,
                            background: cpuTemp > 70 ? '#ef4444' : cpuTemp > 50 ? '#f59e0b' : '#22c55e'
                        }} />
                    </div>
                    <span className="loads-value-num">{cpuTemp.toFixed(0)}°C</span>
                </div>
                <div className="loads-row">
                    <span className="loads-label">Memory</span>
                    <div className="loads-bar-container">
                        <div className="loads-bar" style={{ 
                            width: `${Math.min(100, memPct)}%`,
                            background: memPct > 80 ? '#ef4444' : memPct > 50 ? '#f59e0b' : '#3b82f6'
                        }} />
                    </div>
                    <span className="loads-value-num">{memPct.toFixed(0)}%</span>
                </div>
                <div className="loads-row">
                    <span className="loads-label">Memory</span>
                    <span className="loads-value">{formatBytes(memUsedKB * 1024)} / {formatBytes(memTotalKB * 1024)}</span>
                </div>
                <div className="loads-row">
                    <span className="loads-label">Uptime</span>
                    <span className="loads-value">{formatUptime(uptime)}</span>
                </div>
                <div className="loads-row">
                    <span className="loads-label">Network</span>
                    <span className="loads-value">{net.rx_bytes !== undefined ? `↑ ${formatBytes(net.tx_bytes || 0)} ↓ ${formatBytes(net.rx_bytes || 0)}` : 'N/A'}</span>
                </div>
            </div>
        </div>
    );
}

function MCUCard({ mcuName, mcuData }: { mcuName: string; mcuData: any }) {
    const mcu = mcuData || {};
    const load = typeof mcu.load === 'number' ? mcu.load * 100 : 0;
    const freq = typeof mcu.freq === 'number' ? (mcu.freq / 1000000).toFixed(1) : 'N/A';
    const temp = typeof mcu.mcu_temperature === 'number' ? mcu.mcu_temperature : 'N/A';
    const awake = typeof mcu.awake_time === 'number' ? mcu.awake_time.toFixed(0) : 'N/A';

    return (
        <div className="loads-card">
            <div className="loads-card-header">
                <span className="loads-title">MCU</span>
                <span className="loads-subtitle">{mcuName}</span>
            </div>
            <div className="loads-card-body">
                <div className="loads-row">
                    <span className="loads-label">Load</span>
                    <div className="loads-bar-container">
                        <div className="loads-bar" style={{ 
                            width: `${Math.min(100, load)}%`,
                            background: load > 80 ? '#ef4444' : load > 50 ? '#f59e0b' : '#22c55e'
                        }} />
                    </div>
                    <span className="loads-value-num">{load.toFixed(1)}%</span>
                </div>
                <div className="loads-row">
                    <span className="loads-label">Freq</span>
                    <span className="loads-value">{freq} MHz</span>
                </div>
                <div className="loads-row">
                    <span className="loads-label">Temp</span>
                    <span className="loads-value">{temp !== 'N/A' ? `${temp}°C` : 'N/A'}</span>
                </div>
                <div className="loads-row">
                    <span className="loads-label">Awake</span>
                    <span className="loads-value">{awake}s</span>
                </div>
            </div>
        </div>
    );
}

function DiagnosticsSection() {
    const { connState, url, logs } = useConnectionDiagnostics();
    
    return (
        <div className="diagnostics-section">
            <div className="diag-header">CONNECTION DIAGNOSTICS</div>
            <div className="diag-row">
                <span className="diag-label">Moonraker URL:</span>
                <span className="diag-value mono">{url}</span>
            </div>
            <div className="diag-row">
                <span className="diag-label">WebSocket:</span>
                <span className={`diag-value ${connState === 'ONLINE' ? 'online' : 'offline'}`}>
                    {connState}
                </span>
            </div>
            {logs.length > 0 && (
                <div className="api-log">
                    <div className="api-log-header">Recent API Calls:</div>
                    {logs.map(log => (
                        <div key={log.id} className={`api-log-entry ${log.status}`}>
                            <span className="api-method">{log.method}</span>
                            <span className="api-status">{log.status}</span>
                            {log.duration && <span className="api-duration">{log.duration}ms</span>}
                            {log.error && <span className="api-error">{log.error}</span>}
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}

export default function SystemHealth() {
    const [systemInfo, setSystemInfo] = useState<SystemInfo | null>(null);
    const [procStats, setProcStats] = useState<ProcStats | null>(null);
    const [serverInfo, setServerInfo] = useState<ServerInfo | null>(null);
    const [mcuObjects, setMcuObjects] = useState<Record<string, any>>({});
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    
    const { connState } = useConnectionDiagnostics();

    const fetchData = async () => {
        try {
            const [sysData, procData, srvData] = await Promise.all([
                client.apiCall<any>('machine.system_info'),
                client.apiCall<any>('machine.proc_stats'),
                client.apiCall<any>('server.info')
            ]);
            
            if (sysData) setSystemInfo(sysData);
            if (procData) setProcStats(procData);
            if (srvData) setServerInfo(srvData);
            
            setError(null);
        } catch (e: any) {
            setError(e.message || 'Failed to fetch system data');
            console.error('System health fetch error:', e);
        } finally {
            setLoading(false);
        }
    };

    const fetchMcuData = async () => {
        try {
            const listData = await client.apiCall<any>('printer.objects.list');
            
            if (listData?.objects) {
                const mcuObjects = listData.objects.filter((obj: string) => 
                    obj === 'mcu' || obj.startsWith('mcu ')
                );
                
                if (mcuObjects.length > 0) {
                    const queryObj: Record<string, null> = {};
                    mcuObjects.forEach((name: string) => { queryObj[name] = null; });
                    
                    const queryData = await client.apiCall<any>('printer.objects.query', { objects: queryObj });
                    
                    if (queryData?.status) {
                        setMcuObjects(queryData.status);
                    }
                }
            }
        } catch (e) {
            console.error('MCU fetch error:', e);
        }
    };

    useEffect(() => {
        fetchData();
        fetchMcuData();
        const interval = setInterval(() => {
            fetchData();
            fetchMcuData();
        }, 5000);
        return () => clearInterval(interval);
    }, []);

    const isMoonrakerOnline = serverInfo?.klippy_connected !== undefined;
    const isKlipperReady = serverInfo?.klippy_state === 'ready';

    if (loading) {
        return (
            <div className="system-container">
                <div className="loading-state">Loading system information...</div>
                <DiagnosticsSection />
            </div>
        );
    }

    if (error || !isMoonrakerOnline || connState !== 'ONLINE') {
        return (
            <div className="system-container">
                <div className="error-state">
                    <h2>SYSTEM OFFLINE</h2>
                    <p>{error || (connState !== 'ONLINE' ? `WebSocket: ${connState}` : 'Moonraker not connected')}</p>
                    <button onClick={fetchData}>RETRY</button>
                </div>
                <DiagnosticsSection />
            </div>
        );
    }

    return (
        <div className="system-container">
            <div className="system-header">
                <h1>SYSTEM LOADS</h1>
                <div className="system-status">
                    <span className={`status-badge ${isKlipperReady ? 'ready' : 'error'}`}>
                        KLIPPER: {serverInfo?.klippy_state?.toUpperCase() || 'UNKNOWN'}
                    </span>
                    <span className="status-badge online">
                        MOONRAKER: {serverInfo?.moonraker_version || 'N/A'}
                    </span>
                </div>
            </div>

            <DiagnosticsSection />

            <div className="loads-grid">
                {systemInfo && procStats && (
                    <HostSystemCard systemInfo={systemInfo} procStats={procStats} />
                )}
                
                {Object.keys(mcuObjects).length > 0 ? (
                    Object.entries(mcuObjects).map(([name, data]) => (
                        <MCUCard key={name} mcuName={name} mcuData={data} />
                    ))
                ) : (
                    <div className="loads-card">
                        <div className="loads-card-header">
                            <span className="loads-title">MCU</span>
                            <span className="loads-subtitle">No MCU connected</span>
                        </div>
                        <div className="loads-card-body">
                            <div className="loads-row">
                                <span className="loads-value" style={{ opacity: 0.5 }}>
                                    Connect printer hardware to see MCU stats
                                </span>
                            </div>
                        </div>
                    </div>
                )}
            </div>

            <style>{`
                .system-container {
                    padding: 1rem;
                    height: 100%;
                    overflow: auto;
                    background: var(--bg-dark);
                }
                
                .system-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    margin-bottom: 1.5rem;
                    padding-bottom: 1rem;
                    border-bottom: 1px solid var(--border);
                }
                
                .system-header h1 {
                    font-size: 1.25rem;
                    font-weight: 600;
                    letter-spacing: 1px;
                    color: var(--text);
                }
                
                .system-status {
                    display: flex;
                    gap: 0.75rem;
                }
                
                .status-badge {
                    font-size: 0.7rem;
                    padding: 0.35rem 0.75rem;
                    border-radius: 4px;
                    font-weight: 600;
                    text-transform: uppercase;
                }
                
                .status-badge.ready {
                    background: rgba(34, 197, 94, 0.2);
                    color: #22c55e;
                }
                
                .status-badge.error {
                    background: rgba(239, 68, 68, 0.2);
                    color: #ef4444;
                }
                
                .status-badge.online {
                    background: rgba(59, 130, 246, 0.2);
                    color: #3b82f6;
                }
                
                .loads-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
                    gap: 1rem;
                }
                
                .loads-card {
                    background: var(--bg-panel);
                    border: 1px solid var(--border);
                    border-radius: 8px;
                    overflow: hidden;
                }
                
                .loads-card-header {
                    padding: 0.75rem 1rem;
                    background: var(--bg-header);
                    border-bottom: 1px solid var(--border);
                }
                
                .loads-title {
                    display: block;
                    font-size: 0.75rem;
                    font-weight: 600;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                    color: var(--text-muted);
                }
                
                .loads-subtitle {
                    display: block;
                    font-size: 0.85rem;
                    color: var(--text);
                    margin-top: 0.25rem;
                }
                
                .loads-card-body {
                    padding: 1rem;
                }
                
                .loads-row {
                    display: flex;
                    align-items: center;
                    gap: 0.75rem;
                    margin-bottom: 0.6rem;
                    font-size: 0.8rem;
                }
                
                .loads-label {
                    width: 70px;
                    flex-shrink: 0;
                    color: var(--text-muted);
                }
                
                .loads-value {
                    flex: 1;
                    color: var(--text);
                }
                
                .loads-bar-container {
                    flex: 1;
                    height: 6px;
                    background: var(--bg-dark);
                    border-radius: 3px;
                    overflow: hidden;
                }
                
                .loads-bar {
                    height: 100%;
                    border-radius: 3px;
                    transition: width 0.3s;
                }
                
                .loads-value-num {
                    width: 40px;
                    text-align: right;
                    font-family: monospace;
                    font-size: 0.75rem;
                    color: var(--text);
                }
                
                .loading-state, .error-state {
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    height: 100%;
                    color: var(--text-muted);
                    gap: 1rem;
                }
                
                .error-state h2 {
                    color: #ef4444;
                }
                
                .error-state button {
                    padding: 0.5rem 1.5rem;
                    background: var(--accent);
                    border: none;
                    border-radius: 4px;
                    color: white;
                    cursor: pointer;
                }
                
                .diagnostics-section {
                    background: var(--bg-panel);
                    border: 1px solid var(--border);
                    border-radius: 8px;
                    padding: 1rem;
                    margin-bottom: 1rem;
                }
                
                .diag-header {
                    font-size: 0.7rem;
                    font-weight: 600;
                    color: var(--text-muted);
                    margin-bottom: 0.75rem;
                    letter-spacing: 0.5px;
                }
                
                .diag-row {
                    display: flex;
                    gap: 0.75rem;
                    font-size: 0.75rem;
                    margin-bottom: 0.4rem;
                }
                
                .diag-label {
                    color: var(--text-muted);
                    width: 100px;
                }
                
                .diag-value {
                    color: var(--text);
                }
                
                .diag-value.mono {
                    font-family: monospace;
                    font-size: 0.7rem;
                }
                
                .diag-value.online {
                    color: #22c55e;
                }
                
                .diag-value.offline {
                    color: #ef4444;
                }
                
                .api-log {
                    margin-top: 0.75rem;
                    padding-top: 0.75rem;
                    border-top: 1px solid var(--border);
                }
                
                .api-log-header {
                    font-size: 0.65rem;
                    color: var(--text-muted);
                    margin-bottom: 0.5rem;
                }
                
                .api-log-entry {
                    display: flex;
                    gap: 0.5rem;
                    font-size: 0.65rem;
                    padding: 0.25rem 0;
                    font-family: monospace;
                }
                
                .api-log-entry.success .api-status { color: #22c55e; }
                .api-log-entry.error .api-status { color: #ef4444; }
                .api-log-entry.pending .api-status { color: #f59e0b; }
                
                .api-method { color: var(--text); }
                .api-duration { color: var(--text-muted); margin-left: auto; }
                .api-error { color: #ef4444; }
            `}</style>
        </div>
    );
}
