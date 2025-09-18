# Ramen Simulator - Frontend Prototype

A minimal Phaser.js frontend for the Ramen Simulator game.

## Features

- **Recipe Builder**: Select ingredients for your ramen recipe:
  - 麺 (Noodles): 4 types (太麺, 細麺, 中太麺, 平打ち麺)
  - スープ (Soup): 4 types (鶏白湯, 豚骨, 味噌, 魚介系)
  - かえし (Sauce): 4 types (醤油だれ, 味噌だれ, 塩だれ, 豚骨だれ)
  - 香味油 (Oil): 4 types (黒マー油, ネギ油, ラー油, ごま油)
  - 具材 (Toppings): Up to 3 from 6 options (チャーシュー, 味玉, メンマ, 海苔, コーン, バター)
  - 盛り付け (Presentation): 4 bowl types (黒どんぶり, 白どんぶり, 木製どんぶり, 陶器どんぶり)

- **Cooking Skill**: Adjustable skill level (1-10) affecting recipe evaluation

- **API Integration**: Sends recipe to backend for evaluation via POST request

- **Results Display**: Shows 10-axis evaluation scores and total cost

## Usage

1. **Start the Backend Server**:
   ```bash
   cd server
   make run-server
   ```
   The server should be running on `http://localhost:8080`

2. **Open the Frontend**:
   - Open `index.html` in a web browser
   - Or serve it with a local HTTP server:
     ```bash
     cd phaser-app
     python -m http.server 3000
     # Then open http://localhost:3000
     ```

3. **Create a Recipe**:
   - Select ingredients from each category by clicking the buttons
   - Adjust cooking skill level (1-10)
   - Click "Evaluate Recipe" to send to backend

4. **View Results**:
   - The 10-axis evaluation scores will be displayed
   - Shows both raw scores (0-65535) and percentages
   - Displays total recipe cost

## Technical Details

- **Framework**: Phaser.js 3.70.0 (loaded from CDN)
- **Language**: Plain JavaScript (no TypeScript)
- **API Endpoint**: `POST http://localhost:8080/recipes/evaluate`
- **Minimal Dependencies**: Only Phaser.js, no additional libraries

## File Structure

```
phaser-app/
├── index.html          # Main HTML file with Phaser.js CDN
├── game.js            # Game logic and UI implementation
└── README.md          # This file
```

The prototype uses functional placeholders without styling or assets, focusing on the core recipe evaluation workflow.