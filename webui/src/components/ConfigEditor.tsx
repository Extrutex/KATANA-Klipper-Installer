import { useState } from 'react';

// Mock data for prototype
const MOCK_CONFIG = {
    z_offset: 1.25,
    pressure_advance: 0.045,
    max_accel: 3000,
    extruder_temp: 245,
    bed_temp: 100,
    retraction: 0.8
};

export default function ConfigEditor() {
    const [config] = useState(MOCK_CONFIG);
    const [hasChanges] = useState(false);

    return (
        <div className="glass-panel config-container" style={{ position: 'relative' }}>
            {/* NO-ASSUMPTION OVERLAY */}
            <div style={{
                position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
                background: 'rgba(0,0,0,0.7)', zIndex: 10,
                display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
                backdropFilter: 'blur(4px)'
            }}>
                <div style={{
                    border: '2px solid #fc0', padding: '2rem', borderRadius: '8px',
                    background: 'rgba(20,20,0,0.9)', textAlign: 'center', maxWidth: '500px'
                }}>
                    <h2 style={{ color: '#fc0', marginTop: 0 }}>⚠️ PROTOTYPE MODE</h2>
                    <p style={{ color: '#fff', lineHeight: '1.5' }}>
                        This configuration editor is currently using <strong>Mock Data</strong>.<br />
                        To adhere to strict execution rules, editing is disabled until<br />
                        real configuration parsing (via <code>/printer/objects/query?configfile</code>) is implemented.
                    </p>
                </div>
            </div>

            <div className="config-header">
                <h2>VISUAL CONFIG</h2>
                {hasChanges && <span className="badge-unsaved">UNSAVED CHANGES</span>}
            </div>

            <div className="config-grid" style={{ opacity: 0.3, pointerEvents: 'none' }}>

                {/* Z-Offset Section */}
                <div className="config-group">
                    <h3>Calibration</h3>
                    <div className="control-row">
                        <label>Z-Offset (mm)</label>
                        <div className="control-input">
                            <input
                                type="number"
                                step="0.01"
                                value={config.z_offset}
                                readOnly
                            />
                            <div className="slider-container">
                                <input
                                    type="range"
                                    min="0" max="5" step="0.01"
                                    value={config.z_offset}
                                    readOnly
                                />
                            </div>
                        </div>
                    </div>
                    <div className="control-row">
                        <label>Pressure Advance</label>
                        <div className="control-input">
                            <input
                                type="number"
                                step="0.001"
                                value={config.pressure_advance}
                                readOnly
                            />
                        </div>
                    </div>
                </div>

                {/* Performance Section */}
                <div className="config-group">
                    <h3>Performance</h3>
                    <div className="control-row">
                        <label>Max Acceleration</label>
                        <div className="control-input">
                            <input
                                type="number"
                                step="100"
                                value={config.max_accel}
                                readOnly
                            />
                            <div className="slider-container">
                                <input
                                    type="range"
                                    min="500" max="10000" step="100"
                                    value={config.max_accel}
                                    readOnly
                                />
                            </div>
                        </div>
                    </div>
                    <div className="control-row">
                        <label>Retraction (mm)</label>
                        <div className="control-input">
                            <input
                                type="number"
                                step="0.1"
                                value={config.retraction}
                                readOnly
                            />
                        </div>
                    </div>
                </div>

            </div>

            <div className={`save-bar ${hasChanges ? 'visible' : ''}`}>
                <span>You have unsaved changes.</span>
                <div className="save-actions">
                    <button className="btn-secondary" disabled>DISCARD</button>
                    <button className="btn-primary" disabled>SAVE & RESTART</button>
                </div>
            </div>

            <style>{`
                .config-container {
                    padding: 1.5rem;
                    height: 100%;
                    overflow-y: auto;
                    position: relative;
                }
                .config-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    border-bottom: 1px solid rgba(255,255,255,0.1);
                    padding-bottom: 1rem;
                    margin-bottom: 2rem;
                }
                .badge-unsaved {
                    background: rgba(255, 200, 0, 0.2);
                    color: #fc0;
                    padding: 0.2rem 0.8rem;
                    border: 1px solid #fc0;
                    border-radius: 4px;
                    font-size: 0.8rem;
                }
                .config-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
                    gap: 2rem;
                }
                .config-group h3 {
                    color: var(--color-primary);
                    margin-top: 0;
                    margin-bottom: 1.5rem;
                    font-size: 1.1rem;
                    text-transform: uppercase;
                }
                .control-row {
                    margin-bottom: 1.5rem;
                }
                .control-row label {
                    display: block;
                    margin-bottom: 0.5rem;
                    color: #aaa;
                    font-size: 0.9rem;
                }
                .control-input {
                    display: flex;
                    align-items: center;
                    gap: 1rem;
                }
                .control-input input[type="number"] {
                    background: rgba(0,0,0,0.3);
                    border: 1px solid rgba(255,255,255,0.1);
                    color: white;
                    padding: 0.5rem;
                    width: 80px;
                    text-align: right;
                    border-radius: 4px;
                }
                .slider-container {
                    flex: 1;
                }
                input[type="range"] {
                    width: 100%;
                    accent-color: var(--color-primary);
                }

                .save-bar {
                    position: absolute;
                    bottom: -100px;
                    left: 0;
                    right: 0;
                    background: rgba(20,20,20,0.95);
                    border-top: 1px solid var(--color-primary);
                    padding: 1rem 2rem;
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    transition: bottom 0.3s cubic-bezier(0.4, 0, 0.2, 1);
                    box-shadow: 0 -5px 20px rgba(0,0,0,0.5);
                }
                .save-bar.visible {
                    bottom: 0;
                }
                .save-actions {
                    display: flex;
                    gap: 1rem;
                }
                .btn-secondary {
                    background: transparent;
                    border: 1px solid rgba(255,255,255,0.2);
                    color: #ccc;
                    padding: 0.5rem 1rem;
                    cursor: pointer;
                }
            `}</style>
        </div>
    );
}
