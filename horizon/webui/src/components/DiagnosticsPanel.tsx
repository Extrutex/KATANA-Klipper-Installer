import { useState } from 'react';
import { useGCodeStore, KatanaLink, useDiagnostics } from '../lib/moonraker';

export default function DiagnosticsPanel() {
    const alerts = useDiagnostics();
    const { addLog } = useGCodeStore();
    const [selectedId, setSelectedId] = useState<string | null>(null);
    const [downloading, setDownloading] = useState(false);

    const handleAction = (action: string) => {
        if (action === 'FIRMWARE_RESTART') {
            const link = new KatanaLink();
            link.sendGCode('FIRMWARE_RESTART');
            addLog("Sent FIRMWARE_RESTART command", "command");
        }
    };

    const handleDownloadBundle = async () => {
        setDownloading(true);
        try {
            const response = await fetch('/machine/support_bundle', {
                method: 'POST'
            });
            if (response.ok) {
                const blob = await response.blob();
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `katana_support_bundle_${new Date().toISOString().slice(0,10)}.zip`;
                document.body.appendChild(a);
                a.click();
                window.URL.revokeObjectURL(url);
                document.body.removeChild(a);
                addLog("Support bundle downloaded", "response");
            } else {
                addLog("Failed to download bundle", "error");
            }
        } catch (err) {
            addLog("Bundle download failed: " + String(err), "error");
        } finally {
            setDownloading(false);
        }
    };

    if (selectedId && !alerts.find(a => a.id === selectedId)) {
        setSelectedId(null);
    }

    const displayErrors = alerts.map(alert => ({
        ...alert,
        type: alert.level === 'ERROR' ? 'CRITICAL' : 'WARNING',
        action: alert.source === 'PRINTER' ? 'FIRMWARE_RESTART' : undefined
    }));
    // Let's use the list view, it's more robust.

    return (
        <div className="glass-panel diagnostics-container">
            <div className="diag-header">
                <h2>SYSTEM DIAGNOSTICS</h2>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                    <button 
                        className="btn-download" 
                        onClick={handleDownloadBundle}
                        disabled={downloading}
                    >
                        {downloading ? 'CREATING BUNDLE...' : '📦 SUPPORT BUNDLE'}
                    </button>
                    {displayErrors.length > 0 ? (
                        <span className="badge-critical">{displayErrors.length} ACTIVE ISSUES</span>
                    ) : (
                        <span className="badge-success">SYSTEM NOMINAL</span>
                    )}
                </div>
            </div>

            <div className="diag-layout">
                {/* Error List */}
                <div className="error-list">
                    {displayErrors.map(err => (
                        <div
                            key={err.id}
                            className={`error-item ${err.type.toLowerCase()} ${selectedId === err.id ? 'active' : ''}`}
                            onClick={() => setSelectedId(err.id)}
                        >
                            <div className="error-icon">
                                {err.type === 'CRITICAL' ? '⛔' : '⚠️'}
                            </div>
                            <div className="error-summary">
                                <span className="error-code">{err.source}</span>
                                <span className="error-msg-summary">{err.message}</span>
                                <span className="error-time">{new Date(err.timestamp).toLocaleTimeString()}</span>
                            </div>
                        </div>
                    ))}
                    {displayErrors.length === 0 && (
                        <div className="all-clear">
                            <span className="check-icon">✅</span>
                            <h3>NO ACTIVE ERRORS</h3>
                            <p>All monitored systems are operational.</p>
                        </div>
                    )}
                </div>

                {/* Detail View */}
                <div className="error-detail">
                    {selectedId && displayErrors.find(e => e.id === selectedId) ? (
                        (() => {
                            const err = displayErrors.find(e => e.id === selectedId)!;
                            return (
                                <div className="detail-content">
                                    <h3 className={err.type.toLowerCase()}>{err.message}</h3>

                                    <div className="raw-log">
                                        <h4>SOURCE DETAILS</h4>
                                        <pre>{err.source} :: {err.level}</pre>
                                        <p style={{ marginTop: '1rem', fontFamily: 'monospace' }}>{err.id}</p>
                                    </div>

                                    <div className="resolution-actions">
                                        <h4>AVAILABLE ACTIONS</h4>
                                        <div className="action-buttons">
                                            {err.action && (
                                                <button className="btn-primary" onClick={() => handleAction(err.action!)}>
                                                    EXECUTE {err.action}
                                                </button>
                                            )}
                                            <button className="btn-secondary" onClick={() => window.open('https://www.klipper3d.org/Config_Reference.html', '_blank')}>
                                                SEARCH DOCS
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            );
                        })()
                    ) : (
                        <div className="placeholder">
                            {displayErrors.length > 0 ?
                                <span>Select an issue to view options.</span> :
                                <span>System is operating normally.</span>
                            }
                        </div>
                    )}
                </div>
            </div>

            <style>{`
                .diagnostics-container {
                    display: flex;
                    flex-direction: column;
                    height: 100%;
                    padding: 0;
                    overflow: hidden;
                    background: rgba(10, 10, 14, 0.8);
                }
                .diag-header {
                    padding: 1.5rem;
                    border-bottom: 1px solid rgba(255,255,255,0.1);
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                }
                .badge-critical {
                    background: rgba(255,50,50,0.2);
                    color: #ff5555;
                    border: 1px solid #ff5555;
                    padding: 0.2rem 0.8rem;
                    border-radius: 4px;
                    font-weight: bold;
                    letter-spacing: 1px;
                }
                .badge-success {
                    background: rgba(50,255,100,0.1);
                    color: #5f5;
                    border: 1px solid #5f5;
                    padding: 0.2rem 0.8rem;
                    border-radius: 4px;
                    font-weight: bold;
                    letter-spacing: 1px;
                }
                .diag-layout {
                    display: grid;
                    grid-template-columns: 350px 1fr;
                    flex: 1;
                    height: 100%;
                }
                .error-list {
                    border-right: 1px solid rgba(255,255,255,0.1);
                    overflow-y: auto;
                }
                .error-item {
                    padding: 1.5rem;
                    border-bottom: 1px solid rgba(255,255,255,0.05);
                    cursor: pointer;
                    display: flex;
                    gap: 1rem;
                    transition: all 0.2s;
                    border-left: 3px solid transparent;
                }
                .error-item:hover {
                    background: rgba(255,255,255,0.02);
                }
                .error-item.active {
                    background: rgba(255,255,255,0.05);
                    border-left: 3px solid var(--color-primary);
                }
                .error-item.critical { border-left-color: #f55; }
                .error-item.warning { border-left-color: #fa5; }
                
                .error-code { display: block; font-weight: bold; color: #fff; margin-bottom: 0.2rem; }
                .error-msg-summary { display: block; font-size: 0.9rem; color: #ccc; margin-bottom: 0.2rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
                .error-time { font-size: 0.8rem; color: #666; font-family: monospace; }
                .error-icon { font-size: 1.5rem; }

                .error-detail {
                    padding: 2rem;
                    overflow-y: auto;
                    background: rgba(0,0,0,0.2);
                }
                .detail-content h3 {
                    font-size: 1.4rem;
                    margin-bottom: 2rem;
                    padding-bottom: 1rem;
                    border-bottom: 1px solid rgba(255,255,255,0.1);
                }
                .detail-content h3.critical { color: #f55; }
                
                .resolution-actions h4 { color: #aaa; margin-bottom: 1rem; font-size: 0.9rem; letter-spacing: 1px; }
                .action-buttons { display: flex; gap: 1rem; }
                
                .raw-log { margin-bottom: 2rem; opacity: 0.8; }
                .raw-log pre { background: #000; padding: 1rem; border-radius: 4px; font-family: monospace; color: #fc0; }

                .all-clear {
                    padding: 3rem;
                    text-align: center;
                    color: #5f5;
                }
                .check-icon { font-size: 3rem; display: block; margin-bottom: 1rem; }
                .placeholder { 
                    height: 100%; display: flex; alignItems: center; justifyContent: center; color: #444; 
                }
                .btn-download {
                    background: rgba(0, 150, 255, 0.15);
                    border: 1px solid rgba(0, 150, 255, 0.4);
                    color: #0af;
                    padding: 0.5rem 1rem;
                    border-radius: 4px;
                    cursor: pointer;
                    font-size: 0.85rem;
                    transition: all 0.2s;
                }
                .btn-download:hover:not(:disabled) {
                    background: rgba(0, 150, 255, 0.25);
                    border-color: #0af;
                }
                .btn-download:disabled {
                    opacity: 0.5;
                    cursor: not-allowed;
                }
            `}</style>
        </div>
    );
}
