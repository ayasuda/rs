package model

import (
	"encoding/csv"
	"fmt"
	"os"
	"strings"
)

// Ingredient represents an ingredient with its properties and contribution values
type Ingredient struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Category string `json:"category"`
	// Contribution values for each evaluation axis
	Contributions EvaluationScores `json:"contributions"`
}

// EvaluationScores represents the 10-axis evaluation scores
type EvaluationScores struct {
	Umami       int `json:"umami"`
	Aroma       int `json:"aroma"`
	Saltiness   int `json:"saltiness"`
	Fat         int `json:"fat"`
	Sweetness   int `json:"sweetness"`
	Spiciness   int `json:"spiciness"`
	Originality int `json:"originality"`
	Visual      int `json:"visual"`
	Volume      int `json:"volume"`
	Harmony     int `json:"harmony"`
}

// Recipe represents a complete ramen recipe
type Recipe struct {
	Noodles           Ingredient   `json:"noodles"`
	Soup              Ingredient   `json:"soup"`
	Sauce             Ingredient   `json:"sauce"`
	Oil               Ingredient   `json:"oil"`
	Toppings          []Ingredient `json:"toppings"`
	Presentation      Ingredient   `json:"presentation"`
	CookingSkillLevel *float32     `json:"cookingSkillLevel,omitempty"`
}

// RecipeEvaluation represents the evaluation result of a recipe
type RecipeEvaluation struct {
	Scores         EvaluationScores  `json:"scores"`
	TotalCost      int               `json:"totalCost"`
	AdjustedScores *EvaluationScores `json:"adjustedScores,omitempty"`
}

// LoadIngredients loads ingredients from CSV file with mock contribution values
func LoadIngredients(filePath string) ([]Ingredient, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	reader := csv.NewReader(file)
	records, err := reader.ReadAll()
	if err != nil {
		return nil, err
	}

	// Skip header row and parse data
	ingredients := make([]Ingredient, 0, len(records)-1)
	for i, record := range records {
		if i == 0 { // Skip header
			continue
		}

		if len(record) != 3 {
			return nil, fmt.Errorf("invalid ingredient record at line %d: expected 3 fields, got %d", i+1, len(record))
		}

		ingredient := Ingredient{
			ID:       strings.TrimSpace(record[0]),
			Name:     strings.TrimSpace(record[1]),
			Category: strings.TrimSpace(record[2]),
			Contributions: generateMockContributions(strings.TrimSpace(record[2])),
		}
		ingredients = append(ingredients, ingredient)
	}

	return ingredients, nil
}

// generateMockContributions creates realistic contribution values based on category
func generateMockContributions(category string) EvaluationScores {
	switch category {
	case "noodles":
		return EvaluationScores{
			Umami: 5000, Aroma: 2000, Saltiness: 1000, Fat: 2000,
			Sweetness: 1000, Spiciness: 0, Originality: 3000, Visual: 8000,
			Volume: 15000, Harmony: 8000,
		}
	case "soup":
		return EvaluationScores{
			Umami: 20000, Aroma: 15000, Saltiness: 12000, Fat: 8000,
			Sweetness: 3000, Spiciness: 2000, Originality: 5000, Visual: 5000,
			Volume: 8000, Harmony: 12000,
		}
	case "sauce":
		return EvaluationScores{
			Umami: 8000, Aroma: 5000, Saltiness: 15000, Fat: 3000,
			Sweetness: 2000, Spiciness: 8000, Originality: 4000, Visual: 3000,
			Volume: 2000, Harmony: 6000,
		}
	case "oil":
		return EvaluationScores{
			Umami: 3000, Aroma: 8000, Saltiness: 2000, Fat: 20000,
			Sweetness: 1000, Spiciness: 1000, Originality: 2000, Visual: 4000,
			Volume: 1000, Harmony: 5000,
		}
	case "topping":
		return EvaluationScores{
			Umami: 6000, Aroma: 4000, Saltiness: 3000, Fat: 5000,
			Sweetness: 2000, Spiciness: 3000, Originality: 8000, Visual: 12000,
			Volume: 6000, Harmony: 4000,
		}
	case "presentation":
		return EvaluationScores{
			Umami: 1000, Aroma: 2000, Saltiness: 500, Fat: 1000,
			Sweetness: 1000, Spiciness: 500, Originality: 6000, Visual: 15000,
			Volume: 2000, Harmony: 8000,
		}
	default:
		return EvaluationScores{}
	}
}