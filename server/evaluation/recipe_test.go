package evaluation

import (
	"testing"

	"github.com/ayasuda/rs/server/model"
)

// Test data - sample ingredients for testing
func getTestIngredients() []model.Ingredient {
	return []model.Ingredient{
		{
			ID:       "thick_noodles",
			Name:     "太麺",
			Category: "noodles",
			Contributions: model.EvaluationScores{
				Umami: 5000, Aroma: 2000, Saltiness: 1000, Fat: 2000,
				Sweetness: 1000, Spiciness: 0, Originality: 3000, Visual: 8000,
				Volume: 15000, Harmony: 8000,
			},
		},
		{
			ID:       "chicken_broth",
			Name:     "鶏白湯",
			Category: "soup",
			Contributions: model.EvaluationScores{
				Umami: 20000, Aroma: 15000, Saltiness: 12000, Fat: 8000,
				Sweetness: 3000, Spiciness: 2000, Originality: 5000, Visual: 5000,
				Volume: 8000, Harmony: 12000,
			},
		},
		{
			ID:       "shoyu_tare",
			Name:     "醤油だれ",
			Category: "sauce",
			Contributions: model.EvaluationScores{
				Umami: 8000, Aroma: 5000, Saltiness: 15000, Fat: 3000,
				Sweetness: 2000, Spiciness: 8000, Originality: 4000, Visual: 3000,
				Volume: 2000, Harmony: 6000,
			},
		},
		{
			ID:       "sesame_oil",
			Name:     "ごま油",
			Category: "oil",
			Contributions: model.EvaluationScores{
				Umami: 3000, Aroma: 8000, Saltiness: 2000, Fat: 20000,
				Sweetness: 1000, Spiciness: 1000, Originality: 2000, Visual: 4000,
				Volume: 1000, Harmony: 5000,
			},
		},
		{
			ID:       "chashu",
			Name:     "チャーシュー",
			Category: "topping",
			Contributions: model.EvaluationScores{
				Umami: 6000, Aroma: 4000, Saltiness: 3000, Fat: 5000,
				Sweetness: 2000, Spiciness: 3000, Originality: 8000, Visual: 12000,
				Volume: 6000, Harmony: 4000,
			},
		},
		{
			ID:       "green_onion",
			Name:     "ネギ",
			Category: "topping",
			Contributions: model.EvaluationScores{
				Umami: 2000, Aroma: 6000, Saltiness: 1000, Fat: 500,
				Sweetness: 1500, Spiciness: 2000, Originality: 3000, Visual: 8000,
				Volume: 2000, Harmony: 3000,
			},
		},
		{
			ID:       "standard_bowl",
			Name:     "標準盛り",
			Category: "presentation",
			Contributions: model.EvaluationScores{
				Umami: 1000, Aroma: 2000, Saltiness: 500, Fat: 1000,
				Sweetness: 1000, Spiciness: 500, Originality: 6000, Visual: 15000,
				Volume: 2000, Harmony: 8000,
			},
		},
	}
}

func TestEvaluateRecipe(t *testing.T) {
	ingredients := getTestIngredients()

	// Helper function to create float32 pointer
	float32Ptr := func(f float32) *float32 { return &f }

	tests := []struct {
		name           string
		recipe         model.Recipe
		expectedChecks func(t *testing.T, result model.RecipeEvaluation)
	}{
		{
			name: "basic recipe without cooking skill",
			recipe: model.Recipe{
				Noodles:      model.Ingredient{ID: "thick_noodles"},
				Soup:         model.Ingredient{ID: "chicken_broth"},
				Sauce:        model.Ingredient{ID: "shoyu_tare"},
				Oil:          model.Ingredient{ID: "sesame_oil"},
				Toppings:     []model.Ingredient{{ID: "chashu"}},
				Presentation: model.Ingredient{ID: "standard_bowl"},
			},
			expectedChecks: func(t *testing.T, result model.RecipeEvaluation) {
				// Verify all scores are positive
				if result.Scores.Umami <= 0 {
					t.Errorf("Expected positive Umami score, got %d", result.Scores.Umami)
				}
				if result.Scores.Aroma <= 0 {
					t.Errorf("Expected positive Aroma score, got %d", result.Scores.Aroma)
				}
				if result.Scores.Saltiness <= 0 {
					t.Errorf("Expected positive Saltiness score, got %d", result.Scores.Saltiness)
				}

				// Verify total cost is calculated
				if result.TotalCost <= 0 {
					t.Errorf("Expected positive total cost, got %d", result.TotalCost)
				}

				// Verify no adjusted scores when no cooking skill
				if result.AdjustedScores != nil {
					t.Error("Expected no adjusted scores when cooking skill is not provided")
				}

				// Verify expected total from ingredient contributions
				expectedUmami := 5000 + 20000 + 8000 + 3000 + 6000 + 1000 // sum of all ingredient umami
				if result.Scores.Umami != expectedUmami {
					t.Errorf("Expected Umami %d, got %d", expectedUmami, result.Scores.Umami)
				}
			},
		},
		{
			name: "recipe with cooking skill level 5",
			recipe: model.Recipe{
				Noodles:           model.Ingredient{ID: "thick_noodles"},
				Soup:              model.Ingredient{ID: "chicken_broth"},
				Sauce:             model.Ingredient{ID: "shoyu_tare"},
				Oil:               model.Ingredient{ID: "sesame_oil"},
				Toppings:          []model.Ingredient{{ID: "chashu"}},
				Presentation:      model.Ingredient{ID: "standard_bowl"},
				CookingSkillLevel: float32Ptr(5.0),
			},
			expectedChecks: func(t *testing.T, result model.RecipeEvaluation) {
				// Verify adjusted scores exist
				if result.AdjustedScores == nil {
					t.Fatal("Expected adjusted scores when cooking skill is provided")
				}

				// Verify adjusted scores are higher than base scores (due to skill bonus)
				if result.AdjustedScores.Umami <= result.Scores.Umami {
					t.Errorf("Expected adjusted Umami (%d) to be higher than base (%d)",
						result.AdjustedScores.Umami, result.Scores.Umami)
				}

				// Verify harmony gets bigger bonus (8% vs 3% per skill level)
				harmonyBonus := float64(result.AdjustedScores.Harmony) / float64(result.Scores.Harmony)
				umamiBonus := float64(result.AdjustedScores.Umami) / float64(result.Scores.Umami)

				if harmonyBonus <= umamiBonus {
					t.Errorf("Expected harmony bonus (%.3f) to be larger than umami bonus (%.3f)",
						harmonyBonus, umamiBonus)
				}
			},
		},
		{
			name: "recipe with cooking skill level 10 (maximum)",
			recipe: model.Recipe{
				Noodles:           model.Ingredient{ID: "thick_noodles"},
				Soup:              model.Ingredient{ID: "chicken_broth"},
				Sauce:             model.Ingredient{ID: "shoyu_tare"},
				Oil:               model.Ingredient{ID: "sesame_oil"},
				Toppings:          []model.Ingredient{{ID: "chashu"}},
				Presentation:      model.Ingredient{ID: "standard_bowl"},
				CookingSkillLevel: float32Ptr(10.0),
			},
			expectedChecks: func(t *testing.T, result model.RecipeEvaluation) {
				if result.AdjustedScores == nil {
					t.Fatal("Expected adjusted scores when cooking skill is provided")
				}

				// At skill level 10, expect 30% bonus for most attributes
				expectedUmamiBonus := 1.30 // 1 + (10/100)*3
				actualUmamiBonus := float64(result.AdjustedScores.Umami) / float64(result.Scores.Umami)

				if actualUmamiBonus < expectedUmamiBonus-0.01 || actualUmamiBonus > expectedUmamiBonus+0.01 {
					t.Errorf("Expected umami bonus around %.2f, got %.2f", expectedUmamiBonus, actualUmamiBonus)
				}

				// At skill level 10, expect 80% bonus for harmony
				expectedHarmonyBonus := 1.80 // 1 + (10/100)*8
				actualHarmonyBonus := float64(result.AdjustedScores.Harmony) / float64(result.Scores.Harmony)

				if actualHarmonyBonus < expectedHarmonyBonus-0.01 || actualHarmonyBonus > expectedHarmonyBonus+0.01 {
					t.Errorf("Expected harmony bonus around %.2f, got %.2f", expectedHarmonyBonus, actualHarmonyBonus)
				}
			},
		},
		{
			name: "recipe with multiple toppings",
			recipe: model.Recipe{
				Noodles:      model.Ingredient{ID: "thick_noodles"},
				Soup:         model.Ingredient{ID: "chicken_broth"},
				Sauce:        model.Ingredient{ID: "shoyu_tare"},
				Oil:          model.Ingredient{ID: "sesame_oil"},
				Toppings:     []model.Ingredient{{ID: "chashu"}, {ID: "green_onion"}},
				Presentation: model.Ingredient{ID: "standard_bowl"},
			},
			expectedChecks: func(t *testing.T, result model.RecipeEvaluation) {
				// Verify both toppings contribute to scores
				expectedUmami := 5000 + 20000 + 8000 + 3000 + 6000 + 2000 + 1000 // includes both toppings
				if result.Scores.Umami != expectedUmami {
					t.Errorf("Expected Umami with multiple toppings %d, got %d", expectedUmami, result.Scores.Umami)
				}

				// Verify cost includes both toppings (80 each)
				expectedMinCost := 80 + 120 + 60 + 40 + 80 + 80 + 40 // noodles + soup + sauce + oil + topping1 + topping2 + presentation
				if result.TotalCost != expectedMinCost {
					t.Errorf("Expected total cost %d, got %d", expectedMinCost, result.TotalCost)
				}
			},
		},
		{
			name: "recipe with zero cooking skill",
			recipe: model.Recipe{
				Noodles:           model.Ingredient{ID: "thick_noodles"},
				Soup:              model.Ingredient{ID: "chicken_broth"},
				Sauce:             model.Ingredient{ID: "shoyu_tare"},
				Oil:               model.Ingredient{ID: "sesame_oil"},
				Toppings:          []model.Ingredient{{ID: "chashu"}},
				Presentation:      model.Ingredient{ID: "standard_bowl"},
				CookingSkillLevel: float32Ptr(0.0),
			},
			expectedChecks: func(t *testing.T, result model.RecipeEvaluation) {
				if result.AdjustedScores == nil {
					t.Fatal("Expected adjusted scores when cooking skill is provided")
				}

				// With skill level 0, adjusted scores should equal base scores
				if result.AdjustedScores.Umami != result.Scores.Umami {
					t.Errorf("Expected adjusted Umami (%d) to equal base (%d) with zero skill",
						result.AdjustedScores.Umami, result.Scores.Umami)
				}

				if result.AdjustedScores.Harmony != result.Scores.Harmony {
					t.Errorf("Expected adjusted Harmony (%d) to equal base (%d) with zero skill",
						result.AdjustedScores.Harmony, result.Scores.Harmony)
				}
			},
		},
		{
			name: "recipe with unknown ingredient IDs",
			recipe: model.Recipe{
				Noodles:      model.Ingredient{ID: "unknown_noodles"},
				Soup:         model.Ingredient{ID: "chicken_broth"},
				Sauce:        model.Ingredient{ID: "shoyu_tare"},
				Oil:          model.Ingredient{ID: "sesame_oil"},
				Toppings:     []model.Ingredient{{ID: "unknown_topping"}},
				Presentation: model.Ingredient{ID: "standard_bowl"},
			},
			expectedChecks: func(t *testing.T, result model.RecipeEvaluation) {
				// Unknown ingredients should not contribute to scores
				// Only soup + sauce + oil + presentation should contribute
				expectedUmami := 20000 + 8000 + 3000 + 1000
				if result.Scores.Umami != expectedUmami {
					t.Errorf("Expected Umami with unknown ingredients %d, got %d", expectedUmami, result.Scores.Umami)
				}

				// Cost should still be calculated for known ingredients
				expectedCost := 120 + 60 + 40 + 40 // soup + sauce + oil + presentation
				if result.TotalCost != expectedCost {
					t.Errorf("Expected cost with unknown ingredients %d, got %d", expectedCost, result.TotalCost)
				}
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := EvaluateRecipe(tt.recipe, ingredients)
			tt.expectedChecks(t, result)
		})
	}
}

func TestEvaluateRecipe_ScoreRanges(t *testing.T) {
	ingredients := getTestIngredients()

	recipe := model.Recipe{
		Noodles:      model.Ingredient{ID: "thick_noodles"},
		Soup:         model.Ingredient{ID: "chicken_broth"},
		Sauce:        model.Ingredient{ID: "shoyu_tare"},
		Oil:          model.Ingredient{ID: "sesame_oil"},
		Toppings:     []model.Ingredient{{ID: "chashu"}, {ID: "green_onion"}},
		Presentation: model.Ingredient{ID: "standard_bowl"},
	}

	result := EvaluateRecipe(recipe, ingredients)

	// Test that all scores are within reasonable ranges (0-100000)
	scores := []struct {
		name  string
		value int
	}{
		{"Umami", result.Scores.Umami},
		{"Aroma", result.Scores.Aroma},
		{"Saltiness", result.Scores.Saltiness},
		{"Fat", result.Scores.Fat},
		{"Sweetness", result.Scores.Sweetness},
		{"Spiciness", result.Scores.Spiciness},
		{"Originality", result.Scores.Originality},
		{"Visual", result.Scores.Visual},
		{"Volume", result.Scores.Volume},
		{"Harmony", result.Scores.Harmony},
	}

	for _, score := range scores {
		t.Run("score_range_"+score.name, func(t *testing.T) {
			if score.value < 0 {
				t.Errorf("%s score should not be negative, got %d", score.name, score.value)
			}
			if score.value > 100000 {
				t.Errorf("%s score should not exceed 100000, got %d", score.name, score.value)
			}
		})
	}
}