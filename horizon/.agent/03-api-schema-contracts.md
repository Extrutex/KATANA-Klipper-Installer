# API Schema Contracts  (Moonraker) 

## Goals
- type safety
- validation
- error mapping

## Must
- zentraler Moonraker Client (ein Ort)
- response validation (schema/type)
- error mapping (netzwerk, timeout, json, schema mismatch)
- retries nur kontrolliert (nicht “spam”)

## Policy
- all responses validated (typed)
- schema mismatch is an error category, not silently ignored

## Error Categories
- NETWORK (dns, refused)
- TIMEOUT
- HTTP_ERROR
- JSON_PARSE
- SCHEMA_MISMATCH
- AUTH (if enabled)
- SERVER (moonraker internal)

## Observability
- log trace_id per request (frontend)
- show last_success_timestamp per module

