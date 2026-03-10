# Development Phase Structure and Task List: Ramen Shop Simulator

This document organizes the tasks for each development phase of "Ramen Shop Simulator." Based on an iterative development methodology, progress is divided into 4 iterations from planning to release.

---

## Planning and Design Phase (Week 1)

| Task                                  | Description                                                                              |
|---------------------------------------|------------------------------------------------------------------------------------------|
| Finalize game specifications          | Integrate all spec files and create a confirmed version                                  |
| UI design (screen list / transition diagram) | List major screens and create screen transition maps (using PlantUML, etc.)         |
| Define recipe evaluation DSL          | Specify type design and computation processing for recipe components → evaluation vector |
| Determine MVP scope                   | Extract minimum playable specifications and clarify implementation priorities            |

---

## 1st Iteration: Recipe Crafting & Customer Evaluation (Weeks 2–3)

| Task                                       | Description                                                                           |
|--------------------------------------------|---------------------------------------------------------------------------------------|
| Implement recipe building UI               | Interface for combining noodles, soup, ingredients, etc.                              |
| Implement evaluation vector computation    | Aggregate 10-axis numerical values from each component to calculate uint16 evaluations |
| Match with customer preference vectors     | Calculate satisfaction by matching against customer weights and ideal values          |
| Display evaluations via text and expressions | Show feedback comments and visuals based on satisfaction level                      |

---

## 2nd Iteration: Shop Management and Time Management (Weeks 4–5)

| Task                                     | Description                                                                                  |
|------------------------------------------|----------------------------------------------------------------------------------------------|
| Business hours settings and fixed cost model | Design costs per time slot and calculate revenue balance                               |
| Customer inflow logic                    | Calculate inflow count based on time slot × category × reputation                           |
| Implement reputation → inflow → customer count | Build causal chain model: satisfaction → reputation score → inflow rate              |
| Calculate sales and profit               | Profit analysis based on automatic cost calculation and pricing                              |
| Daily progression and business cycle display | Progress the 1-day unit flow and visualize results                                     |

---

## 3rd Iteration: Mini-game and UX Presentation (Weeks 6–7)

| Task                                  | Description                                                                               |
|---------------------------------------|-------------------------------------------------------------------------------------------|
| Implement service mini-game           | Tempo-based action: order taking → cooking → serving                                      |
| Presentations based on satisfaction   | Express reactions through expressions, comments, and visit effects                        |
| Side menu and fullness calculations   | Determine fullness occupation from ramen and assess side order possibilities              |
| Reflect shop interior and exterior    | Visualize inflow correction (A value) through cleanliness and interior design             |

---

## 4th Iteration: Multi-platform Support and QA (Weeks 8–9)

| Task                                       | Description                                                                                          |
|--------------------------------------------|------------------------------------------------------------------------------------------------------|
| Final Web UI adjustments                   | Optimize for smartphone display and confirm responsive design                                        |
| iOS/Android port (Capacitor, etc.)         | Configure WebView wrapping and native support settings                                               |
| Add save / load functionality              | Save and restore gameplay progress data                                                              |
| Bug fixes and balance adjustments          | Identify issues through QA playtesting and adjust parameters                                         |
| Prepare store submission materials         | Organize icons, descriptions, screenshots, and other materials required for each app store submission |

---

(Last updated: July 2025)
