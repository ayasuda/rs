# Recipe Crafting Specifications

In this game, "creating a ramen recipe" is a crafting element where players combine components to assemble their "ideal bowl." The final result is internally represented as numerical values across 10 evaluation axes, producing ratings for each customer.

## Recipe Components

* Noodles
* Soup
* Tare (seasoning sauce)
* Flavored oil
* Ingredients (main and supplementary)
* Presentation (bowl and arrangement)

## Evaluation Axis List

Each recipe is internally represented by numerical values (uint16, 0–65535) for each of the following 10 evaluation axes.

| Evaluation Axis   | Content (Characteristic of the Ramen)                                           | Numerical Range (uint16)              |
|-------------------|----------------------------------------------------------------------------------|---------------------------------------|
| Umami             | Depth and richness of flavor base from dashi, tare, and umami ingredients        | 0 = No taste / 65535 = Intense umami |
| Aroma             | Impression on the nose from flavored oil, aromatic ingredients, and cooking method | 0 = No scent / 65535 = Strong aroma |
| Saltiness         | Amount of saltiness from tare and soup                                           | 0 = Very mild / 65535 = Very salty   |
| Fat Content       | Total amount from emulsified soup, flavored oil, and fatty ingredients           | 0 = Light / 65535 = Back-fat style   |
| Sweetness         | Sweetness derived from tare and ingredients (mirin, onion, flavored egg, etc.)   | 0 = No sweetness / 65535 = Sweet     |
| Spiciness         | Stimulation from spices, chili peppers, garlic, etc.                             | 0 = Mild / 65535 = Intense           |
| Creativity        | Rarity of combinations / impact / topicality                                     | 0 = Classic / 65535 = Eccentric      |
| Visual Appeal     | Color / ingredient arrangement / bowl / coherence and impression of presentation  | 0 = Messy / 65535 = Instagram-worthy |
| Volume            | Noodle quantity, ingredient quantity, thickness, and sense of satisfaction        | 0 = For small eaters / 65535 = Large serving |


## Evaluation Score Calculation Logic

In this game, the "taste evaluation" of a bowl of ramen is internally calculated as a 10-axis numerical evaluation through the following steps. These evaluations are not displayed directly as numbers to the player; they are communicated indirectly through text-based impressions of flavor and customer reactions.

### Step 1: Defining Evaluation Contribution Values per Component

Each recipe component (e.g., soup, flavored oil, ingredients) has individual "contribution values" calculated for the 10 evaluation axes at the time of creation. For example, if a player crafts "Black Mayu Oil" as a flavored oil, the contribution level to axes such as "aroma strength" and "fat content" is immediately determined based on the ingredients and cooking method.

These contribution values are internally computed based on parameters defined in the game for each ingredient and process. Even components with the same name may have different contribution values if they are prepared differently.
For example, "Black Mayu Oil" is configured to strongly influence "aroma strength" and "fat content."

### Step 2: Aggregating the Recipe's Total Score

For all components selected by the player, the contribution values to the corresponding evaluation axes are added together. This produces a 10-axis overall evaluation for the complete bowl of ramen. Values for each axis are clipped to the uint16 range of 0–65535.

### Step 3: Special Axis Correction Calculations

Some evaluation axes involve mutual corrections rather than simple addition.

* "Harmony": Calculated based on deviation and correlation across all axes, and the degree to which each axis is balanced (lower variance = higher score)
* "Creativity / Originality": Scored based on the use of rare ingredients, unconventional combinations, and eccentric presentation (greater distance from conventional = higher score)

Furthermore, corrections are applied to the overall evaluation based on the skill and experience level of the staff member in charge of cooking. Specifically, based on the staff member's "cooking skill" parameter:

* A small boost is added to scores on each evaluation axis
* Variance in harmony is reduced
* "Creativity overload" is suppressed (compositions that are too eccentric and fall apart are moderated)

These effects mean that even the same recipe will yield different evaluation results depending on who cooks it.

### Step 4: Customer Preference Matching

Each customer has a "preference vector (H)" across 10 axes, and also holds a "weight vector (W)" for each axis. These weights indicate which evaluation axes the customer prioritizes, adjusting the degree of impact that deviations between the preference vector and the completed ramen's evaluation vector (R) have on the score.

The satisfaction score (S) is calculated as follows:

`S = Σ [w_i × (65535 - |r_i - h_i|)] (i = 1–10)`

This mechanism creates a realistic preference evaluation where the same ramen receives different ratings depending on each customer's values — for example, a customer who prioritizes appearance vs. one who loves fatty flavors.

Each customer has a "preference vector (H)" across 10 axes. The deviation (difference) between the ramen's evaluation value and the customer's preference vector is calculated and reflected as the final "satisfaction level" and "repeat visit rate." All component arguments are summed to determine the final value for each axis.

* Axis range: 0–65535
* Harmony is determined by the smallness of inter-axis deviation and degree of compatibility
* Creativity is evaluated based on the unnaturalness derived from the realism and simplicity of ingredients used

## Evaluation Score Calculation Example

Below is an example showing how ramen and customer preferences are matched in practice based on the evaluation logic.

### Ramen Example

* Name: Rich Chicken Paitan with Black Flavored Oil
* Components:
  * High-hydration thick noodles
  * Chicken paitan soup
  * Dark soy sauce tare
  * Black mayu oil (flavored oil)
  * Ingredients: Seared chashu pork, flavored egg, green onion
  * Presentation: Black bowl, radial arrangement

### Customer Category Example

* Category: Male College Student
* Preference Tendencies:
  * Fat Content: Prioritized (w = high)
  * Volume: Prioritized (w = high)
  * Spiciness: Somewhat prioritized
  * Visual Appeal: Low priority (w = low)
  * Harmony: Low priority

In this composition, if the recipe strongly contributes to fat, volume, and spiciness, the matching with the evaluation axes will yield a high satisfaction score. Conversely, a customer who prioritizes presentation may give this ramen a low rating.

### Ramen Evaluation Score Calculation (Recipe)

The following table summarizes the contribution values each component provides to the 10 evaluation axes.

| Component                    | Umami | Aroma | Saltiness | Fat   | Sweetness | Spiciness | Creativity | Visual | Volume | Harmony |
|------------------------------|-------|-------|-----------|-------|-----------|-----------|------------|--------|--------|---------|
| High-hydration thick noodles | 6000  |       |           | 3000  |           |           |            |        | 7000   | 5000    |
| Chicken paitan soup          | 15000 | 5000  | 7000      | 12000 |           |           |            |        |        | 6000    |
| Dark soy sauce tare          | 6000  |       | 10000     |       | 4000      | 2000      |            |        |        | 4000    |
| Black mayu oil               |       | 10000 |           | 8000  |           |           | 6000       |        |        | 3000    |
| Seared chashu pork           | 5000  |       |           | 9000  |           |           |            | 3000   | 5000   | 4000    |
| Flavored egg                 | 3000  |       |           |       | 4000      |           |            | 2500   |        |         |
| Green onion                  |       | 2000  |           |       |           | 1500      |            | 2000   |        |         |
| Presentation                 |       |       |           |       |           |           | 3000       | 5000   |        | 5000    |

### Ramen Evaluation Score Calculation (After Cooking Corrections)

The following shows the overall evaluation values for the ramen after receiving corrections from the staff member's "cooking skill." Cooking skill applies a +3% boost correction to each evaluation axis, with an additional stabilization correction (+5%) applied to harmony.

| Evaluation Axis        | Total (Before Correction) | Correction Factor | Total (After Correction) |
|------------------------|---------------------------|-------------------|--------------------------|
| Umami Intensity        | 35000                     | ×1.03             | 36050                    |
| Aroma Strength         | 17000                     | ×1.03             | 17510                    |
| Saltiness              | 17000                     | ×1.03             | 17510                    |
| Fat Content (Richness) | 32000                     | ×1.03             | 32960                    |
| Sweetness Presence     | 8000                      | ×1.03             | 8240                     |
| Spiciness              | 3500                      | ×1.03             | 3605                     |
| Originality/Creativity | 9000                      | ×1.03             | 9270                     |
| Visual Appeal          | 12500                     | ×1.03             | 12875                    |
| Volume                 | 12000                     | ×1.03             | 12360                    |
| Harmony                | 27000                     | ×1.08             | 29160                    |

With this correction, even the same recipe will yield an overall improvement in taste evaluation when cooked by a higher-skilled staff member, improving customer satisfaction.

* Deviation per evaluation axis = |Ramen evaluation value − Customer ideal value|, then multiplied by weight and summed as a weighted deviation total.
* Evaluation score = 100 − (Weighted deviation total / Normalization constant) *Normalization constant determined by game balance (e.g., 100,000)*
* Calculation example (outline):
  * Umami deviation: |36050 − 40000| × 1.0 = 3950
  * Fat content deviation: |32960 − 35000| × 1.2 = 2448
  * Volume deviation: |12360 − 14000| × 1.0 = 1640
  * ...calculated similarly for remaining axes, total: approximately 12,000

→ Evaluation score ≒ 100 − (12000 / 100000) = 88.0

In this way, the preferences and weights of individual customer categories influence the evaluation, and the design rewards players whose strategies align with the target customer demographic.
