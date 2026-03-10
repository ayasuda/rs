# Ramen Simulator - Frontend Prototype

A Phaser.js frontend for the Ramen Simulator game with dynamic ingredient loading and improved UI.

## Features

- **Dynamic Ingredient Loading**: Fetches ingredients from backend API (`GET /master/ingredients`)
- **Dropdown Interface**: Clean dropdown selection for each recipe component:
  - 麺 (Noodles): Dynamically loaded from server
  - スープ (Soup): Dynamically loaded from server  
  - かえし (Sauce): Dynamically loaded from server
  - 香味油 (Oil): Dynamically loaded from server
  - 具材 (Toppings): Multiple selection (up to 3) from server data
  - 盛り付け (Presentation): Dynamically loaded from server

- **Cooking Skill**: Adjustable skill level (1-10) affecting recipe evaluation

- **API Integration**: Full integration with backend APIs
  - Fetches ingredient master data on startup
  - Sends complete recipe for evaluation via POST request

- **Enhanced Results Display**: Table format showing:
  - 10-axis evaluation scores with raw values and percentages
  - Quality ratings (Excellent, Very Good, Good, Average, Poor, Very Poor)
  - Color-coded ratings and total cost display

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