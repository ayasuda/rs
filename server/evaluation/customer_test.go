package evaluation

import (
	"testing"

	"github.com/ayasuda/rs/server/model"
)

// Test data - sample customers and recipe evaluations for testing
func getTestCustomers() []model.CustomerCategory {
	return []model.CustomerCategory{
		{
			ID:         1,
			Name:       "高校生",
			BaseBudget: 800,
			PreferenceVector: model.EvaluationScores{
				Umami: 30000, Aroma: 25000, Saltiness: 35000, Fat: 20000,
				Sweetness: 15000, Spiciness: 40000, Originality: 25000, Visual: 15000,
				Volume: 50000, Harmony: 20000,
			},
			WeightVector: model.PreferenceWeights{
				Umami: 1.0, Aroma: 0.8, Saltiness: 1.2, Fat: 0.6,
				Sweetness: 0.5, Spiciness: 1.5, Originality: 1.0, Visual: 0.3,
				Volume: 2.0, Harmony: 0.4,
			},
		},
		{
			ID:         2,
			Name:       "大学生",
			BaseBudget: 1200,
			PreferenceVector: model.EvaluationScores{
				Umami: 35000, Aroma: 30000, Saltiness: 30000, Fat: 35000,
				Sweetness: 20000, Spiciness: 35000, Originality: 40000, Visual: 25000,
				Volume: 45000, Harmony: 25000,
			},
			WeightVector: model.PreferenceWeights{
				Umami: 1.2, Aroma: 1.0, Saltiness: 1.0, Fat: 1.5,
				Sweetness: 0.8, Spiciness: 1.3, Originality: 1.5, Visual: 1.0,
				Volume: 1.8, Harmony: 0.6,
			},
		},
		{
			ID:         3,
			Name:       "キャリアウーマン",
			BaseBudget: 1800,
			PreferenceVector: model.EvaluationScores{
				Umami: 25000, Aroma: 40000, Saltiness: 20000, Fat: 15000,
				Sweetness: 25000, Spiciness: 10000, Originality: 35000, Visual: 50000,
				Volume: 20000, Harmony: 40000,
			},
			WeightVector: model.PreferenceWeights{
				Umami: 1.0, Aroma: 1.6, Saltiness: 0.7, Fat: 0.4,
				Sweetness: 1.0, Spiciness: 0.3, Originality: 1.4, Visual: 2.0,
				Volume: 0.6, Harmony: 1.8,
			},
		},
	}
}

func getTestRecipeEvaluations() []model.RecipeEvaluation {
	return []model.RecipeEvaluation{
		{
			// Perfect match for 高校生 (high volume, spiciness)
			Scores: model.EvaluationScores{
				Umami: 30000, Aroma: 25000, Saltiness: 35000, Fat: 20000,
				Sweetness: 15000, Spiciness: 40000, Originality: 25000, Visual: 15000,
				Volume: 50000, Harmony: 20000,
			},
			TotalCost: 420,
		},
		{
			// Good match for キャリアウーマン (high visual, aroma, harmony)
			Scores: model.EvaluationScores{
				Umami: 25000, Aroma: 40000, Saltiness: 20000, Fat: 15000,
				Sweetness: 25000, Spiciness: 10000, Originality: 35000, Visual: 50000,
				Volume: 20000, Harmony: 40000,
			},
			TotalCost: 520,
		},
		{
			// Poor match (all low scores)
			Scores: model.EvaluationScores{
				Umami: 10000, Aroma: 10000, Saltiness: 10000, Fat: 10000,
				Sweetness: 10000, Spiciness: 10000, Originality: 10000, Visual: 10000,
				Volume: 10000, Harmony: 10000,
			},
			TotalCost: 320,
		},
		{
			// Extreme high scores (all maxed out)
			Scores: model.EvaluationScores{
				Umami: 60000, Aroma: 60000, Saltiness: 60000, Fat: 60000,
				Sweetness: 60000, Spiciness: 60000, Originality: 60000, Visual: 60000,
				Volume: 60000, Harmony: 60000,
			},
			TotalCost: 800,
		},
	}
}

func TestEvaluateCustomerSatisfaction(t *testing.T) {
	customers := getTestCustomers()
	recipeEvals := getTestRecipeEvaluations()

	tests := []struct {
		name           string
		recipeEval     model.RecipeEvaluation
		customer       model.CustomerCategory
		price          int
		reputationBonus float64
		expectedChecks func(t *testing.T, result model.CustomerSatisfaction)
	}{
		{
			name:            "perfect_match_affordable_price",
			recipeEval:      recipeEvals[0], // Perfect match for 高校生
			customer:        customers[0],   // 高校生 (budget 800)
			price:           600,            // Well within budget
			reputationBonus: 0.0,
			expectedChecks: func(t *testing.T, result model.CustomerSatisfaction) {
				// Verify satisfaction score is within valid range
				if result.SatisfactionScore < 0 || result.SatisfactionScore > 100 {
					t.Errorf("SatisfactionScore should be 0-100, got %.2f", result.SatisfactionScore)
				}

				// Perfect match with affordable price should yield high satisfaction
				if result.SatisfactionScore < 70.0 {
					t.Errorf("Expected high satisfaction for perfect match, got %.2f", result.SatisfactionScore)
				}

				// Should be willing to return
				if !result.WillReturn {
					t.Error("Customer should be willing to return with high satisfaction")
				}

				// Price should be acceptable
				if !result.PriceAcceptable {
					t.Error("Price should be acceptable within budget")
				}

				// Effective budget should equal base budget (no reputation bonus)
				if result.EffectiveBudget != 800 {
					t.Errorf("Expected effective budget 800, got %d", result.EffectiveBudget)
				}

				// Taste match should be high for perfect match
				if result.DetailedScores.TasteMatch < 80.0 {
					t.Errorf("Expected high taste match for perfect recipe, got %.2f", result.DetailedScores.TasteMatch)
				}

				// Price value should be high for affordable price
				if result.DetailedScores.PriceValue < 70.0 {
					t.Errorf("Expected high price value for affordable price, got %.2f", result.DetailedScores.PriceValue)
				}
			},
		},
		{
			name:            "good_match_with_reputation_bonus",
			recipeEval:      recipeEvals[1], // Good match for キャリアウーマン
			customer:        customers[2],   // キャリアウーマン (budget 1800)
			price:           1600,           // Near budget limit
			reputationBonus: 0.2,            // 20% reputation bonus
			expectedChecks: func(t *testing.T, result model.CustomerSatisfaction) {
				// Effective budget should include reputation bonus
				expectedBudget := int(1800 * 1.2) // 2160
				if result.EffectiveBudget != expectedBudget {
					t.Errorf("Expected effective budget %d, got %d", expectedBudget, result.EffectiveBudget)
				}

				// Price should be acceptable with reputation bonus
				if !result.PriceAcceptable {
					t.Error("Price should be acceptable with reputation bonus")
				}

				// Satisfaction should be reasonable
				if result.SatisfactionScore < 40.0 || result.SatisfactionScore > 100.0 {
					t.Errorf("Satisfaction score should be reasonable, got %.2f", result.SatisfactionScore)
				}

				// Both detailed scores should be positive
				if result.DetailedScores.TasteMatch <= 0 {
					t.Errorf("Taste match should be positive, got %.2f", result.DetailedScores.TasteMatch)
				}
				if result.DetailedScores.PriceValue <= 0 {
					t.Errorf("Price value should be positive, got %.2f", result.DetailedScores.PriceValue)
				}
			},
		},
		{
			name:            "poor_recipe_match",
			recipeEval:      recipeEvals[2], // Poor match (all low scores)
			customer:        customers[1],   // 大学生 (budget 1200)
			price:           800,            // Reasonable price
			reputationBonus: 0.0,
			expectedChecks: func(t *testing.T, result model.CustomerSatisfaction) {
				// Poor recipe match should result in low taste match score
				if result.DetailedScores.TasteMatch > 50.0 {
					t.Errorf("Expected low taste match for poor recipe, got %.2f", result.DetailedScores.TasteMatch)
				}

				// Overall satisfaction should be lower due to poor taste match
				if result.SatisfactionScore > 70.0 {
					t.Errorf("Expected lower satisfaction for poor recipe match, got %.2f", result.SatisfactionScore)
				}

				// Price should still be acceptable
				if !result.PriceAcceptable {
					t.Error("Price should be acceptable within budget")
				}

				// Price value should be reasonable since price is within budget
				if result.DetailedScores.PriceValue < 50.0 {
					t.Errorf("Expected reasonable price value, got %.2f", result.DetailedScores.PriceValue)
				}
			},
		},
		{
			name:            "price_exceeds_budget",
			recipeEval:      recipeEvals[1], // Good recipe
			customer:        customers[0],   // 高校生 (budget 800)
			price:           1200,           // Exceeds budget
			reputationBonus: 0.0,
			expectedChecks: func(t *testing.T, result model.CustomerSatisfaction) {
				// Price should not be acceptable
				if result.PriceAcceptable {
					t.Error("Price should not be acceptable when exceeding budget")
				}

				// Price value should be very low
				if result.DetailedScores.PriceValue > 30.0 {
					t.Errorf("Expected low price value for overpriced item, got %.2f", result.DetailedScores.PriceValue)
				}

				// Overall satisfaction should be low due to price
				if result.SatisfactionScore > 50.0 {
					t.Errorf("Expected low satisfaction for overpriced item, got %.2f", result.SatisfactionScore)
				}

				// Customer should not want to return
				if result.WillReturn {
					t.Error("Customer should not want to return with low satisfaction")
				}
			},
		},
		{
			name:            "extreme_high_scores",
			recipeEval:      recipeEvals[3], // Extreme high scores
			customer:        customers[1],   // 大学生
			price:           400,            // Very affordable
			reputationBonus: 0.0,
			expectedChecks: func(t *testing.T, result model.CustomerSatisfaction) {
				// Very affordable price should yield high price value
				if result.DetailedScores.PriceValue < 90.0 {
					t.Errorf("Expected very high price value for cheap price, got %.2f", result.DetailedScores.PriceValue)
				}

				// Price should definitely be acceptable
				if !result.PriceAcceptable {
					t.Error("Very affordable price should be acceptable")
				}

				// Overall satisfaction should be reasonably high
				if result.SatisfactionScore < 50.0 {
					t.Errorf("Expected reasonably high satisfaction for great recipe and price, got %.2f", result.SatisfactionScore)
				}

				// Customer should want to return
				if !result.WillReturn {
					t.Error("Customer should want to return with high satisfaction")
				}
			},
		},
		{
			name:            "free_recipe_zero_price",
			recipeEval:      recipeEvals[1], // Good recipe
			customer:        customers[2],   // キャリアウーマン
			price:           0,              // Free
			reputationBonus: 0.0,
			expectedChecks: func(t *testing.T, result model.CustomerSatisfaction) {
				// Free should always be acceptable
				if !result.PriceAcceptable {
					t.Error("Free price should always be acceptable")
				}

				// Free should yield maximum price value
				if result.DetailedScores.PriceValue != 100.0 {
					t.Errorf("Expected maximum price value for free, got %.2f", result.DetailedScores.PriceValue)
				}

				// Overall satisfaction should be very high
				if result.SatisfactionScore < 70.0 {
					t.Errorf("Expected very high satisfaction for free good recipe, got %.2f", result.SatisfactionScore)
				}
			},
		},
		{
			name:            "high_reputation_bonus",
			recipeEval:      recipeEvals[0], // Perfect match
			customer:        customers[0],   // 高校生 (budget 800)
			price:           1000,           // Would normally exceed budget
			reputationBonus: 0.5,            // 50% reputation bonus
			expectedChecks: func(t *testing.T, result model.CustomerSatisfaction) {
				// Effective budget should include large reputation bonus
				expectedBudget := int(800 * 1.5) // 1200
				if result.EffectiveBudget != expectedBudget {
					t.Errorf("Expected effective budget %d, got %d", expectedBudget, result.EffectiveBudget)
				}

				// Price should now be acceptable with reputation bonus
				if !result.PriceAcceptable {
					t.Error("Price should be acceptable with high reputation bonus")
				}

				// Satisfaction should be good due to perfect recipe match
				if result.SatisfactionScore < 60.0 {
					t.Errorf("Expected good satisfaction with reputation bonus, got %.2f", result.SatisfactionScore)
				}
			},
		},
		{
			name:            "recipe_with_adjusted_scores",
			recipeEval: model.RecipeEvaluation{
				Scores: model.EvaluationScores{
					Umami: 20000, Aroma: 20000, Saltiness: 20000, Fat: 20000,
					Sweetness: 20000, Spiciness: 20000, Originality: 20000, Visual: 20000,
					Volume: 20000, Harmony: 20000,
				},
				AdjustedScores: &model.EvaluationScores{
					Umami: 26000, Aroma: 26000, Saltiness: 26000, Fat: 26000,
					Sweetness: 26000, Spiciness: 26000, Originality: 26000, Visual: 26000,
					Volume: 26000, Harmony: 26000,
				},
				TotalCost: 500,
			},
			customer:        customers[1], // 大学生
			price:           700,
			reputationBonus: 0.0,
			expectedChecks: func(t *testing.T, result model.CustomerSatisfaction) {
				// Should use adjusted scores for evaluation, not base scores
				// This is hard to test directly, but we can verify satisfaction is reasonable
				if result.SatisfactionScore < 0 || result.SatisfactionScore > 100 {
					t.Errorf("Satisfaction should be in valid range, got %.2f", result.SatisfactionScore)
				}

				// Both detailed scores should be calculated
				if result.DetailedScores.TasteMatch <= 0 {
					t.Errorf("Taste match should be positive, got %.2f", result.DetailedScores.TasteMatch)
				}
				if result.DetailedScores.PriceValue <= 0 {
					t.Errorf("Price value should be positive, got %.2f", result.DetailedScores.PriceValue)
				}
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := EvaluateCustomerSatisfaction(tt.recipeEval, tt.customer, tt.price, tt.reputationBonus)
			tt.expectedChecks(t, result)
		})
	}
}

func TestEvaluateCustomerSatisfaction_EdgeCases(t *testing.T) {
	customers := getTestCustomers()
	recipeEvals := getTestRecipeEvaluations()

	t.Run("negative_reputation_bonus", func(t *testing.T) {
		result := EvaluateCustomerSatisfaction(
			recipeEvals[0],
			customers[0],
			600,
			-0.1, // Negative reputation bonus
		)

		// Effective budget should be reduced
		if result.EffectiveBudget >= 800 {
			t.Errorf("Expected reduced effective budget, got %d", result.EffectiveBudget)
		}

		// All scores should still be in valid ranges
		if result.SatisfactionScore < 0 || result.SatisfactionScore > 100 {
			t.Errorf("Satisfaction score out of range: %.2f", result.SatisfactionScore)
		}
	})

	t.Run("zero_preference_customer", func(t *testing.T) {
		zeroCustomer := model.CustomerCategory{
			ID:         99,
			Name:       "Zero Preference",
			BaseBudget: 1000,
			PreferenceVector: model.EvaluationScores{}, // All zeros
			WeightVector: model.PreferenceWeights{
				Umami: 1.0, Aroma: 1.0, Saltiness: 1.0, Fat: 1.0,
				Sweetness: 1.0, Spiciness: 1.0, Originality: 1.0, Visual: 1.0,
				Volume: 1.0, Harmony: 1.0,
			},
		}

		result := EvaluateCustomerSatisfaction(
			recipeEvals[0],
			zeroCustomer,
			500,
			0.0,
		)

		// Should handle zero preferences gracefully
		if result.SatisfactionScore < 0 || result.SatisfactionScore > 100 {
			t.Errorf("Satisfaction score out of range with zero preferences: %.2f", result.SatisfactionScore)
		}
	})

	t.Run("very_high_price", func(t *testing.T) {
		result := EvaluateCustomerSatisfaction(
			recipeEvals[3], // Best recipe
			customers[2],   // Highest budget customer
			10000,          // Extremely high price
			1.0,            // Maximum reasonable reputation bonus
		)

		// Should handle extreme prices gracefully
		if !result.PriceAcceptable {
			// Price value should be very low
			if result.DetailedScores.PriceValue > 10.0 {
				t.Errorf("Expected very low price value for extreme price, got %.2f", result.DetailedScores.PriceValue)
			}
		}

		// Satisfaction should still be in valid range
		if result.SatisfactionScore < 0 || result.SatisfactionScore > 100 {
			t.Errorf("Satisfaction score out of range: %.2f", result.SatisfactionScore)
		}
	})
}

func TestCalculateTasteMatch(t *testing.T) {
	customers := getTestCustomers()

	// Test direct taste match calculation
	perfectMatchScores := customers[0].PreferenceVector // Exactly matching preferences
	result := calculateTasteMatch(perfectMatchScores, customers[0].PreferenceVector, customers[0].WeightVector)

	if result < 95.0 {
		t.Errorf("Perfect match should yield very high taste match score, got %.2f", result)
	}

	// Test completely different scores
	oppositeScores := model.EvaluationScores{
		Umami: 60000, Aroma: 60000, Saltiness: 60000, Fat: 60000,
		Sweetness: 60000, Spiciness: 60000, Originality: 60000, Visual: 60000,
		Volume: 60000, Harmony: 60000,
	}
	result = calculateTasteMatch(oppositeScores, customers[0].PreferenceVector, customers[0].WeightVector)

	if result > 70.0 {
		t.Errorf("Opposite scores should yield lower taste match, got %.2f", result)
	}
}

func TestCalculatePriceValue(t *testing.T) {
	// Test free price
	result := calculatePriceValue(0, 1000, true)
	if result != 100.0 {
		t.Errorf("Free price should yield 100%% value, got %.2f", result)
	}

	// Test excellent value (50% of budget)
	result = calculatePriceValue(500, 1000, true)
	if result != 100.0 {
		t.Errorf("Excellent value should yield 100%%, got %.2f", result)
	}

	// Test overpriced item
	result = calculatePriceValue(1200, 1000, false)
	if result > 20.0 {
		t.Errorf("Overpriced item should yield low value, got %.2f", result)
	}

	// Test price at budget limit
	result = calculatePriceValue(1000, 1000, true)
	if result < 40.0 || result > 60.0 {
		t.Errorf("Price at budget limit should yield moderate value, got %.2f", result)
	}
}