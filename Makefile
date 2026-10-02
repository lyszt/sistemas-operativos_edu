SRC_DIR := src
PDF     := $(SRC_DIR)/main.pdf

.PHONY: lint run

# Check Spanish grammar/style on the compiled PDF (via LanguageTool's public API)
# Compile the PDF yourself first (e.g. via VSCode) if $(PDF) doesn't exist yet or is stale.
lint:
	./scripts/lint-grammar.sh $(PDF)

# Start the grammar-watcher web UI (live suggestions on every PDF recompile)
run:
	cd grammar-watcher && npm start
