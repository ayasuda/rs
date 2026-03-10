## 1.1 Customer Category Lifestyle Patterns and Business Hours

### Customer Lifestyle Patterns (by Category)

Each customer category `c` has designated "available visit time slots." These are treated as time-varying inflow rate profiles.

Example:

| Category            | Morning | Noon | Evening | Night | Late Night |
|---------------------|---------|------|---------|-------|------------|
| Office Worker       | △       | ◎    | ◎       | ○     | ×          |
| Student             | ×       | ◎    | ◎       | ○     | △          |
| Part-timer          | ○       | ○    | ○       | ◎     | ◎          |
| Family              | ◎       | ◎    | ○       | △     | ×          |
| Night Shift Worker  | ◎       | ○    | ×       | ×     | ◎          |

This creates strategic depth — for example, "a late-night shop is strong with part-timers and night shift workers but irrelevant to office workers."

---

### Shop Business Hours Settings

- Players can choose their shop's operating hours, and **the length of operating hours affects monthly fixed costs**.
- A fixed cost coefficient is set for each time slot, added together as follows:

| Time Slot       | Fixed Cost Coefficient | Notes                              |
|-----------------|------------------------|------------------------------------|
| Morning session | +1.0                   | Includes early cleaning/prep       |
| Noon session    | +1.2                   | High expected profit during peak   |
| Night session   | +1.5                   | Includes overtime costs            |
| Late-night      | +2.0                   | High utility and night labor costs |

- Fixed Cost = Base Rent × Sum of Time Slot Coefficients

---

### Impact on Inflow Rate (Supplement)

The daily inflow rate `B[c]` is determined by the **overlap between operating hours and customer lifestyle patterns**.

```plaintext
Effective B[c] = B[c] × Time Slot Coverage[c]
```

* Time Slot Coverage[c] = Overlap ratio between customer lifestyle and operating hours (0.0–1.0)
* Example: A shop targeting office workers that operates "late night only" → Coverage = 0.0 → No inflow

### Business Implications

* **"Who do you open for?"** becomes the strategic question
* Locations with broad customer demographics benefit from long hours, but also carry higher fixed cost risk
* For niche customer demographics, limiting hours can optimize profitability

In this way, the three axes of "lifestyle patterns × operating hours × fixed costs" create strategic depth that goes beyond simple location selection.

# Customer Category Specifications (Ramen Shop Simulator)

## Overview

This specification defines the list of customer categories that appear in the game and their basic characteristics. Customer categories have a major impact on player strategy through their visit time preferences, taste tendencies, price sensitivity, and fullness characteristics.

---

## Customer Category List (10 Total)

| # | Category Name       | Primary Visit Times     | Characteristics and Tendencies                                                    |
|---|---------------------|-------------------------|-----------------------------------------------------------------------------------|
| 1 | High School Student | After school – Evening  | Low budget, visits with friends, prioritizes volume                               |
| 2 | College Student     | Noon – Night            | Mid budget, values both taste and quantity, open to creative ramen                |
| 3 | Office Worker       | Weekday noon, evening   | Values speed and consistency, sensitive to fair pricing, likes stimulating/salty flavors |
| 4 | Career Woman        | Weekday noon            | Values appearance and cleanliness, prefers light and low-fat menus                |
| 5 | Socialite (Madam)   | Weekday noon, afternoon | Prefers leisurely dining, highly appreciates plating and interior                 |
| 6 | Part-timer          | Noon – Late night       | Cost-performance focused, responds well to junk food style, flexible hours        |
| 7 | Late-night Driver   | Late night – Morning    | Knowledgeable about good restaurants, sensitive to fat and umami, values service  |
| 8 | Family              | Weekend noon            | Prioritizes volume and cleanliness, frequent side menu orders                     |
| 9 | Senior Citizen      | Morning – Noon          | Prefers low-salt, soft ingredients, highly sensitive to temperature and tableware |
| 10 | Tourist             | Irregular hours         | Responds well to unique ramen, price-insensitive, values photo appeal and experience |

---

## Notes

- Each customer category will be given the following detailed profiles in the future:
  - **Lifestyle rhythm profile** (coefficients for each available visit time slot)
  - **Preference vector (ideal values and weights for the 10 evaluation axes)**
  - **Price sensitivity / budget ceiling tendencies**
  - **Fullness characteristics (fullness tolerance, likelihood of ordering side menus)**
  - "Regulars" are managed separately as a **customer state flag**, not a category.
  - Continuously serving highly-rated ramen will cause customers of any category to become regulars.
