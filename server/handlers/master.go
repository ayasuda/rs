package handlers

import (
	"encoding/csv"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
)

// MasterIngredient represents an ingredient from the master data
type MasterIngredient struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Category string `json:"category"`
}

// MasterCustomer represents a customer category from the master data
type MasterCustomer struct {
	ID             int      `json:"id"`
	Name           string   `json:"name"`
	BaseBudget     int      `json:"baseBudget"`
	TimeSlots      []string `json:"timeSlots"`
	Characteristics []string `json:"characteristics"`
}

// Global master data storage
var (
	masterIngredients []MasterIngredient
	masterCustomers   []MasterCustomer
)

// LoadMasterData loads both CSV files into memory
func LoadMasterData() error {
	if err := loadIngredients(); err != nil {
		return fmt.Errorf("failed to load ingredients: %w", err)
	}
	
	if err := loadCustomers(); err != nil {
		return fmt.Errorf("failed to load customers: %w", err)
	}
	
	return nil
}

// loadIngredients loads ingredients from CSV file
func loadIngredients() error {
	file, err := os.Open("data/ingredients.csv")
	if err != nil {
		return err
	}
	defer file.Close()

	reader := csv.NewReader(file)
	records, err := reader.ReadAll()
	if err != nil {
		return err
	}

	// Skip header row and parse data
	masterIngredients = make([]MasterIngredient, 0, len(records)-1)
	for i, record := range records {
		if i == 0 { // Skip header
			continue
		}
		
		if len(record) != 3 {
			return fmt.Errorf("invalid ingredient record at line %d: expected 3 fields, got %d", i+1, len(record))
		}

		ingredient := MasterIngredient{
			ID:       strings.TrimSpace(record[0]),
			Name:     strings.TrimSpace(record[1]),
			Category: strings.TrimSpace(record[2]),
		}
		masterIngredients = append(masterIngredients, ingredient)
	}

	fmt.Printf("Loaded %d ingredients from CSV\n", len(masterIngredients))
	return nil
}

// loadCustomers loads customer categories from CSV file
func loadCustomers() error {
	file, err := os.Open("data/customers.csv")
	if err != nil {
		return err
	}
	defer file.Close()

	reader := csv.NewReader(file)
	records, err := reader.ReadAll()
	if err != nil {
		return err
	}

	// Skip header row and parse data
	masterCustomers = make([]MasterCustomer, 0, len(records)-1)
	for i, record := range records {
		if i == 0 { // Skip header
			continue
		}
		
		if len(record) != 5 {
			return fmt.Errorf("invalid customer record at line %d: expected 5 fields, got %d", i+1, len(record))
		}

		id, err := strconv.Atoi(strings.TrimSpace(record[0]))
		if err != nil {
			return fmt.Errorf("invalid customer ID at line %d: %w", i+1, err)
		}

		baseBudget, err := strconv.Atoi(strings.TrimSpace(record[2]))
		if err != nil {
			return fmt.Errorf("invalid base budget at line %d: %w", i+1, err)
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

		customer := MasterCustomer{
			ID:              id,
			Name:            strings.TrimSpace(record[1]),
			BaseBudget:      baseBudget,
			TimeSlots:       timeSlots,
			Characteristics: characteristics,
		}
		masterCustomers = append(masterCustomers, customer)
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