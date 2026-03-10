# AGENTS.md — AI Agent Entry Point

This file is the entry point for AI coding agents working in this repository.

## Documentation Structure

```
docs/ja/    # PRIMARY — Japanese source of truth
docs/en/    # DERIVED — English translations for AI use
```

**Always treat `docs/ja/` as the authoritative source for all design decisions and specifications.**
`docs/en/` is kept in sync automatically via GitHub Actions, but `docs/ja/` takes precedence in any conflict.

## Reading Order for Agents

When starting work on this repository, read documents in this order:

1. [`docs/en/proposal.md`](docs/en/proposal.md) — Understand the game concept and goals
2. [`docs/en/game_structure.md`](docs/en/game_structure.md) — Understand overall architecture and systems
3. [`docs/en/recipe.md`](docs/en/recipe.md) — Core game mechanic: 10-axis recipe evaluation
4. [`docs/en/customer.md`](docs/en/customer.md) — Customer categories and satisfaction logic
5. [`docs/en/location.md`](docs/en/location.md) — Shop location and traffic calculations
6. [`docs/en/menu.md`](docs/en/menu.md) — Pricing and menu strategy
7. [`docs/en/scene.md`](docs/en/scene.md) — UI screens and navigation

For the full index see [`docs/en/index.md`](docs/en/index.md).

## Documentation Priority Rules

1. `docs/ja/` is the ground truth — if English and Japanese versions differ, Japanese is correct
2. When updating specifications, always update `docs/ja/` first; `docs/en/` will be synced automatically
3. Do not manually edit `docs/en/` files if they were auto-generated; edit `docs/ja/` instead

## Work Management

All tasks and work items are tracked as GitHub Issues. There is no `tasks/` directory — do not create one.

## Code Structure

- `server/` — Go backend (Gin + oapi-codegen). The `server/gen/` package is auto-generated; do not edit it directly.
- `server/handlers/` — API endpoint logic to implement
- `server/data/` — CSV master data (ingredients.csv, customers.csv)
- `phaser-app/` — Phaser.js frontend prototype
- `scripts/` — Python game mechanic prototypes

## Key Implementation Notes

- The 10 evaluation axes are: umami, aroma, saltiness, fat, sweetness, spiciness, originality, visual, volume, harmony
- Customer satisfaction is computed by comparing recipe scores against customer preference vectors with weighted scoring
- OpenAPI spec is at `server/openapi_spec.yaml`; run `make generate` after changes
- Master data is loaded from CSV on server startup
