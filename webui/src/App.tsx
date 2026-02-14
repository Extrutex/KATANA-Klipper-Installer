import { useKatanaLink } from './lib/moonraker';
import ConsolePanel from './components/ConsolePanel';
import FileManager from './components/FileManager';
import SystemHealth from './components/SystemHealth';
import ConfigEditor from './components/ConfigEditor';
import DiagnosticsPanel from './components/DiagnosticsPanel';
import DashboardLayout from './components/DashboardLayout';
import JobHistory from './components/JobHistory';
import Settings from './components/Settings';
import ConfigDiff from './components/ConfigDiff';
import Macros from './components/Macros';
import { useState, useEffect } from 'react';
import './index.css';

type View = 'DASHBOARD' | 'CONSOLE' | 'FILES' | 'SYSTEM' | 'CONFIG' | 'DIAGNOSTICS' | 'JOBS' | 'SETTINGS' | 'CONFIGDIFF' | 'MACROS';

function App() {
  const printer = useKatanaLink();
  const [activeView, setActiveView] = useState<View>('DASHBOARD');

  useEffect(() => {
    const savedSettings = localStorage.getItem('horizon_ui_settings');
    if (savedSettings) {
      try {
        const settings = JSON.parse(savedSettings);
        if (settings.theme) {
          document.documentElement.setAttribute('data-theme', settings.theme);
        }
      } catch (e) {
        console.error('Failed to load theme:', e);
      }
    }
  }, []);

  if (!printer) return <div className="loading">Initializing KATANA Uplink...</div>;

  return (
    <div className="app-container">
      {/* HEADER */}
      <header className="glass-panel header">
        <div className="branding">
          <h1>HORIZON</h1>
          <span className="status-badge" data-status={printer.status}>
            {printer.status.toUpperCase()}
          </span>
        </div>
        <nav>
          <button className={`nav-item ${activeView === 'DASHBOARD' ? 'active' : ''}`} onClick={() => setActiveView('DASHBOARD')}>DASHBOARD</button>
          <button className={`nav-item ${activeView === 'JOBS' ? 'active' : ''}`} onClick={() => setActiveView('JOBS')}>JOBS</button>
          <button className={`nav-item ${activeView === 'CONSOLE' ? 'active' : ''}`} onClick={() => setActiveView('CONSOLE')}>CONSOLE</button>
          <button className={`nav-item ${activeView === 'FILES' ? 'active' : ''}`} onClick={() => setActiveView('FILES')}>FILES</button>
          <button className={`nav-item ${activeView === 'MACROS' ? 'active' : ''}`} onClick={() => setActiveView('MACROS')}>MACROS</button>
          <button className={`nav-item ${activeView === 'CONFIG' ? 'active' : ''}`} onClick={() => setActiveView('CONFIG')}>CONFIG</button>
          <button className={`nav-item ${activeView === 'CONFIGDIFF' ? 'active' : ''}`} onClick={() => setActiveView('CONFIGDIFF')}>CONFIG DIFF</button>
          <button className={`nav-item ${activeView === 'DIAGNOSTICS' ? 'active' : ''}`} onClick={() => setActiveView('DIAGNOSTICS')}>DIAGNOSTICS</button>
          <button className={`nav-item ${activeView === 'SYSTEM' ? 'active' : ''}`} onClick={() => setActiveView('SYSTEM')}>SYSTEM</button>
          <button className={`nav-item ${activeView === 'SETTINGS' ? 'active' : ''}`} onClick={() => setActiveView('SETTINGS')}>SETTINGS</button>
        </nav>
      </header>

      {/* MAIN CONTENT AREA */}
      <main className="main-content">

        {activeView === 'DASHBOARD' && (
          <DashboardLayout />
        )}

        {/* JOBS VIEW */}
        {activeView === 'JOBS' && <JobHistory />}

        {/* CONSOLE VIEW */}
        {activeView === 'CONSOLE' && <ConsolePanel />}

        {/* FILES VIEW */}
        {activeView === 'FILES' && <FileManager />}

        {/* MACROS VIEW */}
        {activeView === 'MACROS' && <Macros />}

        {/* CONFIG VIEW */}
        {activeView === 'CONFIG' && <ConfigEditor />}

        {/* CONFIG DIFF VIEW */}
        {activeView === 'CONFIGDIFF' && <ConfigDiff />}

        {/* DIAGNOSTICS VIEW */}
        {activeView === 'DIAGNOSTICS' && <DiagnosticsPanel />}

        {/* SYSTEM VIEW */}
        {activeView === 'SYSTEM' && <SystemHealth />}

        {/* SETTINGS VIEW */}
        {activeView === 'SETTINGS' && <Settings />}

      </main>

      {/* CSS For Layout */}
      <style>{`
        .app-container {
          height: 100vh;
          display: flex;
          flex-direction: column;
          padding: 1rem;
          gap: 1rem;
          background: radial-gradient(circle at 50% 50%, #1a1d24 0%, #0f1115 100%);
        }

        .header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 1rem 2rem;
          flex-shrink: 0;
        }
        
        .main-content {
          flex: 1;
          overflow: hidden; /* Handle inner scrolls */
        }
        
        .dashboard-grid {
          display: grid;
          grid-template-columns: 300px 1fr 300px;
          gap: 1rem;
          height: 100%;
        }

        /* ... existing shared styles ... */
        .status-badge {
           margin-left: 1rem;
           padding: 0.2rem 0.5rem;
           border-radius: 4px;
           font-size: 0.8rem;
           background: rgba(0,255,100,0.2);
           color: #5f5;
           border: 1px solid #5f5;
        }

        .nav-item {
           background: none;
           border: none;
           color: #aaa;
           font-family: var(--font-display);
           margin-left: 1rem;
           cursor: pointer;
           font-size: 1rem;
           padding-bottom: 5px;
        }
        .nav-item.active {
           color: var(--color-primary);
           border-bottom: 2px solid var(--color-primary);
           text-shadow: 0 0 10px var(--color-primary-glow);
        }

        .card { padding: 1.5rem; margin-bottom: 1rem; }
        .metric-row { display: flex; justify-content: space-between; margin: 0.5rem 0; font-family: monospace; font-size: 1.2rem; }
        .temp-gauge { margin-top: 1rem; }
        .bar-container { height: 8px; background: rgba(255,255,255,0.1); border-radius: 4px; margin: 0.5rem 0; overflow: hidden; }
        .bar-fill { height: 100%; background: var(--color-primary); box-shadow: 0 0 10px var(--color-primary); transition: width 0.5s ease; }
        .viewport { height: 100%; display: flex; align-items: center; justify-content: center; background: #000; color: #333; }
        .warning { border-color: #f55; background: linear-gradient(135deg, #500, #900); }

      `}</style>
    </div>
  );
}

export default App;
