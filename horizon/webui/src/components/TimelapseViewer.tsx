import { useState, useEffect } from 'react';

interface TimelapseFile {
    filename: string;
    size: number;
    modified: number;
}

export default function TimelapseViewer() {
    const [files, setFiles] = useState<TimelapseFile[]>([]);
    const [loading, setLoading] = useState(true);
    const [selectedFile, setSelectedFile] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        fetchTimelapses();
    }, []);

    const fetchTimelapses = async () => {
        setLoading(true);
        setError(null);
        
        try {
            const response = await fetch('/server/files/list?path=timelapse');
            const data = await response.json();
            
            if (data.result) {
                const timelapses: TimelapseFile[] = data.result
                    .filter((f: any) => f.filename.endsWith('.mp4'))
                    .map((f: any) => ({
                        filename: f.filename,
                        size: f.size,
                        modified: f.modified
                    }));
                setFiles(timelapses);
            } else {
                setFiles([]);
            }
        } catch (err) {
            console.error('Failed to fetch timelapses:', err);
            setError('Failed to load timelapses');
        } finally {
            setLoading(false);
        }
    };

    const formatSize = (bytes: number) => {
        if (bytes < 1024) return bytes + ' B';
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
        return (bytes / 1024 / 1024).toFixed(1) + ' MB';
    };

    const formatDate = (timestamp: number) => {
        return new Date(timestamp * 1000).toLocaleDateString('de-DE', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    };

    const deleteTimelapse = async (filename: string) => {
        if (!confirm(`Delete ${filename}?`)) return;
        
        try {
            await fetch('/server/files/delete', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ path: `timelapse/${filename}` })
            });
            fetchTimelapses();
        } catch (err) {
            console.error('Delete failed:', err);
        }
    };

    if (loading) {
        return (
            <div style={{ 
                padding: '2rem', 
                textAlign: 'center', 
                color: 'var(--text-secondary)' 
            }}>
                Loading timelapses...
            </div>
        );
    }

    return (
        <div className="glass-panel timelapse-container">
            <div className="timelapse-header">
                <h2>TIMELAPSE</h2>
                <button className="btn-refresh" onClick={fetchTimelapses}>
                    ↻ REFRESH
                </button>
            </div>

            {error && (
                <div className="error-message">{error}</div>
            )}

            {files.length === 0 ? (
                <div className="empty-state">
                    <span className="empty-icon">🎬</span>
                    <p>No timelapses found.</p>
                    <p className="empty-hint">
                        Start a print with timelapse enabled to capture one!
                    </p>
                </div>
            ) : (
                <div className="timelapse-grid">
                    {files.map((file) => (
                        <div 
                            key={file.filename} 
                            className={`timelapse-card ${selectedFile === file.filename ? 'selected' : ''}`}
                            onClick={() => setSelectedFile(file.filename)}
                        >
                            <div className="thumbnail">
                                <span>🎬</span>
                            </div>
                            <div className="timelapse-info">
                                <span className="filename">{file.filename}</span>
                                <span className="meta">
                                    {formatSize(file.size)} • {formatDate(file.modified)}
                                </span>
                            </div>
                            <button 
                                className="btn-delete"
                                onClick={(e) => {
                                    e.stopPropagation();
                                    deleteTimelapse(file.filename);
                                }}
                            >
                                🗑️
                            </button>
                        </div>
                    ))}
                </div>
            )}

            {selectedFile && (
                <div className="preview-panel">
                    <div className="preview-header">
                        <span>{selectedFile}</span>
                        <button onClick={() => setSelectedFile(null)}>✕</button>
                    </div>
                    <video 
                        controls 
                        autoPlay 
                        src={`/timelapse/${selectedFile}`}
                        className="preview-video"
                    />
                </div>
            )}

            <style>{`
                .timelapse-container {
                    height: 100%;
                    display: flex;
                    flex-direction: column;
                    padding: 0;
                }
                .timelapse-header {
                    padding: 1.5rem;
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    border-bottom: 1px solid var(--border-light);
                }
                .btn-refresh {
                    background: rgba(255,255,255,0.1);
                    border: none;
                    color: var(--text-primary);
                    padding: 0.5rem 1rem;
                    border-radius: 4px;
                    cursor: pointer;
                }
                .error-message {
                    padding: 1rem;
                    background: rgba(255,50,50,0.1);
                    color: #f55;
                    text-align: center;
                }
                .empty-state {
                    flex: 1;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    color: var(--text-secondary);
                }
                .empty-icon {
                    font-size: 3rem;
                    margin-bottom: 1rem;
                }
                .empty-hint {
                    font-size: 0.85rem;
                    opacity: 0.7;
                }
                .timelapse-grid {
                    flex: 1;
                    overflow-y: auto;
                    padding: 1rem;
                    display: grid;
                    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
                    gap: 1rem;
                }
                .timelapse-card {
                    background: rgba(255,255,255,0.03);
                    border: 1px solid var(--border-light);
                    border-radius: 8px;
                    overflow: hidden;
                    cursor: pointer;
                    transition: all 0.2s;
                    display: flex;
                    flex-direction: column;
                }
                .timelapse-card:hover {
                    border-color: var(--color-primary);
                }
                .timelapse-card.selected {
                    border-color: var(--color-primary);
                    box-shadow: 0 0 15px var(--color-primary-glow);
                }
                .thumbnail {
                    height: 100px;
                    background: rgba(0,0,0,0.3);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-size: 2rem;
                }
                .timelapse-info {
                    padding: 0.8rem;
                }
                .filename {
                    display: block;
                    font-size: 0.85rem;
                    color: var(--text-primary);
                    white-space: nowrap;
                    overflow: hidden;
                    text-overflow: ellipsis;
                }
                .meta {
                    font-size: 0.75rem;
                    color: var(--text-secondary);
                }
                .btn-delete {
                    position: absolute;
                    top: 0.5rem;
                    right: 0.5rem;
                    background: rgba(255,50,50,0.8);
                    border: none;
                    border-radius: 4px;
                    padding: 0.3rem;
                    cursor: pointer;
                    opacity: 0;
                    transition: opacity 0.2s;
                }
                .timelapse-card:hover .btn-delete {
                    opacity: 1;
                }
                .preview-panel {
                    position: fixed;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    width: 80%;
                    max-width: 800px;
                    background: rgba(0,0,0,0.95);
                    border: 1px solid var(--color-primary);
                    border-radius: 12px;
                    z-index: 100;
                }
                .preview-header {
                    padding: 1rem;
                    display: flex;
                    justify-content: space-between;
                    border-bottom: 1px solid var(--border-light);
                }
                .preview-video {
                    width: 100%;
                    display: block;
                }
            `}</style>
        </div>
    );
}
