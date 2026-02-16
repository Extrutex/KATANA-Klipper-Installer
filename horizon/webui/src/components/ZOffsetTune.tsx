import { useState } from 'react';
import { client } from '../lib/moonraker';

interface ZOffsetWidgetProps {
    printer: any;
}

export default function ZOffsetTune({ printer }: ZOffsetWidgetProps) {
    const [currentZ, setCurrentZ] = useState(0);
    const [saving, setSaving] = useState(false);
    const [message, setMessage] = useState<string | null>(null);

    const toolhead = printer?.objects?.toolhead || {};
    const position = toolhead.position || [0, 0, 0, 0];
    const currentZPos = position[2] || 0;

    const handleMicrostepUp = () => {
        client.sendGCode(`SET_GCODE_OFFSET Z_ADJUST=+0.01 MOVE=1`);
        setCurrentZ(prev => prev + 0.01);
    };

    const handleMicrostepDown = () => {
        client.sendGCode(`SET_GCODE_OFFSET Z_ADJUST=-0.01 MOVE=1`);
        setCurrentZ(prev => prev - 0.01);
    };

    const handleSave = async () => {
        setSaving(true);
        setMessage(null);
        
        try {
            client.sendGCode('SAVE_CONFIG');
            setMessage('Z-Offset saved!');
        } catch (err) {
            setMessage('Failed to save');
        } finally {
            setSaving(false);
            setTimeout(() => setMessage(null), 3000);
        }
    };

    const handleHome = () => {
        client.sendGCode('G28 Z');
    };

    const handleBabyStep = (amount: number) => {
        client.sendGCode(`SET_GCODE_OFFSET Z_ADJUST=${amount} MOVE=1`);
        setCurrentZ(prev => prev + amount);
    };

    return (
        <div style={{ padding: '1rem' }}>
            <div className="z-offset-display">
                <div className="z-label">CURRENT Z</div>
                <div className="z-value">{currentZPos.toFixed(3)}</div>
            </div>

            <div className="z-adjustment">
                <div className="adjustment-row">
                    <span>Baby Stepping:</span>
                    <span className="z-offset-value">{currentZ >= 0 ? '+' : ''}{currentZ.toFixed(3)}mm</span>
                </div>
            </div>

            <div className="quick-buttons">
                <button className="z-btn" onClick={() => handleBabyStep(-0.1)}>-0.1</button>
                <button className="z-btn" onClick={() => handleBabyStep(-0.01)}>-0.01</button>
                <button className="z-btn" onClick={() => handleBabyStep(0.01)}>+0.01</button>
                <button className="z-btn" onClick={() => handleBabyStep(0.1)}>+0.1</button>
            </div>

            <div className="manual-buttons">
                <button className="btn-secondary" onClick={handleMicrostepDown}>▼ DOWN</button>
                <button className="btn-secondary" onClick={handleMicrostepUp}>▲ UP</button>
            </div>

            <div className="action-buttons">
                <button className="btn-small" onClick={handleHome}>HOME Z</button>
                <button className="btn-primary" onClick={handleSave} disabled={saving}>
                    {saving ? 'SAVING...' : 'SAVE'}
                </button>
            </div>

            {message && <div className="z-message">{message}</div>}

            <style>{`
                .z-offset-display {
                    text-align: center;
                    padding: 1rem;
                    background: rgba(0,0,0,0.3);
                    border-radius: 8px;
                    margin-bottom: 1rem;
                }
                .z-label {
                    font-size: 0.7rem;
                    color: var(--text-secondary);
                    letter-spacing: 2px;
                }
                .z-value {
                    font-size: 2rem;
                    font-family: monospace;
                    color: var(--color-primary);
                    text-shadow: 0 0 10px var(--color-primary-glow);
                }
                .z-adjustment {
                    text-align: center;
                    margin-bottom: 1rem;
                }
                .adjustment-row {
                    display: flex;
                    justify-content: space-between;
                    font-size: 0.9rem;
                    color: var(--text-secondary);
                }
                .z-offset-value {
                    font-family: monospace;
                    color: #fc0;
                }
                .quick-buttons {
                    display: flex;
                    gap: 0.5rem;
                    margin-bottom: 1rem;
                }
                .z-btn {
                    flex: 1;
                    padding: 0.5rem;
                    background: rgba(255,255,255,0.05);
                    border: 1px solid var(--border-light);
                    color: var(--text-primary);
                    border-radius: 4px;
                    cursor: pointer;
                    font-size: 0.8rem;
                    transition: all 0.2s;
                }
                .z-btn:hover {
                    background: var(--color-primary);
                    border-color: var(--color-primary);
                }
                .manual-buttons {
                    display: flex;
                    gap: 0.5rem;
                    margin-bottom: 1rem;
                }
                .manual-buttons button {
                    flex: 1;
                }
                .action-buttons {
                    display: flex;
                    gap: 0.5rem;
                }
                .action-buttons button {
                    flex: 1;
                }
                .btn-secondary {
                    background: rgba(255,255,255,0.1);
                    border: 1px solid var(--border-medium);
                    color: var(--text-primary);
                    padding: 0.5rem;
                    border-radius: 4px;
                    cursor: pointer;
                }
                .btn-primary {
                    background: var(--color-primary);
                    border: none;
                    color: #fff;
                    padding: 0.5rem;
                    border-radius: 4px;
                    cursor: pointer;
                    font-weight: bold;
                }
                .btn-primary:disabled {
                    opacity: 0.5;
                    cursor: not-allowed;
                }
                .btn-small {
                    background: rgba(255,255,255,0.1);
                    border: none;
                    color: var(--text-primary);
                    padding: 0.5rem;
                    border-radius: 4px;
                    cursor: pointer;
                    font-size: 0.8rem;
                }
                .z-message {
                    text-align: center;
                    margin-top: 0.5rem;
                    font-size: 0.8rem;
                    color: #5f5;
                }
            `}</style>
        </div>
    );
}
