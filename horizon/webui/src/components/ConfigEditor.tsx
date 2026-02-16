import { useState, useEffect } from 'react';
import { client } from '../lib/moonraker';

interface ConfigSection {
    [key: string]: string | number;
}

export default function ConfigEditor() {
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [hasChanges, setHasChanges] = useState(false);
    const [config, setConfig] = useState<Record<string, ConfigSection>>({});
    const [editableConfig, setEditableConfig] = useState<Record<string, ConfigSection>>({});

    useEffect(() => {
        loadConfig();
    }, []);

    const loadConfig = async () => {
        setLoading(true);
        setError(null);
        
        try {
            const configData = await client.fetchConfig();
            
            if (configData && configData.configfile && configData.configfile.config) {
                const rawConfig = configData.configfile.config;
                setConfig(rawConfig);
                setEditableConfig(JSON.parse(JSON.stringify(rawConfig)));
            } else {
                setError('Failed to load configuration');
            }
        } catch (err) {
            console.error('Config load error:', err);
            setError('Failed to connect to printer');
        } finally {
            setLoading(false);
        }
    };

    const handleChange = (section: string, key: string, value: string | number) => {
        setEditableConfig(prev => ({
            ...prev,
            [section]: {
                ...prev[section],
                [key]: value
            }
        }));
        setHasChanges(true);
    };

    const handleSave = async () => {
        setSaving(true);
        setError(null);

        try {
            const changes: string[] = [];
            
            for (const [section, values] of Object.entries(editableConfig)) {
                const original = config[section] || {};
                for (const [key, value] of Object.entries(values)) {
                    if (String(original[key]) !== String(value)) {
                        changes.push(`SET ${section} ${key} ${value}`);
                    }
                }
            }

            if (changes.length > 0) {
                changes.forEach(gcode => client.sendGCode(gcode));
                client.sendGCode('SAVE_CONFIG');
            }
            
            setHasChanges(false);
            await loadConfig();
        } catch (err) {
            setError('Failed to save: ' + String(err));
        } finally {
            setSaving(false);
        }
    };

    const handleDiscard = () => {
        setEditableConfig(JSON.parse(JSON.stringify(config)));
        setHasChanges(false);
    };

    if (loading) {
        return (
            <div className="glass-panel config-container" style={{ 
                display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%' 
            }}>
                <div style={{ textAlign: 'center', color: '#888' }}>
                    Loading configuration...
                </div>
            </div>
        );
    }

    if (error && !config) {
        return (
            <div className="glass-panel config-container" style={{ 
                display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%' 
            }}>
                <div style={{ textAlign: 'center', color: '#f55' }}>
                    <h3>Error</h3>
                    <p>{error}</p>
                    <button className="btn-primary" onClick={loadConfig}>RETRY</button>
                </div>
            </div>
        );
    }

    return (
        <div className="glass-panel config-container">
            <div className="config-header">
                <h2>PRINTER CONFIG</h2>
                {hasChanges && <span className="badge-unsaved">UNSAVED CHANGES</span>}
            </div>

            <div className="config-content">
                {Object.entries(editableConfig).map(([sectionName, sectionValues]) => (
                    <div key={sectionName} className="config-section">
                        <h3 className="section-title">{sectionName.toUpperCase()}</h3>
                        <div className="section-fields">
                            {Object.entries(sectionValues).slice(0, 6).map(([key, value]) => (
                                <div key={key} className="config-row">
                                    <label>{key}</label>
                                    <input
                                        type={typeof value === 'number' ? 'number' : 'text'}
                                        value={String(value)}
                                        onChange={(e) => {
                                            const val = typeof value === 'number' 
                                                ? parseFloat(e.target.value) || 0 
                                                : e.target.value;
                                            handleChange(sectionName, key, val);
                                        }}
                                    />
                                </div>
                            ))}
                        </div>
                    </div>
                ))}
            </div>

            {hasChanges && (
                <div className="save-bar">
                    <span>You have unsaved changes.</span>
                    <div className="save-actions">
                        <button className="btn-secondary" onClick={handleDiscard}>DISCARD</button>
                        <button className="btn-primary" onClick={handleSave} disabled={saving}>
                            {saving ? 'SAVING...' : 'SAVE & RESTART'}
                        </button>
                    </div>
                </div>
            )}

            <style>{`
                .config-container {
                    height: 100%;
                    display: flex;
                    flex-direction: column;
                    overflow: hidden;
                }
                .config-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    padding: 1.5rem;
                    border-bottom: 1px solid rgba(255,255,255,0.1);
                    flex-shrink: 0;
                }
                .badge-unsaved {
                    background: rgba(255, 200, 0, 0.2);
                    color: #fc0;
                    padding: 0.2rem 0.8rem;
                    border: 1px solid #fc0;
                    border-radius: 4px;
                    font-size: 0.8rem;
                }
                .config-content {
                    flex: 1;
                    overflow-y: auto;
                    padding: 1rem;
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                    gap: 1rem;
                }
                .config-section {
                    background: rgba(255,255,255,0.03);
                    border: 1px solid rgba(255,255,255,0.05);
                    border-radius: 8px;
                    padding: 1rem;
                }
                .section-title {
                    color: var(--color-primary);
                    margin: 0 0 1rem 0;
                    font-size: 0.9rem;
                    padding-bottom: 0.5rem;
                    border-bottom: 1px solid rgba(255,255,255,0.1);
                }
                .config-row {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    margin-bottom: 0.8rem;
                }
                .config-row label {
                    color: #aaa;
                    font-size: 0.85rem;
                    flex: 1;
                }
                .config-row input {
                    background: rgba(0,0,0,0.3);
                    border: 1px solid rgba(255,255,255,0.2);
                    color: white;
                    padding: 0.4rem;
                    border-radius: 4px;
                    width: 100px;
                    text-align: right;
                }
                .save-bar {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    padding: 1rem 1.5rem;
                    background: rgba(20,20,20,0.95);
                    border-top: 1px solid var(--color-primary);
                }
                .save-actions {
                    display: flex;
                    gap: 1rem;
                }
                .btn-primary, .btn-secondary {
                    padding: 0.5rem 1rem;
                    border-radius: 4px;
                    cursor: pointer;
                    border: none;
                }
                .btn-primary {
                    background: var(--color-primary);
                    color: white;
                }
                .btn-secondary {
                    background: transparent;
                    border: 1px solid rgba(255,255,255,0.2);
                    color: #ccc;
                }
            `}</style>
        </div>
    );
}
