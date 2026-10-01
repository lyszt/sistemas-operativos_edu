MAIN      := main
SRC_DIR   := src
OUTPUT_DIR:= output
PDF       := $(OUTPUT_DIR)/$(MAIN).pdf

.PHONY: all build clean distclean watch open

all: build clean

# Compile the document (handles bibtex/reruns automatically via latexmk)
build:
	latexmk -cd $(SRC_DIR)/$(MAIN).tex

# Re-run on every save
watch:
	latexmk -cd -pvc $(SRC_DIR)/$(MAIN).tex

# Open the compiled PDF (Linux)
open: build
	xdg-open $(PDF)

# Remove auxiliary files, keep the PDF
clean:
	latexmk -cd -c $(SRC_DIR)/$(MAIN).tex

# Remove everything latexmk produced, including the PDF
distclean:
	latexmk -cd -C $(SRC_DIR)/$(MAIN).tex
	rm -rf $(OUTPUT_DIR)
