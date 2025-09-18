package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	openapi "github.com/ayasuda/rs/server/gen"
)

// Server implements the OpenAPI ServerInterface using Gin
type Server struct{}

// NewServer creates a new server instance
func NewServer() *Server {
	return &Server{}
}

// GetCustomerCategories handles GET /customers/categories
func (s *Server) GetCustomerCategories(c *gin.Context) {
	// Mock response with sample customer categories
	categories := []openapi.CustomerCategory{
		{
			Id:   1,
			Name: "高校生",
			PreferenceVector: openapi.EvaluationScores{
				Umami:       30000,
				Aroma:       25000,
				Saltiness:   35000,
				Fat:         20000,
				Sweetness:   15000,
				Spiciness:   40000,
				Originality: 25000,
				Visual:      15000,
				Volume:      50000,
				Harmony:     20000,
			},
			WeightVector: openapi.PreferenceWeights{
				Umami:       1.0,
				Aroma:       0.8,
				Saltiness:   1.2,
				Fat:         0.6,
				Sweetness:   0.5,
				Spiciness:   1.5,
				Originality: 1.0,
				Visual:      0.3,
				Volume:      2.0,
				Harmony:     0.4,
			},
			BaseBudget: 800,
			TimeSlots: []openapi.TimeSlot{
				{Period: openapi.Afternoon, Preference: openapi.High},
				{Period: openapi.Evening, Preference: openapi.High},
			},
			Characteristics: &[]string{"低予算", "友人と来店", "ボリューム重視"},
		},
		{
			Id:   2,
			Name: "大学生",
			PreferenceVector: openapi.EvaluationScores{
				Umami:       35000,
				Aroma:       30000,
				Saltiness:   30000,
				Fat:         35000,
				Sweetness:   20000,
				Spiciness:   35000,
				Originality: 40000,
				Visual:      25000,
				Volume:      45000,
				Harmony:     25000,
			},
			WeightVector: openapi.PreferenceWeights{
				Umami:       1.2,
				Aroma:       1.0,
				Saltiness:   1.0,
				Fat:         1.5,
				Sweetness:   0.8,
				Spiciness:   1.3,
				Originality: 1.5,
				Visual:      1.0,
				Volume:      1.8,
				Harmony:     0.6,
			},
			BaseBudget: 1200,
			TimeSlots: []openapi.TimeSlot{
				{Period: openapi.Lunch, Preference: openapi.High},
				{Period: openapi.Evening, Preference: openapi.High},
				{Period: openapi.Night, Preference: openapi.Medium},
			},
			Characteristics: &[]string{"中予算", "味と量どちらも重視", "創作系にも反応"},
		},
	}

	c.JSON(http.StatusOK, categories)
}

// GetCustomerCategory handles GET /customers/categories/{categoryId}
func (s *Server) GetCustomerCategory(c *gin.Context) {
	categoryIdStr := c.Param("categoryId")
	categoryId, err := strconv.Atoi(categoryIdStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, openapi.Error{
			Code:    "INVALID_CATEGORY_ID",
			Message: "Invalid category ID format",
		})
		return
	}
	
	// Mock response for category ID 1
	if categoryId == 1 {
		category := openapi.CustomerCategory{
			Id:   1,
			Name: "高校生",
			PreferenceVector: openapi.EvaluationScores{
				Umami:       30000,
				Aroma:       25000,
				Saltiness:   35000,
				Fat:         20000,
				Sweetness:   15000,
				Spiciness:   40000,
				Originality: 25000,
				Visual:      15000,
				Volume:      50000,
				Harmony:     20000,
			},
			WeightVector: openapi.PreferenceWeights{
				Umami:       1.0,
				Aroma:       0.8,
				Saltiness:   1.2,
				Fat:         0.6,
				Sweetness:   0.5,
				Spiciness:   1.5,
				Originality: 1.0,
				Visual:      0.3,
				Volume:      2.0,
				Harmony:     0.4,
			},
			BaseBudget: 800,
			TimeSlots: []openapi.TimeSlot{
				{Period: openapi.Afternoon, Preference: openapi.High},
				{Period: openapi.Evening, Preference: openapi.High},
			},
			Characteristics: &[]string{"低予算", "友人と来店", "ボリューム重視"},
		}
		c.JSON(http.StatusOK, category)
		return
	}

	// Return 404 for other category IDs
	c.JSON(http.StatusNotFound, openapi.Error{
		Code:    "NOT_FOUND",
		Message: "Customer category not found",
	})
}

// EvaluateRecipe handles POST /recipes/evaluate
func (s *Server) EvaluateRecipe(c *gin.Context) {
	var recipe openapi.Recipe
	if err := c.ShouldBindJSON(&recipe); err != nil {
		c.JSON(http.StatusBadRequest, openapi.Error{
			Code:    "INVALID_REQUEST",
			Message: "Invalid recipe data",
		})
		return
	}

	// Mock evaluation - simple calculation based on ingredients
	baseScores := openapi.EvaluationScores{
		Umami:       35000,
		Aroma:       17000,
		Saltiness:   17000,
		Fat:         32000,
		Sweetness:   8000,
		Spiciness:   3500,
		Originality: 9000,
		Visual:      12500,
		Volume:      12000,
		Harmony:     27000,
	}

	// Apply cooking skill bonus (3% + 5% for harmony)
	skillLevel := 5.0
	if recipe.CookingSkillLevel != nil {
		skillLevel = float64(*recipe.CookingSkillLevel)
	}
	skillBonus := 1.0 + (skillLevel/100.0)*3.0
	harmonyBonus := 1.0 + (skillLevel/100.0)*8.0

	adjustedScores := openapi.EvaluationScores{
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

	evaluation := openapi.RecipeEvaluation{
		Scores:         baseScores,
		TotalCost:      420,
		AdjustedScores: &adjustedScores,
	}

	c.JSON(http.StatusOK, evaluation)
}

// EvaluateCustomerSatisfaction handles POST /customers/evaluate
func (s *Server) EvaluateCustomerSatisfaction(c *gin.Context) {
	var request openapi.CustomerEvaluationRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, openapi.Error{
			Code:    "INVALID_REQUEST",
			Message: "Invalid evaluation request",
		})
		return
	}

	// Mock satisfaction calculation
	// For simplicity, just return a decent satisfaction score
	baseBudget := 1000
	reputationBonus := float32(0.0)
	if request.ReputationBonus != nil {
		reputationBonus = *request.ReputationBonus
	}
	
	effectiveBudget := int(float32(baseBudget) * (1.0 + reputationBonus))
	priceAcceptable := request.Price <= effectiveBudget
	
	satisfactionScore := float32(85.0)
	if !priceAcceptable {
		satisfactionScore = 45.0
	}

	tasteMatch := float32(90.0)
	priceValue := float32(80.0)

	satisfaction := openapi.CustomerSatisfaction{
		SatisfactionScore: satisfactionScore,
		WillReturn:        satisfactionScore > 70.0,
		PriceAcceptable:   priceAcceptable,
		EffectiveBudget:   &effectiveBudget,
		DetailedScores: &struct {
			PriceValue *float32 `json:"priceValue,omitempty"`
			TasteMatch *float32 `json:"tasteMatch,omitempty"`
		}{
			TasteMatch: &tasteMatch,
			PriceValue: &priceValue,
		},
	}

	c.JSON(http.StatusOK, satisfaction)
}

// CalculatePricing handles POST /pricing/calculate
func (s *Server) CalculatePricing(c *gin.Context) {
	var recipe openapi.Recipe
	if err := c.ShouldBindJSON(&recipe); err != nil {
		c.JSON(http.StatusBadRequest, openapi.Error{
			Code:    "INVALID_REQUEST",
			Message: "Invalid recipe data",
		})
		return
	}

	// Mock pricing calculation
	baseCost := 420
	suggestedPrice := int(float64(baseCost) * 2.5) // 2.5x markup
	profitMargin := float32(float64(suggestedPrice-baseCost) / float64(suggestedPrice))

	costBreakdown := map[string]int{
		"noodles":      80,
		"soup":         120,
		"sauce":        60,
		"oil":          40,
		"toppings":     80,
		"presentation": 40,
	}

	pricing := openapi.PricingInfo{
		BaseCost:       baseCost,
		SuggestedPrice: suggestedPrice,
		ProfitMargin:   profitMargin,
		CostBreakdown:  &costBreakdown,
	}

	c.JSON(http.StatusOK, pricing)
}

// SetupRoutes configures the Gin routes for the API
func (s *Server) SetupRoutes(r *gin.Engine) {
	// Customer routes
	r.GET("/customers/categories", s.GetCustomerCategories)
	r.GET("/customers/categories/:categoryId", s.GetCustomerCategory)
	r.POST("/customers/evaluate", s.EvaluateCustomerSatisfaction)

	// Recipe routes
	r.POST("/recipes/evaluate", s.EvaluateRecipe)

	// Pricing routes
	r.POST("/pricing/calculate", s.CalculatePricing)

	// Master data routes
	r.GET("/master/ingredients", s.GetMasterIngredients)
	r.GET("/master/customers", s.GetMasterCustomers)
}