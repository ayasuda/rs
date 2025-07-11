//go:generate oapi-codegen -config oapi-codegen.yaml openapi_spec.yaml
package main

import (
//  "github.com/deepmap/oapi-codegen/pkg/gin-middleware"
  "github.com/gin-gonic/gin"
  "log"
)

type DummyHandler struct{}

func (d *DummyHandler) PostRecipes(c *gin.Context) {
  c.String(200, "レシピ作成API")
}

func (d *DummyHandler) GetRecipesIdEvaluate(c *gin.Context, id string) {
  c.String(200, "評価API for ID: %s", id)
}

func (d *DummyHandler) GetCustomers(c *gin.Context) {
  c.String(200, "顧客一覧API")
}

func (d *DummyHandler) PostMatch(c *gin.Context) {
  c.String(200, "マッチングAPI")
}

func runServer() {
  //spec, err := GetSwagger()
  //if err != nil {
  //  log.Fatalf("OpenAPI仕様の読み込みに失敗: %v", err)
  //}

  r := gin.Default()

  // OpenAPIバリデーションミドルウェア
  //r.Use(middleware.OapiRequestValidator(spec))

  // 生成されたルーティングに登録
  RegisterHandlers(r, &DummyHandler{})

  log.Println("http://localhost:8080 で待機中...")
  log.Fatal(r.Run(":8080"))
}

