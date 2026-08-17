# Domain Docs

This file tells the engineering skills how to use this repository's domain documentation.

## Before exploration, read these files

- **`CONTEXT.md`** at the repository root, or
- **`CONTEXT-MAP.md`** at the repository root if it exists. It points to one `CONTEXT.md` for each context. Read each file that is applicable to the task.
- **`docs/adr/`**—read ADRs that apply to the area that you will change. In multi-context repositories, also check `src/<context>/docs/adr/` for context-specific decisions.

If these files do not exist, proceed silently. Do not report their absence. Do not suggest that they must be created before work starts. The `/domain-modeling` skill creates them when terms or decisions are resolved.

## File structure

This repository uses the single-context layout:

```text
/
├── CONTEXT.md
├── docs/adr/
│   ├── 0001-event-sourced-orders.md
│   └── 0002-postgres-for-write-model.md
└── src/
```

## Use the glossary vocabulary

When output names a domain concept, use the term defined in `CONTEXT.md`. This rule applies to issue titles, refactor proposals, hypotheses, and test names. Do not use a synonym that the glossary tells you to avoid.

If the required concept is not in the glossary, check if you are creating language that the project does not use. If the missing concept is a real gap, record it for `/domain-modeling`.

## Report ADR conflicts

If output conflicts with an existing ADR, report the conflict. Do not silently replace the decision.

Example:

> _Conflicts with ADR-0007 (event-sourced orders), but it can be reviewed again because…_
