import { useState, useEffect, useRef } from 'react';
import { useKatanaLink, client } from '../lib/moonraker';

interface PrinterData {
  objects?: {
    toolhead?: {
      position?: number[];
      status?: string;
      velocity?: number;
      max_velocity?: number;
      max_accel?: number;
    };
    extruder?: {
      temperature?: number;
      target?: number;
      pressure_advance?: number;
      smooth_time?: number;
      can_extrude?: boolean;
    };
    heater_bed?: {
      temperature?: number;
      target?: number;
    };
    fan?: {
      speed?: number;
    };
    print_stats?: {
      filename?: string;
      total_duration?: number;
      print_duration?: number;
      progress?: number;
      current_layer?: number;
      total_layers?: number;
      filament_used?: number;
      state?: string;
    };
  };
  status?: string;
  webhooks?: {
    state?: string;
    state_message?: string;
  };
}

function EmergencyStop() {
  return (
    <button 
      className="emergency-btn" 
      onClick={() => client.sendGCode('emergency_stop')}
      title="Emergency Stop - Click to stop immediately"
    >
      ⚠ E-STOP
    </button>
  );
}

interface TempDataPoint {
  time: number;
  nozzle: number;
  bed: number;
}

function TemperatureChart() {
  const [history, setHistory] = useState<TempDataPoint[]>([]);
  const printer = useKatanaLink();
  
  useEffect(() => {
    const interval = setInterval(() => {
      const nozzle = printer?.objects?.extruder?.temperature || 0;
      const bed = printer?.objects?.heater_bed?.temperature || 0;
      setHistory(prev => {
        const newPoint = { time: Date.now(), nozzle, bed };
        const updated = [...prev, newPoint].slice(-60);
        return updated;
      });
    }, 1000);
    return () => clearInterval(interval);
  }, [printer]);

  if (history.length < 2) return <div className="temp-chart-loading">Waiting for data...</div>;

  const maxTemp = Math.max(300, ...history.map(h => Math.max(h.nozzle, h.bed)));
  const height = 120;
  const width = 300;

  const nozzlePath = history.map((p, i) => {
    const x = (i / (history.length - 1)) * width;
    const y = height - (p.nozzle / maxTemp) * height;
    return `${i === 0 ? 'M' : 'L'} ${x} ${y}`;
  }).join(' ');

  const bedPath = history.map((p, i) => {
    const x = (i / (history.length - 1)) * width;
    const y = height - (p.bed / maxTemp) * height;
    return `${i === 0 ? 'M' : 'L'} ${x} ${y}`;
  }).join(' ');

  return (
    <div className="temp-chart">
      <svg viewBox={`0 0 ${width} ${height}`} className="chart-svg">
        <defs>
          <linearGradient id="nozzleGrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#ff6b35" stopOpacity="0.3"/>
            <stop offset="100%" stopColor="#ff6b35" stopOpacity="0"/>
          </linearGradient>
          <linearGradient id="bedGrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#3b82f6" stopOpacity="0.3"/>
            <stop offset="100%" stopColor="#3b82f6" stopOpacity="0"/>
          </linearGradient>
        </defs>
        <path d={nozzlePath + ` L${width} ${height} L0 ${height} Z`} fill="url(#nozzleGrad)" />
        <path d={nozzlePath} fill="none" stroke="#ff6b35" strokeWidth="2" />
        <path d={bedPath} fill="none" stroke="#3b82f6" strokeWidth="2" />
      </svg>
      <div className="chart-legend">
        <span className="legend-nozzle">● Nozzle</span>
        <span className="legend-bed">● Bed</span>
      </div>
    </div>
  );
}

function ToolheadControl({ printer }: { printer: PrinterData }) {
  const toolhead = printer?.objects?.toolhead || {};
  const pos = toolhead.position || [0, 0, 0];
  const [speed, setSpeed] = useState(50);
  const moveDistances = [0.1, 1, 5, 10, 25, 50];
  const [dist, setDist] = useState(1);

  const move = (axis: string, delta: number) => {
    client.sendGCode(`G91`);
    client.sendGCode(`G0 ${axis}${delta} F${speed * 60}`);
    client.sendGCode(`G90`);
  };

  return (
    <div className="panel">
      <div className="panel-header">
        <span>Toolhead</span>
      </div>
      <div className="panel-content">
        <div className="position-display">
          <div className="pos">
            <span className="pos-label">X</span>
            <span className="pos-value">{pos[0]?.toFixed(2) || '0.00'}</span>
          </div>
          <div className="pos">
            <span className="pos-label">Y</span>
            <span className="pos-value">{pos[1]?.toFixed(2) || '0.00'}</span>
          </div>
          <div className="pos">
            <span className="pos-label">Z</span>
            <span className="pos-value">{pos[2]?.toFixed(2) || '0.00'}</span>
          </div>
        </div>

        <div className="speed-control">
          <label>Speed: {speed} mm/s</label>
          <input 
            type="range" 
            min="5" 
            max="150" 
            value={speed} 
            onChange={(e) => setSpeed(Number(e.target.value))} 
          />
        </div>

        <div className="move-distances">
          {moveDistances.map(d => (
            <button 
              key={d} 
              className={dist === d ? 'active' : ''}
              onClick={() => setDist(d)}
            >
              {d}
            </button>
          ))}
        </div>

        <div className="d-pad">
          <div className="d-pad-row">
            <span></span>
            <button onClick={() => move('Y', -dist)}>▲</button>
            <span></span>
          </div>
          <div className="d-pad-row">
            <button onClick={() => move('X', -dist)}>◀</button>
            <button className="home" onClick={() => client.sendGCode('G28')}>🏠</button>
            <button onClick={() => move('X', dist)}>▶</button>
          </div>
          <div className="d-pad-row">
            <span></span>
            <button onClick={() => move('Y', dist)}>▼</button>
            <span></span>
          </div>
        </div>

        <div className="z-buttons">
          <button onClick={() => move('Z', dist)}>Z+{dist}</button>
          <button onClick={() => move('Z', -dist)}>Z-{dist}</button>
        </div>

        <button className="motors-off" onClick={() => client.sendGCode('M84')}>
          Motors Off
        </button>
      </div>
    </div>
  );
}

function ExtruderControl({ printer }: { printer: PrinterData }) {
  const extruder = printer?.objects?.extruder || {};
  const [extrudeLen, setExtrudeLen] = useState(5);
  const [extrudeSpeed, setExtrudeSpeed] = useState(5);

  return (
    <div className="panel">
      <div className="panel-header">
        <span>Extruder</span>
      </div>
      <div className="panel-content">
        <div className="temp-control-row">
          <div className="temp-current">
            <span className="temp-value">{(extruder.temperature || 0).toFixed(0)}°C</span>
            <span className="temp-target">/ {(extruder.target || 0).toFixed(0)}°C</span>
          </div>
          <input 
            type="range" 
            min="0" 
            max="300" 
            value={extruder.target || 0}
            onChange={(e) => client.sendGCode(`M104 S${e.target.value}`)}
            className="temp-slider"
          />
        </div>

        <div className="extrude-controls">
          <div className="control-group">
            <label>Length (mm)</label>
            <input 
              type="number" 
              value={extrudeLen}
              onChange={(e) => setExtrudeLen(Number(e.target.value))}
            />
          </div>
          <div className="control-group">
            <label>Speed (mm/s)</label>
            <input 
              type="number" 
              value={extrudeSpeed}
              onChange={(e) => setExtrudeSpeed(Number(e.target.value))}
            />
          </div>
        </div>

        <div className="extrude-buttons">
          <button 
            className="extrude"
            onClick={() => {
              client.sendGCode('G91');
              client.sendGCode(`G0 E${extrudeLen} F${extrudeSpeed * 60}`);
              client.sendGCode('G90');
            }}
          >
            Extrude
          </button>
          <button 
            className="retract"
            onClick={() => {
              client.sendGCode('G91');
              client.sendGCode(`G0 E-${extrudeLen} F${extrudeSpeed * 60}`);
              client.sendGCode('G90');
            }}
          >
            Retract
          </button>
        </div>
      </div>
    </div>
  );
}

function TemperaturePanel({ printer }: { printer: PrinterData }) {
  const heater_bed = printer?.objects?.heater_bed || {};
  const extruder = printer?.objects?.extruder || {};

  const presets = [
    { name: 'PLA', nozzle: 200, bed: 60 },
    { name: 'PETG', nozzle: 240, bed: 80 },
    { name: 'ABS', nozzle: 250, bed: 100 },
    { name: 'TPU', nozzle: 220, bed: 40 },
    { name: 'OFF', nozzle: 0, bed: 0 },
  ];

  return (
    <div className="panel">
      <div className="panel-header">
        <span>Temperatures</span>
      </div>
      <div className="panel-content">
        <div className="temp-row">
          <span className="temp-label">Nozzle</span>
          <div className="temp-bar-wrap">
            <div 
              className="temp-bar-fill orange"
              style={{ width: `${Math.min(100, (extruder.temperature || 0) / (extruder.target || 1) * 100)}%` }}
            />
          </div>
          <span className="temp-nums">{(extruder.temperature || 0).toFixed(0)}° / {(extruder.target || 0).toFixed(0)}°C</span>
        </div>

        <div className="temp-row">
          <span className="temp-label">Bed</span>
          <div className="temp-bar-wrap">
            <div 
              className="temp-bar-fill blue"
              style={{ width: `${Math.min(100, (heater_bed.temperature || 0) / (heater_bed.target || 1) * 100)}%` }}
            />
          </div>
          <span className="temp-nums">{(heater_bed.temperature || 0).toFixed(0)}° / {(heater_bed.target || 0).toFixed(0)}°C</span>
        </div>

        <div className="temp-presets">
          {presets.map(p => (
            <button 
              key={p.name}
              onClick={() => {
                client.sendGCode(`M104 S${p.nozzle}`);
                client.sendGCode(`M140 S${p.bed}`);
              }}
            >
              {p.name}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

function PrintStatus({ printer }: { printer: PrinterData }) {
  const print_stats = printer?.objects?.print_stats || {};
  const status = printer?.status || 'offline';
  
  const progress = print_stats.progress || 0;
  const eta = print_stats.total_duration && print_stats.print_duration 
    ? print_stats.total_duration - print_stats.print_duration 
    : 0;

  const fmtTime = (s: number) => {
    const h = Math.floor(s / 3600);
    const m = Math.floor((s % 3600) / 60);
    return h > 0 ? `${h}h ${m}m` : `${m}m`;
  };

  return (
    <div className="panel">
      <div className="panel-header">
        <span>Print Status</span>
        <span className={`status-badge ${status}`}>{status}</span>
      </div>
      <div className="panel-content">
        <div className="filename">{print_stats.filename || 'No file loaded'}</div>
        
        {status === 'printing' || status === 'paused' ? (
          <>
            <div className="progress-bar-wrap">
              <div className="progress-bar-fill" style={{ width: `${progress * 100}%` }} />
            </div>
            <div className="progress-info">
              <span>{(progress * 100).toFixed(1)}%</span>
              <span>ETA: {eta > 0 ? fmtTime(eta) : '--'}</span>
            </div>
            <div className="layer-info">
              Layer: {print_stats.current_layer || 0} / {print_stats.total_layers || 0}
            </div>
          </>
        ) : null}

        <div className="print-controls">
          {status === 'printing' ? (
            <button onClick={() => client.sendGCode('PAUSE')}>⏸</button>
          ) : status === 'paused' ? (
            <button onClick={() => client.sendGCode('RESUME')}>▶</button>
          ) : null}
          <button 
            className="cancel"
            onClick={() => client.sendGCode('CANCEL_PRINT')}
          >
            ✕
          </button>
        </div>
      </div>
    </div>
  );
}

function WebcamPanel() {
  const [error, setError] = useState(false);
  const imgRef = useRef<HTMLImageElement>(null);

  useEffect(() => {
    if (imgRef.current) imgRef.current.src = '/webcam/?action=stream';
  }, []);

  return (
    <div className="panel webcam">
      <div className="panel-header">
        <span>Camera</span>
      </div>
      <div className="webcam-content">
        {error ? (
          <div className="no-signal">No Signal</div>
        ) : (
          <img ref={imgRef} alt="Webcam" onError={() => setError(true)} />
        )}
      </div>
    </div>
  );
}

export default function DashboardLayout() {
  const printer = useKatanaLink();

  if (!printer) return <div className="loading">Connecting...</div>;

  return (
    <div className="dashboard">
      <div className="toolbar">
        <div className="toolbar-left">
          <h1>KATANA</h1>
        </div>
        <div className="toolbar-right">
          <EmergencyStop />
        </div>
      </div>
      
      <div className="dashboard-grid">
        <div className="col-left">
          <ToolheadControl printer={printer} />
          <ExtruderControl printer={printer} />
          <TemperaturePanel printer={printer} />
        </div>
        
        <div className="col-center">
          <WebcamPanel />
          <TemperatureChart />
        </div>
        
        <div className="col-right">
          <PrintStatus printer={printer} />
        </div>
      </div>

      <style>{`
        :root {
          --bg-primary: #1a1a1f;
          --bg-secondary: #232329;
          --bg-tertiary: #2d2d35;
          --border: #3a3a42;
          --text: #e5e5e5;
          --text-muted: #8b8b8f;
          --accent: #3b82f6;
          --success: #22c55e;
          --warning: #f59e0b;
          --danger: #ef4444;
          --orange: #ff6b35;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
          background: var(--bg-primary);
          color: var(--text);
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          font-size: 14px;
        }

        .dashboard {
          min-height: 100vh;
          display: flex;
          flex-direction: column;
        }

        .toolbar {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 0.75rem 1.25rem;
          background: var(--bg-secondary);
          border-bottom: 1px solid var(--border);
        }

        .toolbar h1 {
          font-size: 1.5rem;
          font-weight: 700;
          color: var(--text);
          letter-spacing: 3px;
        }

        .emergency-btn {
          background: var(--danger);
          color: white;
          border: none;
          padding: 0.6rem 1.25rem;
          border-radius: 4px;
          font-weight: 700;
          font-size: 0.85rem;
          cursor: pointer;
          letter-spacing: 1px;
        }

        .emergency-btn:hover {
          filter: brightness(1.1);
        }

        .dashboard-grid {
          display: grid;
          grid-template-columns: 320px 1fr 300px;
          gap: 1rem;
          padding: 1rem;
          flex: 1;
        }

        .col-left, .col-center, .col-right {
          display: flex;
          flex-direction: column;
          gap: 1rem;
        }

        .col-center {
          display: grid;
          grid-template-rows: 1fr auto;
          gap: 1rem;
        }

        .panel {
          background: var(--bg-secondary);
          border: 1px solid var(--border);
          border-radius: 8px;
          overflow: hidden;
        }

        .panel-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 0.6rem 1rem;
          background: var(--bg-tertiary);
          border-bottom: 1px solid var(--border);
          font-size: 0.75rem;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          color: var(--text-muted);
        }

        .panel-content {
          padding: 1rem;
        }

        .status-badge {
          font-size: 0.65rem;
          padding: 0.2rem 0.5rem;
          border-radius: 3px;
          text-transform: uppercase;
        }

        .status-badge.ready { background: rgba(34,197,94,0.2); color: var(--success); }
        .status-badge.printing { background: rgba(245,158,10,0.2); color: var(--warning); }
        .status-badge.paused { background: rgba(59,130,246,0.2); color: var(--accent); }
        .status-badge.error { background: rgba(239,68,68,0.2); color: var(--danger); }

        /* Position Display */
        .position-display {
          display: flex;
          gap: 0.5rem;
          margin-bottom: 1rem;
        }

        .pos {
          flex: 1;
          background: var(--bg-primary);
          padding: 0.6rem;
          border-radius: 6px;
          text-align: center;
        }

        .pos-label {
          display: block;
          font-size: 0.65rem;
          color: var(--text-muted);
          text-transform: uppercase;
        }

        .pos-value {
          display: block;
          font-size: 1.1rem;
          font-family: 'SF Mono', Monaco, monospace;
          font-weight: 600;
          margin-top: 0.25rem;
        }

        /* Speed Control */
        .speed-control {
          margin-bottom: 0.75rem;
        }

        .speed-control label {
          display: block;
          font-size: 0.7rem;
          color: var(--text-muted);
          margin-bottom: 0.35rem;
        }

        .speed-control input[type="range"] {
          width: 100%;
          height: 4px;
          -webkit-appearance: none;
          background: var(--bg-primary);
          border-radius: 2px;
        }

        .speed-control input[type="range"]::-webkit-slider-thumb {
          -webkit-appearance: none;
          width: 14px;
          height: 14px;
          background: var(--accent);
          border-radius: 50%;
          cursor: pointer;
        }

        /* Move Distances */
        .move-distances {
          display: flex;
          gap: 0.35rem;
          margin-bottom: 1rem;
        }

        .move-distances button {
          flex: 1;
          padding: 0.4rem;
          background: var(--bg-primary);
          border: 1px solid var(--border);
          color: var(--text-muted);
          border-radius: 4px;
          font-size: 0.7rem;
          cursor: pointer;
        }

        .move-distances button.active {
          background: var(--accent);
          color: white;
          border-color: var(--accent);
        }

        /* D-Pad */
        .d-pad {
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 0.35rem;
          margin-bottom: 0.75rem;
        }

        .d-pad-row {
          display: flex;
          gap: 0.35rem;
        }

        .d-pad button {
          width: 48px;
          height: 40px;
          background: var(--bg-primary);
          border: 1px solid var(--border);
          color: var(--text);
          border-radius: 6px;
          cursor: pointer;
          font-size: 1rem;
        }

        .d-pad button.home {
          font-size: 1.2rem;
        }

        .d-pad button:hover {
          background: var(--border);
        }

        .z-buttons {
          display: flex;
          gap: 0.5rem;
          margin-bottom: 0.75rem;
        }

        .z-buttons button {
          flex: 1;
          padding: 0.5rem;
          background: var(--bg-primary);
          border: 1px solid var(--border);
          color: var(--text);
          border-radius: 4px;
          cursor: pointer;
        }

        .motors-off {
          width: 100%;
          padding: 0.5rem;
          background: transparent;
          border: 1px solid var(--border);
          color: var(--text-muted);
          border-radius: 4px;
          font-size: 0.75rem;
          cursor: pointer;
        }

        /* Extruder */
        .temp-control-row {
          display: flex;
          align-items: center;
          gap: 1rem;
          margin-bottom: 1rem;
        }

        .temp-current {
          min-width: 80px;
        }

        .temp-current .temp-value {
          font-size: 1.5rem;
          font-weight: 600;
          display: block;
        }

        .temp-current .temp-target {
          font-size: 0.8rem;
          color: var(--text-muted);
        }

        .temp-slider {
          flex: 1;
          height: 6px;
          -webkit-appearance: none;
          background: var(--bg-primary);
          border-radius: 3px;
        }

        .temp-slider::-webkit-slider-thumb {
          -webkit-appearance: none;
          width: 16px;
          height: 16px;
          background: var(--orange);
          border-radius: 50%;
          cursor: pointer;
        }

        .extrude-controls {
          display: flex;
          gap: 0.75rem;
          margin-bottom: 1rem;
        }

        .control-group {
          flex: 1;
        }

        .control-group label {
          display: block;
          font-size: 0.65rem;
          color: var(--text-muted);
          margin-bottom: 0.25rem;
        }

        .control-group input {
          width: 100%;
          padding: 0.4rem;
          background: var(--bg-primary);
          border: 1px solid var(--border);
          color: var(--text);
          border-radius: 4px;
        }

        .extrude-buttons {
          display: flex;
          gap: 0.5rem;
        }

        .extrude-buttons button {
          flex: 1;
          padding: 0.6rem;
          border: none;
          border-radius: 4px;
          font-weight: 600;
          cursor: pointer;
        }

        .extrude-buttons .extrude {
          background: var(--success);
          color: white;
        }

        .extrude-buttons .retract {
          background: var(--warning);
          color: white;
        }

        /* Temperature Panel */
        .temp-row {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          margin-bottom: 0.75rem;
        }

        .temp-label {
          width: 50px;
          font-size: 0.75rem;
          color: var(--text-muted);
        }

        .temp-bar-wrap {
          flex: 1;
          height: 6px;
          background: var(--bg-primary);
          border-radius: 3px;
          overflow: hidden;
        }

        .temp-bar-fill {
          height: 100%;
          transition: width 0.3s;
        }

        .temp-bar-fill.orange { background: var(--orange); }
        .temp-bar-fill.blue { background: var(--accent); }

        .temp-nums {
          width: 80px;
          font-size: 0.7rem;
          font-family: monospace;
          text-align: right;
          color: var(--text-muted);
        }

        .temp-presets {
          display: flex;
          gap: 0.35rem;
          margin-top: 1rem;
        }

        .temp-presets button {
          flex: 1;
          padding: 0.45rem;
          background: var(--bg-primary);
          border: 1px solid var(--border);
          color: var(--text-muted);
          border-radius: 4px;
          font-size: 0.65rem;
          cursor: pointer;
        }

        .temp-presets button:hover {
          background: var(--border);
          color: var(--text);
        }

        /* Print Status */
        .filename {
          font-size: 0.85rem;
          margin-bottom: 0.75rem;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }

        .progress-bar-wrap {
          height: 8px;
          background: var(--bg-primary);
          border-radius: 4px;
          overflow: hidden;
          margin-bottom: 0.5rem;
        }

        .progress-bar-fill {
          height: 100%;
          background: var(--success);
          transition: width 0.3s;
        }

        .progress-info {
          display: flex;
          justify-content: space-between;
          font-size: 0.75rem;
          color: var(--text-muted);
          margin-bottom: 0.5rem;
        }

        .layer-info {
          font-size: 0.75rem;
          color: var(--text-muted);
          margin-bottom: 1rem;
        }

        .print-controls {
          display: flex;
          gap: 0.5rem;
        }

        .print-controls button {
          flex: 1;
          padding: 0.6rem;
          background: var(--bg-primary);
          border: 1px solid var(--border);
          color: var(--text);
          border-radius: 4px;
          font-size: 1rem;
          cursor: pointer;
        }

        .print-controls button.cancel {
          background: var(--danger);
          border-color: var(--danger);
          color: white;
        }

        /* System Panel */
        .system-panel {
          display: flex;
          flex-direction: column;
          gap: 1rem;
        }

        .system-section {
          padding-bottom: 0.75rem;
          border-bottom: 1px solid var(--border);
        }

        .system-section:last-child {
          border-bottom: none;
          padding-bottom: 0;
        }

        .section-title {
          font-size: 0.65rem;
          font-weight: 600;
          color: var(--text-muted);
          text-transform: uppercase;
          letter-spacing: 0.5px;
          margin-bottom: 0.5rem;
        }

        .sys-row {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          margin-bottom: 0.5rem;
          font-size: 0.75rem;
        }

        .sys-label {
          width: 70px;
          color: var(--text-muted);
        }

        .sys-value {
          width: 40px;
          text-align: right;
          font-family: monospace;
          font-size: 0.7rem;
        }

        .sys-bar {
          flex: 1;
          height: 6px;
          background: var(--bg-primary);
          border-radius: 3px;
          overflow: hidden;
        }

        .sys-fill {
          height: 100%;
          transition: width 0.3s;
        }

        .service-row {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 0.4rem 0;
          font-size: 0.75rem;
        }

        .service-name {
          color: var(--text-muted);
        }

        .service-status {
          font-size: 0.65rem;
          padding: 0.15rem 0.5rem;
          border-radius: 3px;
          text-transform: uppercase;
          font-weight: 600;
        }

        .service-status.ready, .service-status.online {
          background: rgba(34, 197, 94, 0.2);
          color: #22c55e;
        }

        .service-status.startup {
          background: rgba(245, 158, 10, 0.2);
          color: #f59e0b;
        }

        .service-status.error, .service-status.disconnected {
          background: rgba(239, 68, 68, 0.2);
          color: #ef4444;
        }

        .version-row {
          display: flex;
          justify-content: space-between;
          font-size: 0.7rem;
          padding: 0.25rem 0;
        }

        .version-row span:first-child {
          color: var(--text-muted);
        }

        .version-value {
          font-family: monospace;
          color: var(--text);
        }

        .header-info {
          font-size: 0.6rem;
          color: var(--text-muted);
          font-weight: normal;
        }

        /* Temperature Chart */
        .temp-chart {
          background: var(--bg-secondary);
          border: 1px solid var(--border);
          border-radius: 8px;
          padding: 1rem;
        }

        .temp-chart-loading {
          background: var(--bg-secondary);
          border: 1px solid var(--border);
          border-radius: 8px;
          padding: 2rem;
          text-align: center;
          color: var(--text-muted);
        }

        .chart-svg {
          width: 100%;
          height: 120px;
        }

        .chart-legend {
          display: flex;
          justify-content: center;
          gap: 1.5rem;
          margin-top: 0.5rem;
          font-size: 0.7rem;
        }

        .legend-nozzle { color: var(--orange); }
        .legend-bed { color: var(--accent); }

        /* Webcam */
        .webcam {
          min-height: 400px;
        }

        .webcam-content {
          background: #000;
          min-height: 350px;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .webcam-content img {
          width: 100%;
          height: 100%;
          object-fit: contain;
        }

        .no-signal {
          color: var(--text-muted);
        }

        .loading {
          height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          color: var(--text-muted);
        }

        @media (max-width: 1400px) {
          .dashboard-grid {
            grid-template-columns: 1fr 1fr;
          }
        }

        @media (max-width: 900px) {
          .dashboard-grid {
            grid-template-columns: 1fr;
          }
        }
      `}</style>
    </div>
  );
}
