import { useState, useRef, useEffect } from 'react';
import { useGCodeStore, client } from '../lib/moonraker';

export default function ConsolePanel() {
    const [input, setInput] = useState("");
    const { logs, addLog } = useGCodeStore();
    const bottomRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        bottomRef.current?.scrollIntoView({ behavior: "smooth" });
    }, [logs]);

    const handleSend = () => {
        if (!input.trim()) return;

        const cmd = input.trim();
        addLog(`> ${cmd}`, 'command');
        
        client.sendGCode(cmd);
        setInput("");
    };

    const handleRestart = () => {
        addLog(`> FIRMWARE_RESTART`, 'command');
        client.sendGCode("FIRMWARE_RESTART");
    };

    const handleEmergency = () => {
        addLog(`> M112 (EMERGENCY STOP)`, 'command');
        client.sendGCode("M112");
    };

    return (
        <div className="glass-panel console-container">
            <div className="console-header">
                <h2>G-CODE TERMINAL</h2>
                <div className="console-actions">
                    <button className="btn-small" onClick={handleRestart}>RESTART</button>
                    <button className="btn-small error" onClick={handleEmergency}>EMERGENCY</button>
                </div>
            </div>

            <div className="console-output">
                {logs.length === 0 && <div className="log-line info">Ready to receive commands.</div>}
                {logs.map((l, i) => (
                    <div key={i} className={`log-line ${l.type}`}>
                        <span className="timestamp">{new Date(l.time).toLocaleTimeString()}</span>
                        <span className="message">{l.message}</span>
                    </div>
                ))}
                <div ref={bottomRef} />
            </div>

            <div className="console-input-area">
                <input
                    type="text"
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && handleSend()}
                    placeholder="Send G-Code..."
                />
                <button className="btn-primary" onClick={handleSend}>SEND</button>
            </div>

            <style>{`
                .console-container {
                    display: flex;
                    flex-direction: column;
                    height: 100%;
                    overflow: hidden;
                }
                .console-header {
                    padding: 1rem;
                    border-bottom: 1px solid rgba(255,255,255,0.1);
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                }
                .console-output {
                    flex: 1;
                    padding: 1rem;
                    overflow-y: auto;
                    font-family: monospace;
                    background: rgba(0,0,0,0.3);
                }
                .log-line {
                    margin-bottom: 4px;
                    display: flex;
                    gap: 1rem;
                }
                .log-line.command { color: #fff; font-weight: bold; }
                .log-line.response { color: #aaa; }
                .log-line.error { color: #f55; }
                .timestamp { color: #555; font-size: 0.8em; }
                
                .console-input-area {
                    display: flex;
                    padding: 1rem;
                    gap: 1rem;
                    background: rgba(0,0,0,0.5);
                }
                input {
                    flex: 1;
                    background: rgba(255,255,255,0.1);
                    border: 1px solid rgba(255,255,255,0.2);
                    color: white;
                    padding: 0.8rem;
                    border-radius: 4px;
                    font-family: monospace;
                }
                input:focus {
                    outline: none;
                    border-color: var(--color-primary);
                }
                .btn-small {
                    background: rgba(255,255,255,0.1);
                    border: none;
                    color: #fff;
                    padding: 0.4rem 0.8rem;
                    cursor: pointer;
                    margin-left: 0.5rem;
                    font-size: 0.8rem;
                    border-radius: 4px;
                }
                .btn-small.error {
                    background: #500;
                    color: #fcc;
                }

            `}</style>
        </div>
    );
}
