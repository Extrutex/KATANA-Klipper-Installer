# Skill: API Validation Layer (Moonraker)

## Ziel
Kein UI-State ohne validierte Daten.
Responses müssen typisiert/validiert werden (Schema).

## Muss
- zentraler Moonraker Client (ein Ort)
- response validation (schema/type)
- error mapping (netzwerk, timeout, json, schema mismatch)
- retries nur kontrolliert (nicht “spam”)

## Output-Contract
Jeder API Call liefert:
- data (validiert) ODER
- error { category, message, details, retryable, source }
