# Ramen Shop Simulator Design Document

## 1. Title (Tentative)
Ramen Shop Simulator

## 2. Design Goals
Provide players with the fun of crafting their "ideal ramen," while incorporating management elements to deliver a rewarding and strategic gameplay experience.

## 3. Target Users
- Age range: Late teens to adults
- Players with some game experience
- Players who want to play casually on smartphones during spare time

## 4. Genre
Management Simulation + Crafting Elements

## 5. Platform
Smartphone app (iOS / Android)

## 6. Revenue Model
Premium (one-time purchase, no ads or microtransactions)

## 7. Differentiating Points
- Ramen as a subject matter deeply familiar to Japanese people
- Deep recipe crafting system for a single dish
- Personalized taste evaluation system where ratings vary by individual customer

---

# Game Structure and Elements

## Core Elements
- **Creating ramen and its recipes**
- **Shop management (location, equipment, pricing)**
- **Service mini-game (taking orders, serving)**
- **Equipment and recipe improvements**

---

# Recipe Crafting Specifications (Overview)

## Recipe Components
- Noodles
- Soup
- Tare (seasoning sauce)
- Flavored oil
- Ingredients (main and supplementary)
- Presentation (bowl, arrangement)

## Evaluation Axes (10 Axes)
Each recipe is evaluated on the following 10 axes and internally represented as `uint16 (0–65535)`:

1. Umami Intensity
2. Aroma Strength
3. Saltiness
4. Fat Content (richness)
5. Sweetness Presence
6. Spiciness / Stimulation
7. Originality / Creativity
8. Visual Appeal
9. Volume / Portion Size
10. Harmony

## Evaluation Calculation Logic
1. **Each component has contribution values for each evaluation axis**
2. **Sum contribution values from all components to calculate the recipe evaluation vector (R)**
3. **Apply boost correction based on staff cooking skill (e.g., +3% on all axes, +5% on harmony)**
4. **Calculate evaluation score S based on customer preference vector (H) and weight vector (W)**

### Customer Evaluation Formula

`S = Σ [w_i × (65535 - |r_i - h_i|)] (i = 1–10)`
