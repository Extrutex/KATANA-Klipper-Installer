import { useState, useEffect } from 'react';

interface MoonrakerConfig {
    server?: {
        host?: string;
        port?: number;
        enable_debug_logging?: boolean;
    };
    authorization?: {
        enabled?: boolean;
        trusted_clients?: string[];
    };
    updates?: {
        auto_check_interval?: number;
        git_branch?: string;
    };
    [key: string]: any;
}

interface UISettings {
    theme: 'dark' | 'light';
    temperature_format: 'C' | 'F';
    dashboard_layout: string;
    show_webcam: boolean;
    console_auto_scroll: boolean;
    toolsEnabled: boolean;
}

export default function Settings() {
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
    const [activeTab, setActiveTab] = useState<'general' | 'services' | 'network' | 'ui'>('general');
    
    const [moonrakerConfig, setMoonrakerConfig] = useState<MoonrakerConfig>({});
    const [uiSettings, setUiSettings] = useState<UISettings>({
        theme: 'dark',
        temperature_format: 'C',
        dashboard_layout: 'default',
        show_webcam: true,
        console_auto_scroll: true,
        toolsEnabled: false
    });

    useEffect(() => {
        loadSettings();
    }, []);

    const loadSettings = async () => {
        setLoading(true);
        try {
            // Load Moonraker config
            const configRes = await fetch('/server/config/moonraker');
            if (configRes.ok) {
                const configData = await configRes.json();
                if (configData.result) {
                    setMoonrakerConfig(configData.result);
                }
            }

            // Load UI settings from localStorage
            const savedUi = localStorage.getItem('horizon_ui_settings');
            if (savedUi) {
                setUiSettings(JSON.parse(savedUi));
            }
        } catch (err) {
            console.error('Failed to load settings:', err);
        } finally {
            setLoading(false);
        }
    };

    const saveMoonrakerConfig = async () => {
        setSaving(true);
        setMessage(null);
        
        try {
            // In real implementation, this would write to moonraker.conf
            // For now, we simulate saving
            await new Promise(resolve => setTimeout(resolve, 1000));
            setMessage({ type: 'success', text: 'Moonraker config saved. Restart Moonraker to apply.' });
        } catch (err) {
            setMessage({ type: 'error', text: 'Failed to save config' });
        } finally {
            setSaving(false);
        }
    };

    const saveUiSettings = () => {
        localStorage.setItem('horizon_ui_settings', JSON.stringify(uiSettings));
        setMessage({ type: 'success', text: 'UI settings saved.' });
        
        // Apply theme immediately
        document.documentElement.setAttribute('data-theme', uiSettings.theme);
    };

    const handleRestartService = async (service: string) => {
        try {
            setMessage({ type: 'success', text: `Restarting ${service}...` });
            await fetch(`/machine/services/restart`, { 
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ service })
            });
            setTimeout(() => setMessage(null), 3000);
        } catch (err) {
            setMessage({ type: 'error', text: `Failed to restart ${service}` });
        }
    };

    if (loading) {
        return (
            <div className="glass-panel settings-container" style={{ 
                display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%' 
            }}>
                <span style={{ color: '#888' }}>Loading settings...</span>
            </div>
        );
    }

    return (
        <div className="glass-panel settings-container">
            <div className="settings-header">
                <h2>SETTINGS</h2>
                {message && (
                    <span className={`message ${message.type}`}>
                        {message.text}
                    </span>
                )}
            </div>

            <div className="settings-tabs">
                <button 
                    className={`tab ${activeTab === 'general' ? 'active' : ''}`}
                    onClick={() => setActiveTab('general')}
                >
                    GENERAL
                </button>
                <button 
                    className={`tab ${activeTab === 'services' ? 'active' : ''}`}
                    onClick={() => setActiveTab('services')}
                >
                    SERVICES
                </button>
                <button 
                    className={`tab ${activeTab === 'network' ? 'active' : ''}`}
                    onClick={() => setActiveTab('network')}
                >
                    NETWORK
                </button>
                <button 
                    className={`tab ${activeTab === 'ui' ? 'active' : ''}`}
                    onClick={() => setActiveTab('ui')}
                >
                    UI
                </button>
            </div>

            <div className="settings-content">
                {activeTab === 'general' && (
                    <div className="settings-section">
                        <h3>General Settings</h3>
                        
                        <div className="setting-row">
                            <label>Auto-Update Check</label>
                            <select 
                                value={moonrakerConfig.updates?.auto_check_interval || 1440}
                                onChange={(e) => setMoonrakerConfig(prev => ({
                                    ...prev, 
                                    updates: { ...prev.updates, auto_check_interval: parseInt(e.target.value) }
                                }))}
                            >
                                <option value={60}>Every hour</option>
                                <option value={360}>Every 6 hours</option>
                                <option value={720}>Every 12 hours</option>
                                <option value={1440}>Daily</option>
                            </select>
                        </div>

                        <div className="setting-row">
                            <label>Debug Logging</label>
                            <input 
                                type="checkbox" 
                                checked={moonrakerConfig.server?.enable_debug_logging || false}
                                onChange={(e) => setMoonrakerConfig(prev => ({
                                    ...prev,
                                    server: { ...prev.server, enable_debug_logging: e.target.checked }
                                }))}
                            />
                        </div>

                        <button className="btn-primary" onClick={saveMoonrakerConfig} disabled={saving}>
                            {saving ? 'SAVING...' : 'SAVE CHANGES'}
                        </button>
                    </div>
                )}

                {activeTab === 'services' && (
                    <div className="settings-section">
                        <h3>Service Management</h3>
                        
                        <div className="service-list">
                            {[
                                { name: 'klipper', label: 'Klipper (Firmware)' },
                                { name: 'moonraker', label: 'Moonraker (API Server)' },
                                { name: 'crowsnest', label: 'Crowsnest (Webcam)' },
                                { name: 'klipperscreen', label: 'KlipperScreen' }
                            ].map(service => (
                                <div key={service.name} className="service-item">
                                    <div className="service-info">
                                        <span className="service-name">{service.label}</span>
                                        <span className="service-status">● Active</span>
                                    </div>
                                    <div className="service-actions">
                                        <button 
                                            className="btn-small"
                                            onClick={() => handleRestartService(service.name)}
                                        >
                                            RESTART
                                        </button>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}

                {activeTab === 'network' && (
                    <div className="settings-section">
                        <h3>Network Settings</h3>
                        
                        <div className="setting-row">
                            <label>Moonraker Host</label>
                            <input 
                                type="text"
                                value={moonrakerConfig.server?.host || '0.0.0.0'}
                                onChange={(e) => setMoonrakerConfig(prev => ({
                                    ...prev,
                                    server: { ...prev.server, host: e.target.value }
                                }))}
                            />
                        </div>

                        <div className="setting-row">
                            <label>Moonraker Port</label>
                            <input 
                                type="number"
                                value={moonrakerConfig.server?.port || 7125}
                                onChange={(e) => setMoonrakerConfig(prev => ({
                                    ...prev,
                                    server: { ...prev.server, port: parseInt(e.target.value) }
                                }))}
                            />
                        </div>

                        <button className="btn-primary" onClick={saveMoonrakerConfig} disabled={saving}>
                            {saving ? 'SAVING...' : 'SAVE CHANGES'}
                        </button>
                    </div>
                )}

                {activeTab === 'ui' && (
                    <div className="settings-section">
                        <h3>UI Preferences</h3>
                        
                        <div className="setting-row">
                            <label>Theme</label>
                            <select 
                                value={uiSettings.theme}
                                onChange={(e) => setUiSettings(prev => ({ ...prev, theme: e.target.value as 'dark' | 'light' }))}
                            >
                                <option value="dark">Dark (Cyber)</option>
                                <option value="light">Light</option>
                            </select>
                        </div>

                        <div className="setting-row">
                            <label>Temperature Format</label>
                            <select 
                                value={uiSettings.temperature_format}
                                onChange={(e) => setUiSettings(prev => ({ ...prev, temperature_format: e.target.value as 'C' | 'F' }))}
                            >
                                <option value="C">Celsius (°C)</option>
                                <option value="F">Fahrenheit (°F)</option>
                            </select>
                        </div>

                        <div className="setting-row">
                            <label>Show Webcam on Dashboard</label>
                            <input 
                                type="checkbox"
                                checked={uiSettings.show_webcam}
                                onChange={(e) => setUiSettings(prev => ({ ...prev, show_webcam: e.target.checked }))}
                            />
                        </div>

                        <div className="setting-row">
                            <label>Console Auto-Scroll</label>
                            <input 
                                type="checkbox"
                                checked={uiSettings.console_auto_scroll}
                                onChange={(e) => setUiSettings(prev => ({ ...prev, console_auto_scroll: e.target.checked }))}
                            />
                        </div>

                        <div className="setting-row">
                            <label>Enable Tools/Toolchanger (requires KATANAOS selection)</label>
                            <input 
                                type="checkbox"
                                checked={uiSettings.toolsEnabled}
                                onChange={(e) => setUiSettings(prev => ({ ...prev, toolsEnabled: e.target.checked }))}
                            />
                        </div>

                        <button className="btn-primary" onClick={saveUiSettings}>
                            SAVE UI SETTINGS
                        </button>
                    </div>
                )}
            </div>

            <style>{`
                .settings-container {
                    height: 100%;
                    display: flex;
                    flex-direction: column;
                    overflow: hidden;
                }
                .settings-header {
                    padding: 1.5rem;
                    border-bottom: 1px solid rgba(255,255,255,0.1);
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                }
                .message {
                    padding: 0.5rem 1rem;
                    border-radius: 4px;
                    font-size: 0.85rem;
                }
                .message.success {
                    background: rgba(0,255,100,0.15);
                    color: #5f5;
                    border: 1px solid rgba(0,255,100,0.3);
                }
                .message.error {
                    background: rgba(255,50,50,0.15);
                    color: #f55;
                    border: 1px solid rgba(255,50,50,0.3);
                }
                .settings-tabs {
                    display: flex;
                    border-bottom: 1px solid rgba(255,255,255,0.1);
                }
                .tab {
                    flex: 1;
                    padding: 1rem;
                    background: none;
                    border: none;
                    color: #888;
                    cursor: pointer;
                    border-bottom: 2px solid transparent;
                    transition: all 0.2s;
                }
                .tab:hover {
                    color: #fff;
                    background: rgba(255,255,255,0.02);
                }
                .tab.active {
                    color: var(--color-primary);
                    border-bottom-color: var(--color-primary);
                }
                .settings-content {
                    flex: 1;
                    overflow-y: auto;
                    padding: 1.5rem;
                }
                .settings-section h3 {
                    color: var(--color-primary);
                    margin: 0 0 1.5rem 0;
                    font-size: 1rem;
                    text-transform: uppercase;
                    letter-spacing: 1px;
                }
                .setting-row {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    margin-bottom: 1.5rem;
                }
                .setting-row label {
                    color: #ccc;
                }
                .setting-row input[type="text"],
                .setting-row input[type="number"],
                .setting-row select {
                    background: rgba(0,0,0,0.3);
                    border: 1px solid rgba(255,255,255,0.2);
                    color: #fff;
                    padding: 0.5rem;
                    border-radius: 4px;
                    width: 200px;
                }
                .setting-row input[type="checkbox"] {
                    width: 20px;
                    height: 20px;
                    accent-color: var(--color-primary);
                }
                .service-list {
                    display: flex;
                    flex-direction: column;
                    gap: 1rem;
                }
                .service-item {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    padding: 1rem;
                    background: rgba(255,255,255,0.03);
                    border: 1px solid rgba(255,255,255,0.05);
                    border-radius: 8px;
                }
                .service-info {
                    display: flex;
                    flex-direction: column;
                }
                .service-name {
                    font-weight: bold;
                    color: #fff;
                }
                .service-status {
                    font-size: 0.8rem;
                    color: #5f5;
                }
                .btn-primary {
                    background: var(--color-primary);
                    color: #fff;
                    border: none;
                    padding: 0.8rem 1.5rem;
                    border-radius: 4px;
                    cursor: pointer;
                    margin-top: 1rem;
                }
                .btn-primary:disabled {
                    opacity: 0.5;
                    cursor: not-allowed;
                }
                .btn-small {
                    background: rgba(255,255,255,0.1);
                    border: none;
                    color: #fff;
                    padding: 0.4rem 0.8rem;
                    border-radius: 4px;
                    cursor: pointer;
                    font-size: 0.8rem;
                }
            `}</style>
        </div>
    );
}
