###=== Makefile for ramen-simulator project ===###

# Go backend
GO_GEN_DIR=server/gen
OPENAPI_FILE=server/openapi_spec.yaml

generate:
	cd server && go generate ./gen

run-server:
	cd server && go run .

clean:
	rm -rf $(GO_GEN_DIR)

# Docsify documentation (needs `docsify-cli` installed globally)
docs:
	docsify serve

# Unity stub (CLI build example placeholder)
unity-build:
	@echo "(TODO) Unity CLI build command goes here"

help:
	@echo "make generate     - OpenAPIコード生成 (Go)"
	@echo "make run-server   - Goサーバー実行"
	@echo "make docs         - ドキュメントサーバ起動 (docsify)"
	@echo "make unity-build  - Unityビルド (後日追加)"
	@echo "make clean        - 生成ファイル削除"

.PHONY: generate run-server clean docs unity-build help
