# Layout Engine Spec

## Requirement
Mainsail-like structure, but fully configurable layout.

## Concepts
- Widget: { id, type, props, minW, minH, defaultW, defaultH }
- Layout: list of widget placements (grid coords)
- Preset: named layout + enabled modules
- Persistence: per user, versioned (migration on updates)

## Rules
- Layout is data-driven; rendering uses registry of widgets
- No business state stored inside layout config
