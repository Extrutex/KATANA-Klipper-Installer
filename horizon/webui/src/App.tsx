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
import Toolchanger from './components/Toolchanger';
import TimelapseViewer from './components/TimelapseViewer';
import { useState, useEffect } from 'react';
import './index.css';

type View = 'DASHBOARD' | 'CONSOLE' | 'FILES' | 'SYSTEM' | 'CONFIG' | 'DIAGNOSTICS' | 'JOBS' | 'SETTINGS' | 'CONFIGDIFF' | 'MACROS' | 'TOOLCHANGER' | 'TIMELAPSE';

interface NavItem {
  id: View;
  label: string;
  icon: string;
}

const baseNavItems: NavItem[] = [
  { id: 'DASHBOARD', label: 'Dashboard', icon: '◈' },
  { id: 'JOBS', label: 'Jobs', icon: '▣' },
  { id: 'FILES', label: 'Files', icon: '▤' },
  { id: 'CONSOLE', label: 'Console', icon: '▧' },
  { id: 'MACROS', label: 'Macros', icon: '⚡' },
  { id: 'TIMELAPSE', label: 'Timelapse', icon: '◷' },
  { id: 'CONFIG', label: 'Config', icon: '⚙' },
  { id: 'CONFIGDIFF', label: 'Diff', icon: '⇆' },
  { id: 'DIAGNOSTICS', label: 'Diag', icon: '⛑' },
  { id: 'SYSTEM', label: 'System', icon: '☰' },
  { id: 'SETTINGS', label: 'Settings', icon: '☾' },
];

function App() {
  const printer = useKatanaLink();
  const [activeView, setActiveView] = useState<View>('DASHBOARD');
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [toolsEnabled, setToolsEnabled] = useState(false);

  useEffect(() => {
    const savedSettings = localStorage.getItem('horizon_ui_settings');
    if (savedSettings) {
      try {
        const settings = JSON.parse(savedSettings);
        if (settings.theme) {
          document.documentElement.setAttribute('data-theme', settings.theme);
        }
        if (settings.toolsEnabled) {
          setToolsEnabled(true);
        }
      } catch (e) {
        console.error('Failed to load theme:', e);
      }
    }
  }, []);

  const navItems = toolsEnabled 
    ? [...baseNavItems, { id: 'TOOLCHANGER' as View, label: 'Tools', icon: '🔧' }]
    : baseNavItems;

  if (!printer) return <div className="loading">Initializing KATANA Uplink...</div>;

  return (
    <div className="app-container">
      <aside className={`sidebar ${sidebarCollapsed ? 'collapsed' : ''}`}>
        <div className="sidebar-header">
          {!sidebarCollapsed && <h1 className="logo">HORIZON</h1>}
          <button className="collapse-btn" onClick={() => setSidebarCollapsed(!sidebarCollapsed)}>
            {sidebarCollapsed ? '▶' : '◀'}
          </button>
        </div>
        
        <div className="status-indicator" data-status={printer.status}>
          <span className="status-dot"></span>
          {!sidebarCollapsed && <span className="status-text">{printer.status}</span>}
        </div>

        <nav className="sidebar-nav">
          {navItems.map((item) => (
            <button
              key={item.id}
              className={`nav-item ${activeView === item.id ? 'active' : ''}`}
              onClick={() => setActiveView(item.id as View)}
              title={item.label}
            >
              <span className="nav-icon">{item.icon}</span>
              {!sidebarCollapsed && <span className="nav-label">{item.label}</span>}
            </button>
          ))}
        </nav>
      </aside>

      <main className="main-content">
        {activeView === 'DASHBOARD' && <DashboardLayout />}
        {activeView === 'JOBS' && <JobHistory />}
        {activeView === 'CONSOLE' && <ConsolePanel />}
        {activeView === 'FILES' && <FileManager />}
        {activeView === 'MACROS' && <Macros />}
        {activeView === 'TOOLCHANGER' && <Toolchanger />}
        {activeView === 'TIMELAPSE' && <TimelapseViewer />}
        {activeView === 'CONFIG' && <ConfigEditor />}
        {activeView === 'CONFIGDIFF' && <ConfigDiff />}
        {activeView === 'DIAGNOSTICS' && <DiagnosticsPanel />}
        {activeView === 'SYSTEM' && <SystemHealth />}
        {activeView === 'SETTINGS' && <Settings />}
      </main>

      <style>{`
        .app-container {
          height: 100vh;
          display: flex;
          background: var(--bg-dark);
        }
        
        .sidebar {
          width: 220px;
          background: var(--bg-panel);
          backdrop-filter: blur(20px);
          border-right: 1px solid var(--border-light);
          display: flex;
          flex-direction: column;
          transition: width 0.3s ease;
          flex-shrink: 0;
        }
        
        .sidebar.collapsed { width: 60px; }
        
        .sidebar-header {
          padding: 1rem;
          display: flex;
          align-items: center;
          justify-content: space-between;
          border-bottom: 1px solid var(--border-light);
        }
        
        .logo {
          font-size: 1.2rem;
          margin: 0;
          background: linear-gradient(90deg, #fff, var(--color-primary));
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
        }
        
        .collapse-btn {
          background: none;
          border: none;
          color: var(--text-secondary);
          cursor: pointer;
          font-size: 0.8rem;
        }
        
        .status-indicator {
          margin: 1rem;
          padding: 0.5rem;
          border-radius: 8px;
          display: flex;
          align-items: center;
          gap: 0.5rem;
          background: rgba(255,255,255,0.03);
        }
        
        .status-dot {
          width: 8px;
          height: 8px;
          border-radius: 50%;
          background: #555;
        }
        
        .status-indicator[data-status="ready"] .status-dot {
          background: #5f5;
          box-shadow: 0 0 8px #5f5;
        }
        
        .status-indicator[data-status="printing"] .status-dot {
          background: #fc0;
          box-shadow: 0 0 8px #fc0;
          animation: pulse 1s infinite;
        }
        
        .status-indicator[data-status="error"] .status-dot {
          background: #f55;
          box-shadow: 0 0 8px #f55;
        }
        
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.5; }
        }
        
        .status-text {
          font-size: 0.8rem;
          text-transform: uppercase;
          letter-spacing: 1px;
        }
        
        .sidebar-nav {
          flex: 1;
          padding: 0.5rem;
          overflow-y: auto;
        }
        
        .nav-item {
          width: 100%;
          display: flex;
          align-items: center;
          gap: 0.8rem;
          padding: 0.8rem;
          margin-bottom: 0.2rem;
          background: none;
          border: none;
          border-radius: 8px;
          color: var(--text-secondary);
          cursor: pointer;
          transition: all 0.2s ease;
          text-align: left;
        }
        
        .nav-item:hover {
          background: var(--bg-hover);
          color: var(--text-primary);
        }
        
        .nav-item.active {
          background: rgba(0, 255, 136, 0.1);
          color: var(--color-primary);
          border-left: 3px solid var(--color-primary);
        }
        
        .nav-icon {
          font-size: 1.1rem;
          width: 24px;
          text-align: center;
        }
        
        .nav-label {
          font-size: 0.9rem;
        }
        
        .sidebar.collapsed .nav-item {
          justify-content: center;
          padding: 0.8rem 0;
        }
        
        .main-content {
          flex: 1;
          overflow: hidden;
          display: flex;
          flex-direction: column;
        }
        
        .loading {
          height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 1.2rem;
          color: var(--color-primary);
          animation: blink 1s infinite;
        }
        
        @keyframes blink {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.5; }
        }
      `}</style>
    </div>
  );
}

export default App;
