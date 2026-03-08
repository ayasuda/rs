# Overall Game Structure: Ramen Shop Simulator

This document organizes the system composition, play flow, and relationships between elements in "Ramen Shop Simulator." It serves as the base reference for development, implementation, and specification expansion.

---

## 1. Overall Play Flow (Basic Cycle)

```text
1. Shop Selection (Location / Property) →
2. Recipe Creation (Crafting) →
3. Opening / Operations (Business hours, customer visits) →
4. Cooking / Serving (Mini-game or automatic) →
5. Evaluation (Per-customer preference vectors) →
6. Sales Calculation (Price × customer count) →
7. Improvement (Recipe / interior / pricing, etc.)
   ↓
(Repeat daily from this point forward)
```

## 2. Main System Components

| System Name              | Overview / Role                                                                                          |
|--------------------------|----------------------------------------------------------------------------------------------------------|
| Recipe Crafting          | Combine noodles, soup, etc. to generate a 10-axis evaluation vector                                     |
| Customer Evaluation      | Match against each customer's preference vector to determine satisfaction and repeat visits              |
| Shop Operations          | Location, business hours, interior, fixed costs, financial management. Allows strategic choices per shop |
| Customer Inflow Logic    | Calculate category-by-category inflow adjusted for reputation, weather, time of day, etc.               |
| Menu Settings            | Control profit margins through automatic cost calculation plus price setting                             |
| Service Mini-game        | Action element where players tap/swipe to take orders and serve (reward varies by accuracy)             |
| Evaluation → Reputation  | Serving highly-rated ramen increases category-specific reputation scores, leading to higher inflow rates |
| Customer Profiles        | 10 categories with visit time slots, preferences, fullness level, and price sensitivity                 |


## 3. Daily Progression and Business Loop Structure

Operations, evaluation, and profit calculation are performed on a daily basis, with improvements inserted at arbitrary timing.

```
[Business Start]
 ↓
Customer Visits (by time slot)
 ↓
Orders / Cooking (Mini-game or automatic)
 ↓
Evaluation (per customer)
 ↓
Aggregation (reputation, sales, visit history)
 ↓
[Business End]
 ↓
Reward / Improvement Phase (new recipes / price changes / business hours adjustments, etc.)
```

## 4. Component Relationship Diagram (Simplified)

```
[Recipe] ─→ [Evaluation Vector] ─→ [Customer Satisfaction] ─→ [Reputation Score]
    ↓                                         ↓
[Cost Calculation]                  [Pricing Strategy] ─→ [Sales]
                                              ↓
                    [Fullness / Budget Constraints] ──→ [Side Menu Sales]
```

## 5. Supplement: Key Iteration Axes in the Game

| Axis               | Content                                                                              |
|--------------------|--------------------------------------------------------------------------------------|
| Evaluation Axis    | Improving customer satisfaction (taste match) → Reputation UP → Customer count UP   |
| Management Axis    | Improving revenue through business hours / location / pricing                        |
| Improvement Axis   | Adjusting recipes, interior, and service based on evaluation results and visitor analysis |
| Customer Strategy  | Gaining regulars and increasing sales by adapting to each category (time / preferences) |

## Planned Future Features (Not Yet Implemented)

* Story developments through repeat customers becoming regulars
* Ranking elements (tentative)
* Shop branching / multi-location management (future expansion)
