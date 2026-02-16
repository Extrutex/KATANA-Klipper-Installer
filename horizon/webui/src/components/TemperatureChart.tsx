import { useState, useEffect, useRef } from 'react';

interface TempDataPoint {
    time: number;
    temperature: number;
    target: number;
}

export default function TemperatureChart({ printer }: { printer: any }) {
    const [history, setHistory] = useState<{
        nozzle: TempDataPoint[];
        bed: TempDataPoint[];
    }>({
        nozzle: [],
        bed: []
    });
    
    const maxPoints = 60; // 60 data points
    const canvasRef = useRef<HTMLCanvasElement>(null);

    const heater_bed = printer?.objects?.heater_bed || {};
    const extruder = printer?.objects?.extruder || {};

    useEffect(() => {
        const now = Date.now();
        
        setHistory(prev => {
            const newNozzle = [
                ...prev.nozzle,
                { time: now, temperature: extruder.temperature || 0, target: extruder.target || 0 }
            ].slice(-maxPoints);
            
            const newBed = [
                ...prev.bed,
                { time: now, temperature: heater_bed.temperature || 0, target: heater_bed.target || 0 }
            ].slice(-maxPoints);
            
            return { nozzle: newNozzle, bed: newBed };
        });
    }, [printer?.objects?.extruder?.temperature, printer?.objects?.heater_bed?.temperature]);

    useEffect(() => {
        drawChart();
    }, [history]);

    const drawChart = () => {
        const canvas = canvasRef.current;
        if (!canvas) return;
        
        const ctx = canvas.getContext('2d');
        if (!ctx) return;
        
        const width = canvas.width;
        const height = canvas.height;
        
        // Clear
        ctx.fillStyle = 'rgba(0, 0, 0, 0.3)';
        ctx.fillRect(0, 0, width, height);
        
        // Grid
        ctx.strokeStyle = 'rgba(255, 255, 255, 0.1)';
        ctx.lineWidth = 1;
        
        // Horizontal lines
        for (let i = 0; i <= 4; i++) {
            const y = (height / 4) * i;
            ctx.beginPath();
            ctx.moveTo(0, y);
            ctx.lineTo(width, y);
            ctx.stroke();
        }
        
        // Draw temperature line
        const drawLine = (data: TempDataPoint[], color: string, targetColor: string) => {
            if (data.length < 2) return;
            
            const xStep = width / (maxPoints - 1);
            const maxTemp = 300;
            
            // Target line (dashed)
            ctx.setLineDash([5, 5]);
            ctx.strokeStyle = targetColor;
            ctx.beginPath();
            data.forEach((point, i) => {
                const x = i * xStep;
                const y = height - (point.target / maxTemp) * height;
                if (i === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            });
            ctx.stroke();
            
            // Temperature line
            ctx.setLineDash([]);
            ctx.strokeStyle = color;
            ctx.lineWidth = 2;
            ctx.beginPath();
            data.forEach((point, i) => {
                const x = i * xStep;
                const y = height - (point.temperature / maxTemp) * height;
                if (i === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            });
            ctx.stroke();
        };
        
        // Draw nozzle (green)
        drawLine(history.nozzle, '#0f0', 'rgba(0, 255, 0, 0.3)');
        
        // Draw bed (orange)
        drawLine(history.bed, '#f90', 'rgba(255, 150, 0, 0.3)');
    };

    const currentNozzle = extruder.temperature?.toFixed(0) || 0;
    const targetNozzle = extruder.target?.toFixed(0) || 0;
    const currentBed = heater_bed.temperature?.toFixed(0) || 0;
    const targetBed = heater_bed.target?.toFixed(0) || 0;

    return (
        <div style={{ padding: '1rem', height: '100%', display: 'flex', flexDirection: 'column' }}>
            <div className="temp-legend">
                <div className="legend-item">
                    <span className="legend-color" style={{ background: '#0f0' }}></span>
                    <span>Nozzle: {currentNozzle}°C / {targetNozzle}°C</span>
                </div>
                <div className="legend-item">
                    <span className="legend-color" style={{ background: '#f90' }}></span>
                    <span>Bed: {currentBed}°C / {targetBed}°C</span>
                </div>
            </div>
            
            <canvas 
                ref={canvasRef}
                width={400}
                height={150}
                style={{ 
                    width: '100%', 
                    flex: 1,
                    borderRadius: '8px',
                    marginTop: '0.5rem'
                }}
            />

            <style>{`
                .temp-legend {
                    display: flex;
                    justify-content: space-around;
                    font-size: 0.8rem;
                    color: var(--text-secondary);
                }
                .legend-item {
                    display: flex;
                    align-items: center;
                    gap: 0.5rem;
                }
                .legend-color {
                    width: 12px;
                    height: 3px;
                    display: inline-block;
                }
            `}</style>
        </div>
    );
}
