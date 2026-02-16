import { useState, useEffect, useRef } from 'react';
import { client } from '../lib/moonraker';

interface FileItem {
    path: string;
    size: number;
    modified: number;
}

export default function FileManager() {
    const [files, setFiles] = useState<FileItem[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [uploading, setUploading] = useState(false);
    const [uploadProgress, setUploadProgress] = useState(0);
    const fileInputRef = useRef<HTMLInputElement>(null);

    const fetchFiles = async () => {
        setLoading(true);
        setError(null);
        
        try {
            const response = await fetch('/server/files/list?path=gcodes');
            const data = await response.json();
            
            if (data.result) {
                const gcodeFiles: FileItem[] = data.result
                    .filter((f: any) => f.filename.endsWith('.gcode'))
                    .map((f: any) => ({
                        path: f.path,
                        size: f.size,
                        modified: f.modified
                    }));
                setFiles(gcodeFiles);
            }
        } catch (err) {
            console.error('Failed to fetch files:', err);
            setError('Failed to load files. Is Moonraker running?');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchFiles();
    }, []);

    const handleUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
        const file = event.target.files?.[0];
        if (!file) return;

        if (!file.name.endsWith('.gcode')) {
            setError('Only .gcode files are allowed.');
            return;
        }

        setUploading(true);
        setUploadProgress(0);
        setError(null);

        try {
            const formData = new FormData();
            formData.append('file', file);
            formData.append('path', 'gcodes');

            const xhr = new XMLHttpRequest();
            
            xhr.upload.onprogress = (e) => {
                if (e.lengthComputable) {
                    const progress = Math.round((e.loaded / e.total) * 100);
                    setUploadProgress(progress);
                }
            };

            xhr.onload = () => {
                setUploading(false);
                if (xhr.status >= 200 && xhr.status < 300) {
                    fetchFiles();
                    if (fileInputRef.current) {
                        fileInputRef.current.value = '';
                    }
                } else {
                    setError(`Upload failed: ${xhr.statusText}`);
                }
            };

            xhr.onerror = () => {
                setUploading(false);
                setError('Upload failed. Check network connection.');
            };

            xhr.open('POST', '/server/files/upload');
            xhr.send(formData);

        } catch (err) {
            setUploading(false);
            setError('Upload failed: ' + String(err));
        }
    };

    const handleDelete = async (path: string) => {
        if (!confirm(`Delete ${path}?`)) return;
        
        try {
            await fetch('/server/files/delete', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ path })
            });
            fetchFiles();
        } catch (err) {
            console.error('Delete failed:', err);
        }
    };

    const handlePrint = async (path: string) => {
        try {
            client.sendGCode(`PRINT_FILE ${path}`);
        } catch (err) {
            console.error('Print failed:', err);
        }
    };

    return (
        <div className="glass-panel files-container">
            <div className="files-header">
                <h2>G-CODE LIBRARY</h2>
                <div className="actions">
                    <input
                        ref={fileInputRef}
                        type="file"
                        accept=".gcode"
                        onChange={handleUpload}
                        style={{ display: 'none' }}
                        id="file-upload"
                    />
                    <label htmlFor="file-upload" className="btn-primary" style={{ 
                        display: 'inline-block', 
                        cursor: uploading ? 'not-allowed' : 'pointer',
                        opacity: uploading ? 0.6 : 1
                    }}>
                        {uploading ? `UPLOADING ${uploadProgress}%` : 'UPLOAD'}
                    </label>
                    <button className="btn-small" onClick={fetchFiles}>REFRESH</button>
                </div>
            </div>

            {uploading && (
                <div style={{ padding: '0.5rem 1.5rem', background: 'rgba(0,255,100,0.1)', borderBottom: '1px solid rgba(0,255,100,0.2)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem', marginBottom: '0.3rem' }}>
                        <span>Uploading...</span>
                        <span>{uploadProgress}%</span>
                    </div>
                    <div style={{ height: '4px', background: 'rgba(255,255,255,0.1)', borderRadius: '2px' }}>
                        <div style={{ 
                            height: '100%', 
                            width: `${uploadProgress}%`, 
                            background: 'var(--color-primary)',
                            borderRadius: '2px',
                            transition: 'width 0.2s'
                        }} />
                    </div>
                </div>
            )}

            <div className="file-list">
                {loading && (
                    <div style={{ padding: '2rem', textAlign: 'center', color: '#888' }}>
                        Loading files...
                    </div>
                )}
                {error && (
                    <div style={{ padding: '2rem', textAlign: 'center', color: '#f55' }}>
                        {error}
                    </div>
                )}
                {!loading && !error && files.length === 0 && (
                    <div style={{ padding: '2rem', textAlign: 'center', color: '#888' }}>
                        No gcode files found.
                    </div>
                )}
                {!loading && !error && files.length > 0 && (
                    <>
                        <div className="file-row header">
                            <span className="col-name">Filename</span>
                            <span className="col-size">Size</span>
                            <span className="col-date">Date</span>
                            <span className="col-actions">Actions</span>
                        </div>
                        {files.map(file => (
                            <div key={file.path} className="file-row item">
                                <span className="col-name file-icon">{file.path.split('/').pop()}</span>
                                <span className="col-size">{(file.size / 1024 / 1024).toFixed(1)} MB</span>
                                <span className="col-date">{new Date(file.modified * 1000).toLocaleDateString()}</span>
                                <div className="col-actions">
                                    <button className="btn-small action-print" onClick={() => handlePrint(file.path)}>PRINT</button>
                                    <button className="btn-small action-del" onClick={() => handleDelete(file.path)}>DEL</button>
                                </div>
                            </div>
                        ))}
                    </>
                )}
            </div>

            <style>{`
                .files-container {
                    height: 100%;
                    display: flex;
                    flex-direction: column;
                }
                .files-header {
                    padding: 1.5rem;
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    border-bottom: 1px solid rgba(255,255,255,0.1);
                }
                .file-list {
                    padding: 1rem;
                    overflow-y: auto;
                }
                .file-row {
                    display: grid;
                    grid-template-columns: 2fr 1fr 1fr 1.5fr;
                    padding: 0.8rem;
                    align-items: center;
                    border-bottom: 1px solid rgba(255,255,255,0.05);
                }
                .file-row.header {
                    font-weight: bold;
                    color: #888;
                    text-transform: uppercase;
                    font-size: 0.8rem;
                }
                .file-row.item:hover {
                    background: rgba(255,255,255,0.05);
                    border-radius: 6px;
                }
                .file-icon::before {
                    content: "📄";
                    margin-right: 0.5rem;
                }
                .action-print {
                    background: var(--color-primary);
                    color: #fff;
                    border: none;
                }
                .action-del {
                    background: #522;
                    color: #fcc;
                    border: none;
                    margin-left: 0.5rem;
                }
            `}</style>
        </div>
    );
}
