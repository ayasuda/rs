package main

import (
	"embed"
	"fmt"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/ayasuda/rs/server/handlers"
)

//go:embed openapi_spec.yaml
var openAPISpec embed.FS

func main() {
	// Set Gin mode
	gin.SetMode(gin.ReleaseMode)

	// Create Gin router
	r := gin.New()
	
	// Add middleware
	r.Use(gin.Logger())
	r.Use(gin.Recovery())
	r.Use(corsMiddleware())

	// Create server instance
	server := handlers.NewServer()

	// Setup API routes
	server.SetupRoutes(r)

	// Add OpenAPI spec endpoint
	r.GET("/openapi.yaml", func(c *gin.Context) {
		data, err := openAPISpec.ReadFile("openapi_spec.yaml")
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read OpenAPI spec"})
			return
		}
		c.Data(http.StatusOK, "application/x-yaml", data)
	})

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
			"service": "ramen-simulator-api",
			"version": "1.0.0",
		})
	})

	// Start server
	port := ":8080"
	fmt.Printf("🍜 Ramen Simulator API starting on port %s\n", port)
	fmt.Printf("📖 OpenAPI spec available at: http://localhost%s/openapi.yaml\n", port)
	fmt.Printf("🏥 Health check at: http://localhost%s/health\n", port)
	
	if err := r.Run(port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

// corsMiddleware adds CORS headers to allow frontend access
func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}