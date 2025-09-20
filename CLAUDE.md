# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ramen Simulator game project with a multi-language architecture:
- **Game Logic Prototype**: Python scripts for ramen recipe evaluation system (`scripts/ramen.py`)
- **Backend Server**: Go-based API server partially implemented with Gin and oapi-codegen, providing mock APIs
- **Frontend**: Phaser.js-based web prototype with dynamic ingredient loading and recipe evaluation
- **Master Data**: CSV-based ingredient and customer data loaded from `server/data/`
- **Documentation**: Comprehensive game design specifications in `spec/` directory

## Common Commands

### Documentation
```bash
make docs              # Start docsify documentation server
```

### Backend Development (Go)
```bash
make generate          # Generate OpenAPI Go code from spec
make run-server        # Run Go server with CSV data loading
make clean            # Remove generated files
```

### Prototype Testing
```bash
python scripts/ramen.py  # Run ramen evaluation prototype
```

### Frontend Development
```bash
# Open phaser-app/index.html in browser
# Or serve with local HTTP server:
cd phaser-app && python -m http.server 3000
```

### Help
```bash
make help             # Show all available make targets
```

## Architecture

### Game Design Documents
The `spec/` directory contains comprehensive game design documentation:
- `proposal.md` - Core game concept and target audience
- `recipe.md` - Recipe crafting system with 10-axis evaluation
- `customer.md` - Customer categories and behavior patterns
- `location.md` - Shop location and visitor traffic calculations
- `menu.md` - Menu pricing and cost calculation system
- `scene.md` - UI screens and navigation flow

### Code Structure
- `scripts/` - Python prototypes demonstrating game mechanics
- `server/` - Go backend API server with Gin and oapi-codegen implementation
  - `server/data/` - CSV master data files (ingredients.csv, customers.csv)
  - `server/gen/` - Generated Go code from OpenAPI spec
  - `server/handlers/` - API endpoint implementations with mock responses
- `phaser-app/` - Phaser.js frontend prototype with dropdown interface
- `bin/` - Build outputs and executables
- `docs/` - Documentation served by docsify

### Key Game Systems
The project implements a complex ramen simulation with:
- **10-axis recipe evaluation**: umami, aroma, saltiness, fat, sweetness, spiciness, originality, visual, volume, harmony
- **Ingredient contribution system**: Each ingredient contributes specific values to evaluation axes
- **Customer behavior modeling**: 10 customer categories with different preferences and visit patterns
- **Shop management**: Location-based traffic, reputation system, pricing strategy

## Development Notes

- The project uses OpenAPI spec (`server/openapi_spec.yaml`) for API code generation
- Python prototypes in `scripts/` demonstrate the core game mechanics before full implementation
- Documentation is served via docsify and can be viewed locally with `make docs`
- The project is bilingual (Japanese/English) with Japanese specifications and English code
- Master data is loaded from CSV files on server startup for ingredients and customer categories
- Frontend fetches dynamic data from backend APIs and provides dropdown-based recipe building

## Current Implementation Status

### Backend APIs (Go + Gin)
- ✅ Recipe evaluation endpoint with 10-axis scoring
- ✅ Customer category management with mock satisfaction calculation
- ✅ Pricing calculation with cost breakdown
- ✅ Master data endpoints for ingredients and customers
- ✅ CSV data loading on startup (28 ingredients, 10 customer categories)

### Frontend (Phaser.js)
- ✅ Dynamic ingredient loading from backend API
- ✅ Dropdown-based recipe selection interface
- ✅ Multiple toppings selection (up to 3)
- ✅ Recipe evaluation with enhanced results display
- ✅ Table format showing scores, percentages, and quality ratings

## Commit Message Guidelines

When committing changes, use only the standard work summary that Claude Code provides at the end of each task. Do not include extra details, explanations, or formatting beyond the concise summary of what was accomplished.