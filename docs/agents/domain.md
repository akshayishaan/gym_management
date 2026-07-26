# Domain Docs

How engineering skills should consume this repository's domain documentation.

## Before exploring, read these

- `CONTEXT.md` at the repository root.
- `CONTEXT-MAP.md` if it exists, followed by each relevant context document.
- Relevant architectural decisions under `docs/adr/`.

If these files do not exist, proceed silently. The domain-modeling workflow creates them when terminology or architectural decisions are resolved.

## File structure

This is a single-context repository:

```
/
├── CONTEXT.md
├── docs/
│   └── adr/
├── app/
├── components/
├── lib/
└── models/
```

## Use the glossary's vocabulary

When naming domain concepts in issues, refactoring proposals, hypotheses, or tests, use the terms defined in `CONTEXT.md`.

If a needed concept is absent, reconsider whether new terminology is necessary or record the gap for domain modeling.

## Flag ADR conflicts

If proposed work contradicts an existing ADR, identify the conflict explicitly instead of silently overriding the decision.
