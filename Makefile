###=== Makefile for ramen-simulator project ===###

# Docsify documentation (needs `docsify-cli` installed globally)
docs:
	docsify serve

help:
	@echo "make docs         - ドキュメントサーバ起動 (docsify)"

.PHONY: docs help
