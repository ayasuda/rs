package evaluation

import (
	"github.com/ayasuda/rs/server/model"
)

// EvaluateRecipe evaluates a recipe using actual ingredient contribution data
func EvaluateRecipe(recipe model.Recipe, ingredients []model.Ingredient) model.RecipeEvaluation {
	// Find ingredient data by ID for accurate contributions
	ingredientMap := make(map[string]model.Ingredient)
	for _, ingredient := range ingredients {
		ingredientMap[ingredient.ID] = ingredient
	}

	// Calculate base scores by summing ingredient contributions
	baseScores := model.EvaluationScores{}
	totalCost := 0

	// Add contributions from main components
	if noodles, exists := ingredientMap[recipe.Noodles.ID]; exists {
		addContributions(&baseScores, noodles.Contributions)
		totalCost += getIngredientCost(noodles.Category)
	}

	if soup, exists := ingredientMap[recipe.Soup.ID]; exists {
		addContributions(&baseScores, soup.Contributions)
		totalCost += getIngredientCost(soup.Category)
	}

	if sauce, exists := ingredientMap[recipe.Sauce.ID]; exists {
		addContributions(&baseScores, sauce.Contributions)
		totalCost += getIngredientCost(sauce.Category)
	}

	if oil, exists := ingredientMap[recipe.Oil.ID]; exists {
		addContributions(&baseScores, oil.Contributions)
		totalCost += getIngredientCost(oil.Category)
	}

	if presentation, exists := ingredientMap[recipe.Presentation.ID]; exists {
		addContributions(&baseScores, presentation.Contributions)
		totalCost += getIngredientCost(presentation.Category)
	}

	// Add contributions from toppings
	for _, topping := range recipe.Toppings {
		if toppingData, exists := ingredientMap[topping.ID]; exists {
			addContributions(&baseScores, toppingData.Contributions)
			totalCost += getIngredientCost(toppingData.Category)
		}
	}

	// Apply cooking skill level adjustments
	var adjustedScores *model.EvaluationScores
	if recipe.CookingSkillLevel != nil {
		adjusted := applyCookingSkillAdjustment(baseScores, *recipe.CookingSkillLevel)
		adjustedScores = &adjusted
	}

	return model.RecipeEvaluation{
		Scores:         baseScores,
		TotalCost:      totalCost,
		AdjustedScores: adjustedScores,
	}
}

// addContributions adds ingredient contributions to the base scores
func addContributions(baseScores *model.EvaluationScores, contributions model.EvaluationScores) {
	baseScores.Umami += contributions.Umami
	baseScores.Aroma += contributions.Aroma
	baseScores.Saltiness += contributions.Saltiness
	baseScores.Fat += contributions.Fat
	baseScores.Sweetness += contributions.Sweetness
	baseScores.Spiciness += contributions.Spiciness
	baseScores.Originality += contributions.Originality
	baseScores.Visual += contributions.Visual
	baseScores.Volume += contributions.Volume
	baseScores.Harmony += contributions.Harmony
}

// applyCookingSkillAdjustment applies cooking skill bonus to scores
func applyCookingSkillAdjustment(baseScores model.EvaluationScores, skillLevel float32) model.EvaluationScores {
	// Apply 3% bonus per skill level for most attributes
	skillBonus := 1.0 + (float64(skillLevel)/100.0)*3.0
	// Apply 8% bonus per skill level for harmony (as mentioned in existing code)
	harmonyBonus := 1.0 + (float64(skillLevel)/100.0)*8.0

	return model.EvaluationScores{
		Umami:       int(float64(baseScores.Umami) * skillBonus),
		Aroma:       int(float64(baseScores.Aroma) * skillBonus),
		Saltiness:   int(float64(baseScores.Saltiness) * skillBonus),
		Fat:         int(float64(baseScores.Fat) * skillBonus),
		Sweetness:   int(float64(baseScores.Sweetness) * skillBonus),
		Spiciness:   int(float64(baseScores.Spiciness) * skillBonus),
		Originality: int(float64(baseScores.Originality) * skillBonus),
		Visual:      int(float64(baseScores.Visual) * skillBonus),
		Volume:      int(float64(baseScores.Volume) * skillBonus),
		Harmony:     int(float64(baseScores.Harmony) * harmonyBonus),
	}
}

// getIngredientCost returns the cost for an ingredient category
func getIngredientCost(category string) int {
	switch category {
	case "noodles":
		return 80
	case "soup":
		return 120
	case "sauce":
		return 60
	case "oil":
		return 40
	case "topping":
		return 80
	case "presentation":
		return 40
	default:
		return 50
	}
}