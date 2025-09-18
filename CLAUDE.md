# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ramen Simulator game project with a multi-language architecture:
- **Game Logic Prototype**: Python scripts for ramen recipe evaluation system (`scripts/ramen.py`)
- **Backend Server**: Go-based API server (planned, currently empty `server/` directory)
- **Frontend**: Unity-based game client (planned)
- **Documentation**: Comprehensive game design specifications in `spec/` directory

## Common Commands

### Documentation
```bash
make docs              # Start docsify documentation server
```

### Backend Development (Go)
```bash
make generate          # Generate OpenAPI Go code from spec
make run-server        # Run Go server (when implemented)
make clean            # Remove generated files
```

### Prototype Testing
```bash
python scripts/ramen.py  # Run ramen evaluation prototype
```

### Unity Development
```bash
make unity-build       # Unity CLI build (placeholder - not yet implemented)
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
- `server/` - Go backend API server (OpenAPI-based, not yet implemented)
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