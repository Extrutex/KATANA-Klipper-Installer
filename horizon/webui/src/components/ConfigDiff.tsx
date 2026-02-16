import { useState, useEffect } from 'react';
import { client } from '../lib/moonraker';

interface ConfigDiff {
    section: string;
    key: string;
    oldValue: string;
    newValue: string;
    status: 'unchanged' | 'added' | 'removed' | 'changed';
}

export default function ConfigDiff() {
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [currentConfig, setCurrentConfig] = useState<Record<string, any>>({});
    const [savedConfig, setSavedConfig] = useState<Record<string, any>>({});
    const [diff, setDiff] = useState<ConfigDiff[]>([]);
    const [activeSection, setActiveSection] = useState<string>('all');

    useEffect(() => {
        loadConfigs();
    }, []);

    const loadConfigs = async () => {
        setLoading(true);
        setError(null);
        
        try {
            const data = await client.fetchConfig();
            
            if (data && data.configfile && data.configfile.config) {
                setCurrentConfig(data.configfile.config);
                setSavedConfig(JSON.parse(JSON.stringify(data.configfile.config)));
            } else {
                setError('Failed to load configuration');
            }
        } catch (err) {
            setError('Connection error: ' + String(err));
        } finally {
            setLoading(false);
        }
    };

    const computeDiff = () => {
        const diffs: ConfigDiff[] = [];
        
        const allSections = new Set([
            ...Object.keys(currentConfig),
            ...Object.keys(savedConfig)
        ]);

        for (const section of allSections) {
            const currentSection = currentConfig[section] || {};
            const savedSection = savedConfig[section] || {};
            const allKeys = new Set([
                ...Object.keys(currentSection),
                ...Object.keys(savedSection)
            ]);

            for (const key of allKeys) {
                const oldVal = savedSection[key] !== undefined ? String(savedSection[key]) : '';
                const newVal = currentSection[key] !== undefined ? String(currentSection[key]) : '';
                
                let status: ConfigDiff['status'] = 'unchanged';
                if (oldVal === '' && newVal !== '') status = 'added';
                else if (oldVal !== '' && newVal === '') status = 'removed';
                else if (oldVal !== newVal) status = 'changed';

                if (status !== 'unchanged') {
                    diffs.push({ section, key, oldValue: oldVal, newValue: newVal, status });
                }
            }
        }

        setDiff(diffs);
    };

    useEffect(() => {
        if (Object.keys(currentConfig).length > 0 && Object.keys(savedConfig).length > 0) {
            computeDiff();
        }
    }, [currentConfig, savedConfig]);

    const handleReload = () => {
        setSavedConfig(JSON.parse(JSON.stringify(currentConfig)));
    };

    const filteredDiff = activeSection === 'all' 
        ? diff 
        : diff.filter(d => d.section === activeSection);

    const sections = [...new Set(diff.map(d => d.section))];

    const getStatusColor = (status: ConfigDiff['status']) => {
        switch (status) {
            case 'added': return '#5f5';
            case 'removed': return '#f55';
            case 'changed': return '#fc0';
            default: return '#888';
        }
    };

    if (loading) {
        return (
            <div className="glass-panel diff-container" style={{ 
                display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%' 
            }}>
                <span style={{ color: '#888' }}>Loading configuration diff...</span>
            </div>
        );
    }

    if (error) {
        return (
            <div className="glass-panel diff-container" style={{ 
                display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%' 
            }}>
                <div style={{ textAlign: 'center', color: '#f55' }}>
                    <h3>Error</h3>
                    <p>{error}</p>
                    <button className="btn-primary" onClick={loadConfigs}>RETRY</button>
                </div>
            </div>
        );
    }

    return (
        <div className="glass-panel diff-container">
            <div className="diff-header">
                <h2>CONFIG DIFF</h2>
                <div className="diff-actions">
                    <button className="btn-small" onClick={loadConfigs}>REFRESH</button>
                    <button className="btn-small" onClick={handleReload}>RESET VIEW</button>
                </div>
            </div>

            <div className="diff-tabs">
                <button 
                    className={`tab ${activeSection === 'all' ? 'active' : ''}`}
                    onClick={() => setActiveSection('all')}
                >
                    ALL ({diff.length})
                </button>
                {sections.slice(0, 5).map(section => (
                    <button 
                        key={section}
                        className={`tab ${activeSection === section ? 'active' : ''}`}
                        onClick={() => setActiveSection(section)}
                    >
                        {section.toUpperCase()}
                    </button>
                ))}
            </div>

            <div className="diff-content">
                {filteredDiff.length === 0 ? (
                    <div className="no-changes">
                        <span style={{ fontSize: '2rem' }}>✓</span>
                        <p>No changes detected</p>
                    </div>
                ) : (
                    <div className="diff-list">
                        {filteredDiff.map((item, idx) => (
                            <div key={idx} className="diff-item" style={{ borderLeftColor: getStatusColor(item.status) }}>
                                <div className="diff-header-row">
                                    <span className="diff-section">{item.section}</span>
                                    <span className="diff-key">{item.key}</span>
                                    <span className="diff-status" style={{ color: getStatusColor(item.status) }}>
                                        {item.status.toUpperCase()}
                                    </span>
                                </div>
                                <div className="diff-values">
                                    {item.status !== 'added' && (
                                        <div className="diff-old">
                                            <span>OLD:</span>
                                            <code>{item.oldValue || '(empty)'}</code>
                                        </div>
                                    )}
                                    {item.status !== 'removed' && (
                                        <div className="diff-new">
                                            <span>NEW:</span>
                                            <code>{item.newValue || '(empty)'}</code>
                                        </div>
                                    )}
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>

            <style>{`
                .diff-container {
                    height: 100%;
                    display: flex;
                    flex-direction: column;
                    overflow: hidden;
                }
                .diff-header {
                    padding: 1.5rem;
                    border-bottom: 1px solid var(--border-light);
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                }
                .diff-actions {
                    display: flex;
                    gap: 0.5rem;
                }
                .diff-tabs {
                    display: flex;
                    border-bottom: 1px solid var(--border-light);
                    overflow-x: auto;
                }
                .tab {
                    padding: 0.8rem 1rem;
                    background: none;
                    border: none;
                    color: var(--text-secondary);
                    cursor: pointer;
                    border-bottom: 2px solid transparent;
                    white-space: nowrap;
                }
                .tab.active {
                    color: var(--color-primary);
                    border-bottom-color: var(--color-primary);
                }
                .diff-content {
                    flex: 1;
                    overflow-y: auto;
                    padding: 1rem;
                }
                .no-changes {
                    text-align: center;
                    padding: 3rem;
                    color: #5f5;
                }
                .diff-list {
                    display: flex;
                    flex-direction: column;
                    gap: 1rem;
                }
                .diff-item {
                    background: rgba(255,255,255,0.02);
                    border: 1px solid var(--border-light);
                    border-left: 3px solid;
                    border-radius: 4px;
                    padding: 1rem;
                }
                .diff-header-row {
                    display: flex;
                    gap: 1rem;
                    margin-bottom: 0.5rem;
                    align-items: center;
                }
                .diff-section {
                    font-weight: bold;
                    color: var(--color-primary);
                }
                .diff-key {
                    flex: 1;
                    font-family: monospace;
                }
                .diff-status {
                    font-size: 0.7rem;
                    font-weight: bold;
                }
                .diff-values {
                    display: flex;
                    flex-direction: column;
                    gap: 0.3rem;
                    font-size: 0.85rem;
                }
                .diff-old span, .diff-new span {
                    color: var(--text-secondary);
                    margin-right: 0.5rem;
                }
                .diff-old code {
                    color: #f55;
                    text-decoration: line-through;
                }
                .diff-new code {
                    color: #5f5;
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
                .btn-primary {
                    background: var(--color-primary);
                    border: none;
                    color: #fff;
                    padding: 0.8rem 1.5rem;
                    border-radius: 4px;
                    cursor: pointer;
                }
            `}</style>
        </div>
    );
}
