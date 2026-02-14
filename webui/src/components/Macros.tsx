import { useState, useEffect } from 'react';
import { client } from '../lib/moonraker';

interface Macro {
    name: string;
    description?: string;
}

export default function Macros() {
    const [macros, setMacros] = useState<Macro[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [running, setRunning] = useState<string | null>(null);

    useEffect(() => {
        fetchMacros();
    }, []);

    const fetchMacros = async () => {
        setLoading(true);
        setError(null);
        
        try {
            const response = await fetch('/api/printer/objects/list');
            const data = await response.json();
            
            if (data.result && data.result.objects) {
                const gcodeMove = data.result.objects.find((o: any) => o === 'gcode_move');
                if (gcodeMove) {
                    // Macros are stored in config, we need to fetch them differently
                    // For now, let's use a predefined list of common macros
                    setMacros([
                        { name: 'QUICK_HOME', description: 'Home all axes quickly' },
                        { name: 'PRINT_START', description: 'Start print routine' },
                        { name: 'PRINT_END', description: 'End print routine' },
                        { name: 'BED_MESH_CALIBRATE', description: 'Run bed mesh calibration' },
                        { name: 'Z_TILT_ADJUST', description: 'Adjust Z tilt' },
                        { name: 'PID_CALIBRATE', description: 'Run PID calibration' },
                        { name: 'ACCELERATE_TEST', description: 'Test acceleration' },
                    ]);
                }
            }
            
            // Alternative: fetch from config
            const configRes = await fetch('/api/config/printer');
            if (configRes.ok) {
                const configData = await configRes.json();
                if (configData.result && configData.result.config) {
                    const configMacros: Macro[] = [];
                    for (const [key, value] of Object.entries(configData.result.config)) {
                        if (key.startsWith('gcode_macro ')) {
                            const name = key.replace('gcode_macro ', '');
                            const desc = (value as any).description || '';
                            configMacros.push({ name, description: desc });
                        }
                    }
                    if (configMacros.length > 0) {
                        setMacros(configMacros);
                    }
                }
            }
        } catch (err) {
            console.error('Failed to fetch macros:', err);
            // Fallback to common macros
            setMacros([
                { name: 'QUICK_HOME' },
                { name: 'PRINT_START' },
                { name: 'PRINT_END' },
                { name: 'BED_MESH_CALIBRATE' },
                { name: 'Z_TILT_ADJUST' },
            ]);
        } finally {
            setLoading(false);
        }
    };

    const runMacro = async (macroName: string) => {
        setRunning(macroName);
        try {
            client.sendGCode(macroName);
        } catch (err) {
            console.error('Failed to run macro:', err);
        } finally {
            setTimeout(() => setRunning(null), 1000);
        }
    };

    return (
        <div className="glass-panel macros-container">
            <div className="macros-header">
                <h2>G-CODE MACROS</h2>
                <button className="btn-small" onClick={fetchMacros}>REFRESH</button>
            </div>

            <div className="macros-list">
                {loading && (
                    <div style={{ padding: '2rem', textAlign: 'center', color: '#888' }}>
                        Loading macros...
                    </div>
                )}
                
                {error && (
                    <div style={{ padding: '2rem', textAlign: 'center', color: '#f55' }}>
                        {error}
                    </div>
                )}
                
                {!loading && macros.length === 0 && (
                    <div style={{ padding: '2rem', textAlign: 'center', color: '#888' }}>
                        No macros found.
                    </div>
                )}
                
                {!loading && macros.map((macro) => (
                    <div key={macro.name} className="macro-item">
                        <div className="macro-info">
                            <span className="macro-name">{macro.name}</span>
                            {macro.description && (
                                <span className="macro-desc">{macro.description}</span>
                            )}
                        </div>
                        <button 
                            className="btn-run"
                            onClick={() => runMacro(macro.name)}
                            disabled={running === macro.name}
                        >
                            {running === macro.name ? 'RUNNING...' : 'RUN'}
                        </button>
                    </div>
                ))}
            </div>

            <style>{`
                .macros-container {
                    height: 100%;
                    display: flex;
                    flex-direction: column;
                }
                .macros-header {
                    padding: 1.5rem;
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    border-bottom: 1px solid var(--border-light);
                }
                .macros-list {
                    flex: 1;
                    overflow-y: auto;
                    padding: 1rem;
                }
                .macro-item {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    padding: 1rem;
                    margin-bottom: 0.5rem;
                    background: rgba(255,255,255,0.03);
                    border: 1px solid var(--border-light);
                    border-radius: 8px;
                    transition: all 0.2s;
                }
                .macro-item:hover {
                    background: rgba(255,255,255,0.06);
                    border-color: var(--color-primary);
                }
                .macro-info {
                    display: flex;
                    flex-direction: column;
                }
                .macro-name {
                    font-weight: bold;
                    color: var(--text-primary);
                    font-family: monospace;
                }
                .macro-desc {
                    font-size: 0.8rem;
                    color: var(--text-secondary);
                    margin-top: 0.2rem;
                }
                .btn-run {
                    background: var(--color-primary);
                    border: none;
                    color: #fff;
                    padding: 0.5rem 1rem;
                    border-radius: 4px;
                    cursor: pointer;
                    font-weight: bold;
                    font-size: 0.8rem;
                }
                .btn-run:disabled {
                    opacity: 0.5;
                    cursor: not-allowed;
                }
                .btn-small {
                    background: rgba(255,255,255,0.1);
                    border: none;
                    color: var(--text-primary);
                    padding: 0.4rem 0.8rem;
                    border-radius: 4px;
                    cursor: pointer;
                    font-size: 0.8rem;
                }
            `}</style>
        </div>
    );
}
