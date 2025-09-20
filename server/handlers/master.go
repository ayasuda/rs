package handlers

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/ayasuda/rs/server/model"
)

// Global master data storage
var (
	masterIngredients []model.Ingredient
	masterCustomers   []model.CustomerCategory
)

// LoadMasterData loads both CSV files into memory
func LoadMasterData() error {
	var err error

	masterIngredients, err = model.LoadIngredients("data/ingredients.csv")
	if err != nil {
		return fmt.Errorf("failed to load ingredients: %w", err)
	}
	fmt.Printf("Loaded %d ingredients from CSV\n", len(masterIngredients))

	masterCustomers, err = model.LoadCustomers("data/customers.csv")
	if err != nil {
		return fmt.Errorf("failed to load customers: %w", err)
	}
	fmt.Printf("Loaded %d customer categories from CSV\n", len(masterCustomers))

	return nil
}


// GetMasterIngredients handles GET /master/ingredients
func (s *Server) GetMasterIngredients(c *gin.Context) {
	c.JSON(http.StatusOK, masterIngredients)
}

// GetMasterCustomers handles GET /master/customers
func (s *Server) GetMasterCustomers(c *gin.Context) {
	c.JSON(http.StatusOK, masterCustomers)
}