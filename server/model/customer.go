package model

import (
	"encoding/csv"
	"fmt"
	"os"
	"strconv"
	"strings"
)

// CustomerCategory represents a customer category with preferences and characteristics
type CustomerCategory struct {
	ID              int              `json:"id"`
	Name            string           `json:"name"`
	BaseBudget      int              `json:"baseBudget"`
	TimeSlots       []string         `json:"timeSlots"`
	Characteristics []string         `json:"characteristics"`
	PreferenceVector EvaluationScores `json:"preferenceVector"`
	WeightVector    PreferenceWeights `json:"weightVector"`
}

// PreferenceWeights represents importance weights for each evaluation axis
type PreferenceWeights struct {
	Umami       float32 `json:"umami"`
	Aroma       float32 `json:"aroma"`
	Saltiness   float32 `json:"saltiness"`
	Fat         float32 `json:"fat"`
	Sweetness   float32 `json:"sweetness"`
	Spiciness   float32 `json:"spiciness"`
	Originality float32 `json:"originality"`
	Visual      float32 `json:"visual"`
	Volume      float32 `json:"volume"`
	Harmony     float32 `json:"harmony"`
}

// LoadCustomers loads customer categories from CSV file with mock preference data
func LoadCustomers(filePath string) ([]CustomerCategory, error) {
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
	customers := make([]CustomerCategory, 0, len(records)-1)
	for i, record := range records {
		if i == 0 { // Skip header
			continue
		}

		if len(record) != 5 {
			return nil, fmt.Errorf("invalid customer record at line %d: expected 5 fields, got %d", i+1, len(record))
		}

		id, err := strconv.Atoi(strings.TrimSpace(record[0]))
		if err != nil {
			return nil, fmt.Errorf("invalid customer ID at line %d: %w", i+1, err)
		}

		baseBudget, err := strconv.Atoi(strings.TrimSpace(record[2]))
		if err != nil {
			return nil, fmt.Errorf("invalid base budget at line %d: %w", i+1, err)
		}

		// Parse comma-separated time slots
		timeSlots := []string{}
		if timeSlotStr := strings.TrimSpace(record[3]); timeSlotStr != "" {
			for _, slot := range strings.Split(timeSlotStr, ",") {
				timeSlots = append(timeSlots, strings.TrimSpace(slot))
			}
		}

		// Parse semicolon-separated characteristics
		characteristics := []string{}
		if charStr := strings.TrimSpace(record[4]); charStr != "" {
			for _, char := range strings.Split(charStr, ";") {
				characteristics = append(characteristics, strings.TrimSpace(char))
			}
		}

		// Generate mock preference and weight vectors based on customer type
		preferenceVector, weightVector := generateMockPreferences(id, strings.TrimSpace(record[1]))

		customer := CustomerCategory{
			ID:               id,
			Name:             strings.TrimSpace(record[1]),
			BaseBudget:       baseBudget,
			TimeSlots:        timeSlots,
			Characteristics:  characteristics,
			PreferenceVector: preferenceVector,
			WeightVector:     weightVector,
		}
		customers = append(customers, customer)
	}

	return customers, nil
}

// generateMockPreferences creates realistic preference and weight vectors for customer types
func generateMockPreferences(id int, name string) (EvaluationScores, PreferenceWeights) {
	switch id {
	case 1: // 高校生 - volume and price focused
		return EvaluationScores{
				Umami: 30000, Aroma: 25000, Saltiness: 35000, Fat: 20000,
				Sweetness: 15000, Spiciness: 40000, Originality: 25000, Visual: 15000,
				Volume: 50000, Harmony: 20000,
			}, PreferenceWeights{
				Umami: 1.0, Aroma: 0.8, Saltiness: 1.2, Fat: 0.6,
				Sweetness: 0.5, Spiciness: 1.5, Originality: 1.0, Visual: 0.3,
				Volume: 2.0, Harmony: 0.4,
			}
	case 2: // 大学生 - balanced with creativity
		return EvaluationScores{
				Umami: 35000, Aroma: 30000, Saltiness: 30000, Fat: 35000,
				Sweetness: 20000, Spiciness: 35000, Originality: 40000, Visual: 25000,
				Volume: 45000, Harmony: 25000,
			}, PreferenceWeights{
				Umami: 1.2, Aroma: 1.0, Saltiness: 1.0, Fat: 1.5,
				Sweetness: 0.8, Spiciness: 1.3, Originality: 1.5, Visual: 1.0,
				Volume: 1.8, Harmony: 0.6,
			}
	case 3: // 会社員 - speed and stability
		return EvaluationScores{
				Umami: 40000, Aroma: 35000, Saltiness: 40000, Fat: 30000,
				Sweetness: 15000, Spiciness: 30000, Originality: 20000, Visual: 20000,
				Volume: 35000, Harmony: 35000,
			}, PreferenceWeights{
				Umami: 1.3, Aroma: 1.1, Saltiness: 1.4, Fat: 1.0,
				Sweetness: 0.5, Spiciness: 1.2, Originality: 0.7, Visual: 0.8,
				Volume: 1.2, Harmony: 1.5,
			}
	case 4: // キャリアウーマン - visual and light
		return EvaluationScores{
				Umami: 25000, Aroma: 40000, Saltiness: 20000, Fat: 15000,
				Sweetness: 25000, Spiciness: 10000, Originality: 35000, Visual: 50000,
				Volume: 20000, Harmony: 40000,
			}, PreferenceWeights{
				Umami: 1.0, Aroma: 1.6, Saltiness: 0.7, Fat: 0.4,
				Sweetness: 1.0, Spiciness: 0.3, Originality: 1.4, Visual: 2.0,
				Volume: 0.6, Harmony: 1.8,
			}
	default:
		// Default balanced preferences
		return EvaluationScores{
				Umami: 30000, Aroma: 30000, Saltiness: 30000, Fat: 30000,
				Sweetness: 20000, Spiciness: 25000, Originality: 25000, Visual: 30000,
				Volume: 30000, Harmony: 30000,
			}, PreferenceWeights{
				Umami: 1.0, Aroma: 1.0, Saltiness: 1.0, Fat: 1.0,
				Sweetness: 1.0, Spiciness: 1.0, Originality: 1.0, Visual: 1.0,
				Volume: 1.0, Harmony: 1.0,
			}
	}
}