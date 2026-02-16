# Service Health Layer

## Sources
- systemd status (via KATANA endpoints/commands) OR via host integration if available
- port bindings (ss)
- filesystem (disk space)
- temperature/throttling (Pi)

## Outputs
- HEALTH_OK / HEALTH_WARN / HEALTH_ERROR
- structured alerts: id, source, severity, message, details, timestamp

## UI Integration
- Dashboard Health Panel
- Error Center aggregates alerts
- “Run Diagnostics” triggers KATANA bundle generator (optional)
