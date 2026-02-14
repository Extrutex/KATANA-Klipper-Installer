import { useState, useEffect } from 'react';
import { client } from '../lib/moonraker';

interface Tool {
    name: string;
    index: number;
    temperature?: number;
    target?: number;
    active: boolean;
}

export default function Toolchanger() {
    const [tools, setTools] = useState<Tool[]>([]);
    const [activeTool, setActiveTool] = useState(0);
    const [loading, setLoading] = useState(true);
    const [switching, setSwitching] = useState(false);

    useEffect(() => {
        fetchTools();
    }, []);

    const fetchTools = async () => {
        setLoading(true);
        try {
            const response = await fetch('/api/printer/objects/list');
            const data = await response.json();
            
            // Check for extruder objects (extruder, extruder1, extruder2, etc.)
            const objects = data.result?.objects || [];
            const extruders = objects.filter((o: string) => o.startsWith('extruder'));
            
            if (extruders.length > 0) {
                const toolList: Tool[] = extruders.map((name: string, idx: number) => ({
                    name: name.replace('extruder', 'T') || `T${idx}`,
                    index: idx,
                    active: idx === activeTool
                }));
                setTools(toolList);
            } else {
                // Default 4 tools if no extruders detected
                setTools([
                    { name: 'T0', index: 0, active: true },
                    { name: 'T1', index: 1, active: false },
                    { name: 'T2', index: 2, active: false },
                    { name: 'T3', index: 3, active: false }
                ]);
            }
        } catch (err) {
            // Fallback to default
            setTools([
                { name: 'T0', index: 0, active: true },
                { name: 'T1', index: 1, active: false },
                { name: 'T2', index: 2, active: false },
                { name: 'T3', index: 3, active: false }
            ]);
        } finally {
            setLoading(false);
        }
    };

    const switchTool = async (toolIndex: number) => {
        if (toolIndex === activeTool || switching) return;
        
        setSwitching(true);
        try {
            client.sendGCode(`T${toolIndex}`);
            setActiveTool(toolIndex);
            setTools(prev => prev.map(t => ({
                ...t,
                active: t.index === toolIndex
            })));
        } catch (err) {
            console.error('Tool switch failed:', err);
        } finally {
            setTimeout(() => setSwitching(false), 2000);
        }
    };

    const quickActions = [
        { label: 'PURGE', action: 'PURGE' },
        { label: 'CLEAN', action: 'CLEAN_NOZZLE' },
        { label: 'PARK', action: 'TOOL_PARK' },
    ];

    const handleQuickAction = (action: string) => {
        client.sendGCode(action);
    };

    if (loading) {
        return (
            <div style={{ 
                padding: '2rem', 
                textAlign: 'center', 
                color: 'var(--text-secondary)' 
            }}>
                Loading tool information...
            </div>
        );
    }

    return (
        <div className="glass-panel toolchanger-container">
            <div className="toolchanger-header">
                <h2>TOOLCHANGER</h2>
                <span className="active-tool-badge">
                    ACTIVE: {tools[activeTool]?.name || 'NONE'}
                </span>
            </div>

            <div className="tool-grid">
                {tools.map((tool) => (
                    <button
                        key={tool.index}
                        className={`tool-button ${tool.active ? 'active' : ''}`}
                        onClick={() => switchTool(tool.index)}
                        disabled={switching}
                    >
                        <span className="tool-name">{tool.name}</span>
                        <span className={`tool-status ${tool.active ? 'active' : ''}`}>
                            {tool.active ? '● ACTIVE' : '○ READY'}
                        </span>
                    </button>
                ))}
            </div>

            <div className="quick-actions">
                <span className="actions-label">QUICK ACTIONS</span>
                <div className="actions-grid">
                    {quickActions.map(action => (
                        <button
                            key={action.action}
                            className="action-button"
                            onClick={() => handleQuickAction(action.action)}
                        >
                            {action.label}
                        </button>
                    ))}
                </div>
            </div>

            <div className="tool-info">
                <div className="info-row">
                    <span>Total Tools:</span>
                    <span>{tools.length}</span>
                </div>
                <div className="info-row">
                    <span>Status:</span>
                    <span className="status-ok">{switching ? 'SWITCHING...' : 'READY'}</span>
                </div>
            </div>

            <style>{`
                .toolchanger-container {
                    height: 100%;
                    display: flex;
                    flex-direction: column;
                    padding: 0;
                }
                .toolchanger-header {
                    padding: 1.5rem;
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    border-bottom: 1px solid var(--border-light);
                }
                .active-tool-badge {
                    background: var(--color-primary);
                    color: #fff;
                    padding: 0.4rem 1rem;
                    border-radius: 4px;
                    font-size: 0.85rem;
                    font-weight: bold;
                }
                .tool-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(80px, 1fr));
                    gap: 1rem;
                    padding: 1.5rem;
                }
                .tool-button {
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    padding: 1rem;
                    background: rgba(255,255,255,0.03);
                    border: 2px solid var(--border-light);
                    border-radius: 12px;
                    cursor: pointer;
                    transition: all 0.2s;
                }
                .tool-button:hover:not(:disabled) {
                    border-color: var(--color-primary);
                    background: rgba(255,255,255,0.06);
                }
                .tool-button.active {
                    border-color: var(--color-primary);
                    background: rgba(0,255,128,0.1);
                    box-shadow: 0 0 20px var(--color-primary-glow);
                }
                .tool-button:disabled {
                    opacity: 0.5;
                    cursor: not-allowed;
                }
                .tool-name {
                    font-size: 1.5rem;
                    font-weight: bold;
                    color: var(--text-primary);
                }
                .tool-status {
                    font-size: 0.7rem;
                    color: var(--text-secondary);
                    margin-top: 0.3rem;
                }
                .tool-status.active {
                    color: var(--color-primary);
                }
                .quick-actions {
                    padding: 0 1.5rem;
                    border-top: 1px solid var(--border-light);
                    padding-top: 1rem;
                }
                .actions-label {
                    font-size: 0.7rem;
                    color: var(--text-secondary);
                    letter-spacing: 1px;
                    display: block;
                    margin-bottom: 0.5rem;
                }
                .actions-grid {
                    display: flex;
                    gap: 0.5rem;
                }
                .action-button {
                    flex: 1;
                    padding: 0.6rem;
                    background: rgba(255,255,255,0.05);
                    border: 1px solid var(--border-light);
                    border-radius: 6px;
                    color: var(--text-primary);
                    cursor: pointer;
                    font-size: 0.8rem;
                    transition: all 0.2s;
                }
                .action-button:hover {
                    background: var(--color-primary);
                    border-color: var(--color-primary);
                }
                .tool-info {
                    margin-top: auto;
                    padding: 1rem 1.5rem;
                    background: rgba(0,0,0,0.2);
                    border-top: 1px solid var(--border-light);
                }
                .info-row {
                    display: flex;
                    justify-content: space-between;
                    font-size: 0.85rem;
                    color: var(--text-secondary);
                    margin-bottom: 0.3rem;
                }
                .status-ok {
                    color: #5f5;
                }
            `}</style>
        </div>
    );
}
