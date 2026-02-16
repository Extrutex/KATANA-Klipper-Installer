# Websocket Supervisor Spec

## Goals
- stable realtime
- visible connection health
- controlled reconnection
- bounded memory usage

## Connection States
- CONNECTING
- ONLINE
- DEGRADED (ws up but events missing/heartbeat issues)
- OFFLINE

## Heartbeat
- ping/pong or periodic server event expectation
- timeout -> DEGRADED -> OFFLINE

## Reconnect
- exponential backoff with jitter
- max retry interval cap
- manual retry button in UI

## Fallback
- when OFFLINE/DEGRADED: poll key endpoints at controlled interval
