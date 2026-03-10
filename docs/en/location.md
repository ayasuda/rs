# Location and Property Specifications (Customer Count Logic and Reputation Linkage)

## Overview

This specification defines the core functionality of the "location and property" element — specifically the formula logic that influences customer count. It focuses on the impact that category-specific base inflow rates and reputation scores have on customer numbers, designed so that location selection directly connects to game strategy.

---

## 1. Relationship Between Location and Customer Count

Each rental property has the following parameters configured:

- **Potential customer count** by customer category
- **Base inflow rate** by customer category
- **Seating capacity** (directly tied to maximum daily customer count)

Customer count is calculated by the following formula:

```plaintext
Customer Count[c] = min(Potential Customers[c] × Effective Inflow Rate[c], Capacity)
```

## 2. Composition of Effective Inflow Rate

The inflow rate is calculated by multiplying the base value with multiple correction factors:

```
Effective Inflow Rate[c] = B[c] × (1 + R[c]) × (1 + W) × (1 + M) × (1 + D) × (1 + A)
```

| Symbol | Correction Factor         | Unit                        | Description                                                                           |
|--------|---------------------------|-----------------------------|---------------------------------------------------------------------------------------|
| `B[c]` | Base inflow rate          | Per category                | Initial value dependent on shop location and foot traffic                             |
| `R[c]` | Reputation correction     | Per category                | Customer correction based on reputation score (base 50; ±50 yields max ±0.5 correction) |
| `W`    | Weather correction        | Common                      | Correction for weather conditions such as rain or snow (e.g., -0.3)                  |
| `M`    | Advertising effect        | Common or per category      | Temporary boost from flyers, SNS, TV, etc. (e.g., +0.2)                              |
| `D`    | Day/Event correction      | Common                      | Impact from day of week, holidays, or event days (e.g., +0.1)                        |
| `A`    | Interior/exterior correction | Common or per category   | Ongoing appeal correction from cleanliness and exterior presentation (e.g., +0.1)    |


## 3. Reputation Correction R[c] Formula

When the ramen served by the player matches a customer's preferences, the **category-specific reputation score [R[c]]** increases.

The reputation score has a base value of 50, and the formula is:

```plaintext
R[c] = (Reputation Score[c] - 50) ÷ 100
```

* As the reputation score rises, the inflow rate increases and customer count grows
* However, since customers cannot exceed the shop's "seating capacity," there is a capacity ceiling on reputation gains

## 4. Causal Relationship: Evaluation → Reputation → Customer Count

```plaintext
Serving High-Quality Ramen
  ↓
Category-Specific Customer Satisfaction Increases
    ↓
Reputation Score[c] Increases
      ↓
Inflow Rate[c] Increases
        ↓
Customer Count[c] Increases
```


This structure is designed so players can control customer count through "strategic ramen creation targeting specific demographics" and "reinforcement through interior design and advertising."
