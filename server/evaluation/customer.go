package evaluation

import (
	"math"

	"github.com/ayasuda/rs/server/model"
)

// EvaluateCustomerSatisfaction evaluates how satisfied a customer would be with a recipe
func EvaluateCustomerSatisfaction(recipeEval model.RecipeEvaluation, customer model.CustomerCategory, price int, reputationBonus float64) model.CustomerSatisfaction {
	// Use adjusted scores if available, otherwise use base scores
	scores := recipeEval.Scores
	if recipeEval.AdjustedScores != nil {
		scores = *recipeEval.AdjustedScores
	}

	// Calculate taste match score (0-100)
	tasteMatch := calculateTasteMatch(scores, customer.PreferenceVector, customer.WeightVector)

	// Calculate effective budget with reputation bonus
	effectiveBudget := int(float64(customer.BaseBudget) * (1.0 + reputationBonus))
	priceAcceptable := price <= effectiveBudget

	// Calculate price-value score (0-100)
	priceValue := calculatePriceValue(price, effectiveBudget, priceAcceptable)

	// Combine taste match and price-value into overall satisfaction
	// Weight: 70% taste match, 30% price value
	satisfactionScore := (tasteMatch * 0.7) + (priceValue * 0.3)

	// Determine if customer will return (threshold: 50)
	willReturn := satisfactionScore > 50.0

	return model.CustomerSatisfaction{
		SatisfactionScore: satisfactionScore,
		WillReturn:        willReturn,
		PriceAcceptable:   priceAcceptable,
		EffectiveBudget:   effectiveBudget,
		DetailedScores: struct {
			TasteMatch float32 `json:"tasteMatch"`
			PriceValue float32 `json:"priceValue"`
		}{
			TasteMatch: tasteMatch,
			PriceValue: priceValue,
		},
	}
}

// calculateTasteMatch computes how well the recipe scores match customer preferences
func calculateTasteMatch(recipeScores model.EvaluationScores, preferences model.EvaluationScores, weights model.PreferenceWeights) float32 {
	// Calculate weighted preference matching for each axis
	var totalScore float64
	var totalWeight float64

	// For each evaluation axis, calculate how well the recipe matches preferences
	axisScores := []struct {
		recipe, preference float64
		weight             float32
	}{
		{float64(recipeScores.Umami), float64(preferences.Umami), weights.Umami},
		{float64(recipeScores.Aroma), float64(preferences.Aroma), weights.Aroma},
		{float64(recipeScores.Saltiness), float64(preferences.Saltiness), weights.Saltiness},
		{float64(recipeScores.Fat), float64(preferences.Fat), weights.Fat},
		{float64(recipeScores.Sweetness), float64(preferences.Sweetness), weights.Sweetness},
		{float64(recipeScores.Spiciness), float64(preferences.Spiciness), weights.Spiciness},
		{float64(recipeScores.Originality), float64(preferences.Originality), weights.Originality},
		{float64(recipeScores.Visual), float64(preferences.Visual), weights.Visual},
		{float64(recipeScores.Volume), float64(preferences.Volume), weights.Volume},
		{float64(recipeScores.Harmony), float64(preferences.Harmony), weights.Harmony},
	}

	for _, axis := range axisScores {
		if axis.preference > 0 {
			// Calculate match score: closer to preference = higher score
			// Use a gaussian-like function centered on the preference value
			difference := math.Abs(axis.recipe - axis.preference)
			maxDifference := axis.preference * 0.5 // Allow 50% deviation for reasonable score

			// Convert difference to a 0-100 score (closer = higher score)
			var axisScore float64
			if difference <= maxDifference {
				// Good match: score between 50-100
				axisScore = 100.0 - (difference/maxDifference)*50.0
			} else {
				// Poor match: score between 0-50
				remainingDiff := difference - maxDifference
				maxRemainingDiff := axis.preference * 1.5 // Total tolerance range
				if remainingDiff >= maxRemainingDiff {
					axisScore = 0.0
				} else {
					axisScore = 50.0 * (1.0 - (remainingDiff/maxRemainingDiff))
				}
			}

			totalScore += axisScore * float64(axis.weight)
			totalWeight += float64(axis.weight)
		}
	}

	if totalWeight == 0 {
		return 50.0 // Default neutral score
	}

	return float32(totalScore / totalWeight)
}

// calculatePriceValue computes price-value satisfaction (0-100)
func calculatePriceValue(price int, effectiveBudget int, priceAcceptable bool) float32 {
	if !priceAcceptable {
		// Price exceeds budget - very low score based on how much it exceeds
		overageRatio := float64(price-effectiveBudget) / float64(effectiveBudget)
		if overageRatio >= 1.0 {
			return 0.0 // Price is 2x budget or more
		}
		return float32(20.0 * (1.0 - overageRatio)) // Score 0-20 based on overage
	}

	// Price is within budget - score based on value perception
	if price == 0 {
		return 100.0 // Free is always good value
	}

	// Calculate value score: lower price relative to budget = higher value
	priceRatio := float64(price) / float64(effectiveBudget)

	if priceRatio <= 0.5 {
		// Excellent value (price <= 50% of budget)
		return 100.0
	} else if priceRatio <= 0.7 {
		// Good value (price 50-70% of budget)
		return float32(100.0 - (priceRatio-0.5)/0.2*20.0) // Score 80-100
	} else if priceRatio <= 0.9 {
		// Fair value (price 70-90% of budget)
		return float32(80.0 - (priceRatio-0.7)/0.2*20.0) // Score 60-80
	} else {
		// Poor value (price 90-100% of budget)
		return float32(60.0 - (priceRatio-0.9)/0.1*20.0) // Score 40-60
	}
}