PROJECT_NAME = JupSwift

# ANSI colours for nice logs
BLUE  = \033[34m
RESET = \033[0m

.PHONY: help
help:
	@echo "$(BLUE)===== $(PROJECT_NAME) iOS Project Makefile =====$(RESET)"
	@echo "$(BLUE)DOCC COMMANDS:$(RESET)"
	@echo "  make docc-archive        - Generate DocC documentation archive to .docc-build/"
	@echo "  make docc-rendered       - Build HTML docs ready to be hosted."
	@echo "  make preview-docs        - Serve docs locally."
	@echo "  make deploy-docs         - Deploy documentation to GitHub Pages"

# ===========================================
# DocC with swift-docc-render
# ===========================================

# Creates raw DocC HTML without styling or renderer. Not ready for hosting.
.PHONY: docc-archive
docc-archive:
	@echo "$(BLUE)Generating DocC documentation archive...$(RESET)"
	swift package \
	--allow-writing-to-directory ./.docc-build \
	generate-documentation \
	--target $(PROJECT_NAME) \
	--output-path ./.docc-build \
	--transform-for-static-hosting \
	--hosting-base-path $(PROJECT_NAME) \
	--disable-indexing
	@echo "$(BLUE)Documentation archive created at ./.docc-build$(RESET)"

# Creates the raw DocC and copies render assets.
.PHONY: docc-rendered
docc-rendered: docc-archive
	@echo "CWD is: $(shell pwd)"
	@echo "$(BLUE)Copying swift-docc-render assets into .docc-build...$(RESET)"
	cp -a ../swift-docc-render/dist/. .docc-build/
	@echo "$(BLUE)Documentation ready for static hosting with swift-docc-render$(RESET)"

# Show styled docs on a local server
.PHONY: preview-docs
preview-docs: docc-rendered
	@echo "$(BLUE)Serving DocC documentation...$(RESET)"
	@echo "Open your browser to http://localhost:8000/documentation/$(shell echo $(PROJECT_NAME) | tr '[:upper:]' '[:lower:]')"
	cd .docc-build && python3 -m http.server

# Deploy documentation to GitHub Pages
.PHONY: deploy-docs
deploy-docs: docc-rendered
	@echo "$(BLUE)Deploying DocC to GitHub Pages...$(RESET)"
	ghp-import -n -p -f .docc-build
