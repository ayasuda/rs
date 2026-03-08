# Ramen Simulator

A ramen shop simulation game with deep recipe crafting and management mechanics.

## Overview

Ramen Simulator is a management simulation game where players design their ideal ramen recipe, manage a shop, and serve customers with varying tastes and preferences. The game features a 10-axis recipe evaluation system, dynamic customer modeling, and strategic shop management.

## Documentation

Design and specification documents are organized as follows:

- [`docs/ja/`](docs/ja/index.md) — Primary specification documents (Japanese, source of truth)
- [`docs/en/`](docs/en/index.md) — English translations (for reference and AI use)

### Key Documents

| Document | Japanese | English |
|---|---|---|
| Game Proposal | [企画書](docs/ja/proposal.md) | [Proposal](docs/en/proposal.md) |
| Game Structure | [ゲームの構成要素](docs/ja/game_structure.md) | [Game Structure](docs/en/game_structure.md) |
| Recipe Crafting | [レシピクラフト](docs/ja/recipe.md) | [Recipe Crafting](docs/en/recipe.md) |
| Customer System | [顧客システム](docs/ja/customer.md) | [Customer System](docs/en/customer.md) |
| Shop Location | [店舗経営](docs/ja/location.md) | [Shop Management](docs/en/location.md) |
| Menu & Pricing | [メニュー・価格戦略](docs/ja/menu.md) | [Menu & Pricing](docs/en/menu.md) |
| UI & Scenes | [UIと画面遷移](docs/ja/scene.md) | [UI & Scenes](docs/en/scene.md) |
| Roadmap | [将来的な拡張](docs/ja/roadmap.md) | [Roadmap](docs/en/roadmap.md) |

## Project Structure

```
README.md           # This file — human entry point
AGENTS.md           # AI agent entry point
docs/
  ja/               # Primary design documents (Japanese, source of truth)
  en/               # English translations (for AI use)
server/             # Go backend API server (Gin + oapi-codegen)
  data/             # CSV master data (ingredients, customers)
  gen/              # Generated Go code from OpenAPI spec
  handlers/         # API endpoint implementations
phaser-app/         # Phaser.js frontend prototype
scripts/            # Python prototypes for game mechanics
spec/               # Legacy spec directory (see docs/ja/ for current docs)
```

## Development

### Backend (Go)

```bash
make generate      # Generate OpenAPI Go code from spec
make run-server    # Run Go server with CSV data loading
make clean         # Remove generated files
```

### Frontend (Phaser.js)

```bash
cd phaser-app && python -m http.server 3000
# Open http://localhost:3000 in your browser
```

### Documentation

```bash
make docs          # Start docsify documentation server
```

## Issues & Work Tracking

All work items are tracked as [GitHub Issues](https://github.com/ayasuda/rs/issues).
