# 3. Menu and Pricing Strategy Specifications

## Overview

In this game, realistic management elements such as procurement and inventory management are omitted. Instead, strategic profit control is realized through "cost per bowl," "free pricing," and "customer purchasing behavior (budget, fullness)."

---

## 1. Basic Cost and Pricing Specifications

### Cost (In-game Definition)

- Ingredient procurement management is not performed, but **"cost" is automatically calculated based on the ramen recipe content**.
- Cost is internally calculated from the following elements (all automatic):
  - Noodle type / soup type / number of ingredients / number of special toppings / presentation style, etc.
  - Cost is presented to the player as information only and cannot be directly manipulated.

### Pricing

- Players can **freely set selling prices** for ramen, side menus, and toppings.
- The set price affects customer evaluation and satisfaction.

---

## 2. Customer Budget and Purchasing Behavior

### Payment Budget

Customers have a "base budget per category," and their **payment ceiling fluctuates based on reputation score**.

```plaintext
Payment Ceiling[c] = Base Budget[c] × (1 + Reputation Correction[c])
```

Example:

College Student (base budget 800 yen) × Reputation correction +0.25 → Payment ceiling = 1,000 yen

Ramen or additional menus priced above this payment ceiling will see a significant drop in purchase probability.

### Side Menus and Fullness

Customers have a **"fullness gauge" (0.0–1.0)**.

The ramen's "volume" occupies the fullness gauge, with the remaining space used to choose side menus.

```plaintext
Fullness Consumed = Ramen Volume + Side Menu Volume
```

* Customers will only make purchase decisions within the range where fullness ≤ 1.0.
* Therefore, if you serve high-volume ramen, side menus become harder to sell.

## 3. Player Strategy Options

* Ramen pricing strategy (balance between quantity and price)
* Side menu lineup strategy (small snack options vs. high-unit-price low-volume items)
* Topping option strategy (flavor emphasis / differentiation)

As reputation improves, budgets increase, enabling strategies such as:

* "High volume + low price to maximize customer count"
* "High price + high satisfaction to maximize profit"

depending on the player's preferred style.
