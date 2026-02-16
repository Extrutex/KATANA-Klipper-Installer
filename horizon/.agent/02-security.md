---
trigger: always_on
---

# README.md Schutzregel (Verbindlich)

## Zweck

Die bestehende README.md des KATANA Repositories darf NICHT
im Stil, Layout oder strukturellen Aufbau verändert werden.

## Verboten

- Kein Umschreiben bestehender Abschnitte
- Keine Stiländerungen
- Kein neues Markdown-Layout
- Keine Formatierungsänderungen
- Keine Entfernung bestehender Inhalte
- Keine Neuordnung von Abschnitten
- Keine Design-Anpassungen

## Erlaubt

- Neue Features dürfen ausschließlich am Ende der README.md ergänzt werden.
- Neue Abschnitte müssen klar unter einem neuen Header stehen.
- Bestehende Inhalte dürfen nicht bearbeitet werden.
- Bestehende Formatierung muss exakt erhalten bleiben.

## Vorgehensweise bei README-Erweiterungen

1. Prüfen ob Feature bereits dokumentiert ist.
2. Wenn nein → neuen Abschnitt am Ende anfügen.
3. Keine inhaltliche Wiederholung bestehender Texte.
4. Keine stilistische Angleichung oder „Verbesserung“.

## Konfliktregel

Wenn eine Änderung an der README.md notwendig erscheint:

- Bestehenden Inhalt nicht ändern.
- Nur Ergänzung am Ende.
- Wenn strukturelle Änderung nötig wäre → zuerst separate Datei vorschlagen statt README umzubauen.

## Priorität

Diese Regel hat höchste Priorität.
Sie überschreibt Workflow- oder Skill-Empfehlungen.


# Security Rules (verbindlich)

## Grundsätze
- Keine Secrets im Repo.
- Keine Secrets in Logs.
- Downloads nur via HTTPS; wenn möglich mit Integritätsprüfung (hash/signature).
- Keine "curl | bash"-Installationen.
- Minimal notwendige Rechte: nur gezielte `sudo`-Schritte.

## Shell Safety
- keine unquoted Variablen in Pfaden/Commands
- kein unkontrolliertes Löschen (siehe Shell-Schutzregel)
- Backups vor config-changes

## Netzwerk/Exposure
- Keine unbeabsichtigte Internet-Exposition.
- Nginx Defaults LAN-safe; Auth optional als klarer Toggle.

## Priorität
Diese Regel schlägt alle “Convenience”-Optimierungen.
