package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	openapi "github.com/ayasuda/rs/server/gen"
	"github.com/ayasuda/rs/server/evaluation"
	"github.com/ayasuda/rs/server/model"
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

	// Convert OpenAPI recipe to model recipe
	modelRecipe := convertToModelRecipe(recipe)

	// Use the evaluation package to evaluate the recipe
	modelEvaluation := evaluation.EvaluateRecipe(modelRecipe, masterIngredients)

	// Convert back to OpenAPI format
	openAPIEvaluation := convertToOpenAPIEvaluation(modelEvaluation)

	c.JSON(http.StatusOK, openAPIEvaluation)
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

	// Find the customer category
	var customer *model.CustomerCategory
	for _, customerData := range masterCustomers {
		if customerData.ID == request.CustomerCategoryId {
			customer = &customerData
			break
		}
	}

	if customer == nil {
		c.JSON(http.StatusBadRequest, openapi.Error{
			Code:    "INVALID_CUSTOMER_ID",
			Message: "Customer category not found",
		})
		return
	}

	// Convert OpenAPI RecipeEvaluation to model RecipeEvaluation
	modelRecipeEval := convertToModelRecipeEvaluation(request.RecipeEvaluation)

	// Get reputation bonus
	reputationBonus := 0.0
	if request.ReputationBonus != nil {
		reputationBonus = float64(*request.ReputationBonus)
	}

	// Use the evaluation package to calculate satisfaction
	modelSatisfaction := evaluation.EvaluateCustomerSatisfaction(
		modelRecipeEval,
		*customer,
		request.Price,
		reputationBonus,
	)

	// Convert back to OpenAPI format
	openAPISatisfaction := convertToOpenAPICustomerSatisfaction(modelSatisfaction)

	c.JSON(http.StatusOK, openAPISatisfaction)
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

// convertToModelRecipe converts OpenAPI Recipe to model Recipe
func convertToModelRecipe(openAPIRecipe openapi.Recipe) model.Recipe {
	modelRecipe := model.Recipe{
		Noodles:           convertToModelIngredient(openAPIRecipe.Noodles),
		Soup:              convertToModelIngredient(openAPIRecipe.Soup),
		Sauce:             convertToModelIngredient(openAPIRecipe.Sauce),
		Oil:               convertToModelIngredient(openAPIRecipe.Oil),
		Presentation:      convertToModelIngredient(openAPIRecipe.Presentation),
		CookingSkillLevel: openAPIRecipe.CookingSkillLevel,
	}

	// Convert toppings
	for _, topping := range openAPIRecipe.Toppings {
		modelRecipe.Toppings = append(modelRecipe.Toppings, convertToModelIngredient(topping))
	}

	return modelRecipe
}

// convertToModelIngredient converts OpenAPI Ingredient to model Ingredient
func convertToModelIngredient(openAPIIngredient openapi.Ingredient) model.Ingredient {
	return model.Ingredient{
		ID:       openAPIIngredient.Id,
		Name:     openAPIIngredient.Name,
		Category: string(*openAPIIngredient.Category),
	}
}

// convertToOpenAPIEvaluation converts model RecipeEvaluation to OpenAPI RecipeEvaluation
func convertToOpenAPIEvaluation(modelEval model.RecipeEvaluation) openapi.RecipeEvaluation {
	openAPIEval := openapi.RecipeEvaluation{
		Scores:    convertToOpenAPIScores(modelEval.Scores),
		TotalCost: modelEval.TotalCost,
	}

	if modelEval.AdjustedScores != nil {
		adjustedScores := convertToOpenAPIScores(*modelEval.AdjustedScores)
		openAPIEval.AdjustedScores = &adjustedScores
	}

	return openAPIEval
}

// convertToOpenAPIScores converts model EvaluationScores to OpenAPI EvaluationScores
func convertToOpenAPIScores(modelScores model.EvaluationScores) openapi.EvaluationScores {
	return openapi.EvaluationScores{
		Umami:       modelScores.Umami,
		Aroma:       modelScores.Aroma,
		Saltiness:   modelScores.Saltiness,
		Fat:         modelScores.Fat,
		Sweetness:   modelScores.Sweetness,
		Spiciness:   modelScores.Spiciness,
		Originality: modelScores.Originality,
		Visual:      modelScores.Visual,
		Volume:      modelScores.Volume,
		Harmony:     modelScores.Harmony,
	}
}

// convertToModelRecipeEvaluation converts OpenAPI RecipeEvaluation to model RecipeEvaluation
func convertToModelRecipeEvaluation(openAPIEval openapi.RecipeEvaluation) model.RecipeEvaluation {
	modelEval := model.RecipeEvaluation{
		Scores:    convertToModelScores(openAPIEval.Scores),
		TotalCost: openAPIEval.TotalCost,
	}

	if openAPIEval.AdjustedScores != nil {
		adjustedScores := convertToModelScores(*openAPIEval.AdjustedScores)
		modelEval.AdjustedScores = &adjustedScores
	}

	return modelEval
}

// convertToModelScores converts OpenAPI EvaluationScores to model EvaluationScores
func convertToModelScores(openAPIScores openapi.EvaluationScores) model.EvaluationScores {
	return model.EvaluationScores{
		Umami:       openAPIScores.Umami,
		Aroma:       openAPIScores.Aroma,
		Saltiness:   openAPIScores.Saltiness,
		Fat:         openAPIScores.Fat,
		Sweetness:   openAPIScores.Sweetness,
		Spiciness:   openAPIScores.Spiciness,
		Originality: openAPIScores.Originality,
		Visual:      openAPIScores.Visual,
		Volume:      openAPIScores.Volume,
		Harmony:     openAPIScores.Harmony,
	}
}

// convertToOpenAPICustomerSatisfaction converts model CustomerSatisfaction to OpenAPI CustomerSatisfaction
func convertToOpenAPICustomerSatisfaction(modelSatisfaction model.CustomerSatisfaction) openapi.CustomerSatisfaction {
	return openapi.CustomerSatisfaction{
		SatisfactionScore: modelSatisfaction.SatisfactionScore,
		WillReturn:        modelSatisfaction.WillReturn,
		PriceAcceptable:   modelSatisfaction.PriceAcceptable,
		EffectiveBudget:   &modelSatisfaction.EffectiveBudget,
		DetailedScores: &struct {
			PriceValue *float32 `json:"priceValue,omitempty"`
			TasteMatch *float32 `json:"tasteMatch,omitempty"`
		}{
			TasteMatch: &modelSatisfaction.DetailedScores.TasteMatch,
			PriceValue: &modelSatisfaction.DetailedScores.PriceValue,
		},
	}
}