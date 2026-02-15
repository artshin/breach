# Gridcrack iOS App Makefile
# Usage:
#   make build          - Build for simulator (Debug)
#   make release        - Build for device (Release)
#   make run            - Run on default simulator
#   make device DEVICE=Daedalus - Build and install on named device
#   make clean          - Clean build artifacts
#   make generate       - Regenerate Xcode project from project.yml

# Project settings
PROJECT := Gridcrack.xcodeproj
SCHEME := Gridcrack
BUNDLE_ID := com.artshin.gridcrack
CONFIGURATION_DEBUG := Debug
CONFIGURATION_RELEASE := Release

# Build directories
BUILD_DIR := $(CURDIR)/build
DERIVED_DATA := $(BUILD_DIR)/DerivedData

# Default simulator
SIMULATOR := iPhone 17 Pro

.PHONY: all build release release-profile run device clean generate list-devices lint lint-fix format format-check quality screenshots generate-backgrounds test help

all: help

# Build for simulator (Debug)
build:
	@echo "Building $(SCHEME) for simulator..."
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION_DEBUG) \
		-sdk iphonesimulator \
		-derivedDataPath $(DERIVED_DATA) \
		build

# Build for device (Release)
release:
	@echo "Building $(SCHEME) for device (Release)..."
	@if [ -f .env ]; then . ./.env; fi; \
	security unlock-keychain -p "$$KEYCHAIN_PASSWORD" ~/Library/Keychains/login.keychain-db 2>/dev/null || true
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION_RELEASE) \
		-sdk iphoneos \
		-derivedDataPath $(DERIVED_DATA) \
		-allowProvisioningUpdates \
		build

# Build for device (Release) with performance analysis
# Generates a markdown report in release-build-analysis/
release-profile:
	@./scripts/analyze-build.sh

# Run on simulator
run: build
	@echo "Running $(SCHEME) on $(SIMULATOR)..."
	@xcrun simctl boot "$(SIMULATOR)" 2>/dev/null || true
	@APP_PATH=$$(find $(DERIVED_DATA) -name "$(SCHEME).app" -path "*Debug-iphonesimulator*" | head -1); \
	if [ -n "$$APP_PATH" ]; then \
		xcrun simctl install booted "$$APP_PATH"; \
		xcrun simctl launch booted $(BUNDLE_ID); \
	else \
		echo "Error: Could not find built app"; \
		exit 1; \
	fi

# Build and install on a named device
# Usage: make device DEVICE=Daedalus
device:
ifndef DEVICE
	$(error DEVICE is not set. Usage: make device DEVICE=<device_name>)
endif
	@echo "Looking for device: $(DEVICE)..."
	@DEVICE_UDID=$$(xcrun xctrace list devices 2>/dev/null | grep "$(DEVICE)" | grep -v Simulator | head -1 | sed -E 's/.*\(([A-F0-9-]+)\)$$/\1/'); \
	if [ -z "$$DEVICE_UDID" ]; then \
		echo "Error: Device '$(DEVICE)' not found. Run 'make list-devices' to see available devices."; \
		exit 1; \
	fi; \
	echo "Found device $(DEVICE) with UDID: $$DEVICE_UDID"; \
	echo "Building $(SCHEME) for device..."; \
	if [ -f .env ]; then . ./.env; fi; \
	security unlock-keychain -p "$$KEYCHAIN_PASSWORD" ~/Library/Keychains/login.keychain-db 2>/dev/null || true; \
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION_DEBUG) \
		-sdk iphoneos \
		-derivedDataPath $(DERIVED_DATA) \
		-allowProvisioningUpdates \
		build; \
	APP_PATH=$$(find $(DERIVED_DATA) -name "$(SCHEME).app" -path "*Debug-iphoneos*" | head -1); \
	if [ -z "$$APP_PATH" ]; then \
		echo "Error: Could not find built app"; \
		exit 1; \
	fi; \
	echo "Installing $$APP_PATH to $(DEVICE)..."; \
	xcrun devicectl device install app --device "$$DEVICE_UDID" "$$APP_PATH"; \
	echo "Launching $(BUNDLE_ID) on $(DEVICE)..."; \
	xcrun devicectl device process launch --device "$$DEVICE_UDID" $(BUNDLE_ID)

# Shortcut for Daedalus device
daedalus:
	@$(MAKE) device DEVICE=Daedalus

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		clean
	rm -rf $(BUILD_DIR)

# Regenerate Xcode project from project.yml (requires xcodegen)
generate:
	@if command -v xcodegen >/dev/null 2>&1; then \
		echo "Regenerating Xcode project..."; \
		xcodegen generate; \
	else \
		echo "Error: xcodegen not found. Install with: brew install xcodegen"; \
		exit 1; \
	fi

# List available devices
list-devices:
	@echo "Available devices:"
	@xcrun xctrace list devices 2>/dev/null | grep -v Simulator | grep -v "^$$"

# List simulators
list-simulators:
	@echo "Available simulators:"
	@xcrun simctl list devices available | grep -E "iPhone|iPad"

# Run unit tests on simulator
test:
	@echo "Running tests..."
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION_DEBUG) \
		-sdk iphonesimulator \
		-derivedDataPath $(DERIVED_DATA) \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		test

# ─── Code Quality ────────────────────────────────────────────────────────────

# Lint with SwiftLint (report only, no changes)
lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		echo "Running SwiftLint..."; \
		swiftlint lint --config .swiftlint.yml; \
	else \
		echo "Error: swiftlint not found. Install with: brew install swiftlint"; \
		exit 1; \
	fi

# Lint and auto-fix what SwiftLint can
lint-fix:
	@if command -v swiftlint >/dev/null 2>&1; then \
		echo "Running SwiftLint autocorrect..."; \
		swiftlint lint --fix --config .swiftlint.yml; \
		echo "Running SwiftLint to show remaining issues..."; \
		swiftlint lint --config .swiftlint.yml; \
	else \
		echo "Error: swiftlint not found. Install with: brew install swiftlint"; \
		exit 1; \
	fi

# Format with SwiftFormat (applies changes)
format:
	@if command -v swiftformat >/dev/null 2>&1; then \
		echo "Running SwiftFormat..."; \
		swiftformat Gridcrack; \
	else \
		echo "Error: swiftformat not found. Install with: brew install swiftformat"; \
		exit 1; \
	fi

# Check formatting without changes (for CI)
format-check:
	@if command -v swiftformat >/dev/null 2>&1; then \
		echo "Checking formatting..."; \
		swiftformat Gridcrack --lint; \
	else \
		echo "Error: swiftformat not found. Install with: brew install swiftformat"; \
		exit 1; \
	fi

# Run all quality checks (no changes, report only)
quality: lint format-check

# ─── Screenshots ─────────────────────────────────────────────────────────────

# Generate AI backgrounds for App Store screenshots (requires GPU + venv)
generate-backgrounds:
	@echo "==> Generating AI backgrounds (SDXL on GPU)..."
	@if [ ! -d scripts/screenshots/.venv ]; then \
		echo "Error: venv not found. Set up with:"; \
		echo "  cd scripts/screenshots && uv venv .venv --python 3.12"; \
		echo "  uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cu128"; \
		echo "  uv pip install diffusers transformers accelerate safetensors"; \
		exit 1; \
	fi
	@scripts/screenshots/.venv/bin/python3 scripts/screenshots/generate_backgrounds.py

# Capture and composite App Store screenshots
screenshots:
	@echo "==> Step 1: Capture raw screenshots from simulators..."
	@bash scripts/screenshots/capture.sh
	@echo ""
	@echo "==> Step 2: Composite final App Store images..."
	@python3 scripts/screenshots/composite.py

# Help
help:
	@echo "Gridcrack iOS App Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make build              - Build for simulator (Debug)"
	@echo "  make release            - Build for device (Release)"
	@echo "  make release-profile    - Release build with performance report"
	@echo "  make run                - Build and run on simulator"
	@echo "  make device DEVICE=Name - Build and install on named device"
	@echo "  make daedalus           - Build and install on Daedalus"
	@echo "  make test               - Run unit tests on simulator"
	@echo "  make clean              - Clean build artifacts"
	@echo "  make generate           - Regenerate Xcode project (xcodegen)"
	@echo "  make list-devices       - List available physical devices"
	@echo "  make list-simulators    - List available simulators"
	@echo ""
	@echo "Code Quality:"
	@echo "  make lint               - Run SwiftLint (report only)"
	@echo "  make lint-fix           - Run SwiftLint with autocorrect"
	@echo "  make format             - Format code with SwiftFormat"
	@echo "  make format-check       - Check formatting (no changes)"
	@echo "  make quality            - Run all checks (lint + format-check)"
	@echo ""
	@echo "Screenshots:"
	@echo "  make generate-backgrounds - Generate AI backgrounds (GPU required)"
	@echo "  make screenshots        - Capture and composite App Store screenshots"
	@echo ""
	@echo "Examples:"
	@echo "  make device DEVICE=Daedalus"
	@echo "  make device DEVICE=\"Artur's iPad\""
