import { useState, useEffect } from 'react';

interface JobHistoryItem {
    filename: string;
    status: 'completed' | 'cancelled' | 'failed';
    start_time: number;
    end_time: number;
    total_duration: number;
    print_duration: number;
    filament_used?: number;
    metadata?: {
        size: number;
        slicer: string;
        first_layer_bed_temp?: number;
        first_layer_extr_temp?: number;
        layer_height?: number;
    };
}

export default function JobHistory() {
    const [jobs, setJobs] = useState<JobHistoryItem[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    const fetchJobs = async () => {
        setLoading(true);
        setError(null);
        
        try {
            const response = await fetch('/server/history/list?limit=50');
            const data = await response.json();
            
            if (data.result && data.result.jobs) {
                setJobs(data.result.jobs);
            } else {
                setJobs([]);
            }
        } catch (err) {
            console.error('Failed to fetch job history:', err);
            setError('Failed to load job history');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchJobs();
    }, []);

    const formatDuration = (seconds: number) => {
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        const s = Math.floor(seconds % 60);
        
        if (h > 0) {
            return `${h}h ${m}m`;
        } else if (m > 0) {
            return `${m}m ${s}s`;
        }
        return `${s}s`;
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

    const formatFilament = (mm: number) => {
        if (!mm) return '-';
        return `${(mm / 1000).toFixed(2)}m`;
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'completed': return '#5f5';
            case 'cancelled': return '#fa0';
            case 'failed': return '#f55';
            default: return '#888';
        }
    };

    return (
        <div className="glass-panel history-container">
            <div className="history-header">
                <h2>PRINT HISTORY</h2>
                <button className="btn-small" onClick={fetchJobs}>REFRESH</button>
            </div>

            <div className="history-list">
                {loading && (
                    <div style={{ padding: '2rem', textAlign: 'center', color: '#888' }}>
                        Loading history...
                    </div>
                )}
                
                {error && (
                    <div style={{ padding: '2rem', textAlign: 'center', color: '#f55' }}>
                        {error}
                    </div>
                )}
                
                {!loading && !error && jobs.length === 0 && (
                    <div style={{ padding: '2rem', textAlign: 'center', color: '#888' }}>
                        No print history available.
                    </div>
                )}
                
                {!loading && !error && jobs.length > 0 && (
                    <>
                        <div className="history-row header">
                            <span className="col-status">Status</span>
                            <span className="col-file">Filename</span>
                            <span className="col-date">Date</span>
                            <span className="col-duration">Duration</span>
                            <span className="col-filament">Filament</span>
                        </div>
                        
                        {jobs.map((job, idx) => (
                            <div key={idx} className="history-row item">
                                <span className="col-status">
                                    <span 
                                        className="status-dot" 
                                        style={{ background: getStatusColor(job.status) }}
                                        title={job.status}
                                    />
                                </span>
                                <span className="col-file" title={job.filename}>
                                    {job.filename}
                                </span>
                                <span className="col-date">
                                    {formatDate(job.start_time)}
                                </span>
                                <span className="col-duration">
                                    {formatDuration(job.print_duration || job.total_duration)}
                                </span>
                                <span className="col-filament">
                                    {formatFilament(job.filament_used || 0)}
                                </span>
                            </div>
                        ))}
                    </>
                )}
            </div>

            <style>{`
                .history-container {
                    height: 100%;
                    display: flex;
                    flex-direction: column;
                }
                .history-header {
                    padding: 1.5rem;
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    border-bottom: 1px solid rgba(255,255,255,0.1);
                }
                .history-list {
                    flex: 1;
                    overflow-y: auto;
                    padding: 1rem;
                }
                .history-row {
                    display: grid;
                    grid-template-columns: 60px 2fr 1.5fr 1fr 1fr;
                    padding: 0.8rem;
                    align-items: center;
                    border-bottom: 1px solid rgba(255,255,255,0.05);
                }
                .history-row.header {
                    font-weight: bold;
                    color: #888;
                    text-transform: uppercase;
                    font-size: 0.75rem;
                    position: sticky;
                    top: 0;
                    background: rgba(10,10,14,0.95);
                    z-index: 1;
                }
                .history-row.item:hover {
                    background: rgba(255,255,255,0.03);
                }
                .status-dot {
                    display: inline-block;
                    width: 10px;
                    height: 10px;
                    border-radius: 50%;
                }
                .col-file {
                    overflow: hidden;
                    text-overflow: ellipsis;
                    white-space: nowrap;
                    padding-right: 1rem;
                }
                .col-date, .col-duration, .col-filament {
                    font-family: monospace;
                    font-size: 0.85rem;
                    color: #aaa;
                }
                .btn-small {
                    background: rgba(255,255,255,0.1);
                    border: none;
                    color: #fff;
                    padding: 0.4rem 0.8rem;
                    cursor: pointer;
                    font-size: 0.8rem;
                    border-radius: 4px;
                }
            `}</style>
        </div>
    );
}
