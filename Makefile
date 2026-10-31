# Makefile for MacStatus
# A native macOS Apple Silicon hardware status monitor

SHELL := /bin/bash
APP_NAME := MacStatus
EXECUTABLE_NAME := MacStatusApp
BUILD_DIR := build
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
INSTALL_DIR ?= /Applications

.PHONY: all build release test run app install uninstall clean icon help

# Default target
all: build

## build: Build the debug binary using Swift Package Manager
build:
	@echo "==> Building $(EXECUTABLE_NAME) (debug)..."
	@swift build

## release: Build the optimized release binary
release:
	@echo "==> Building $(EXECUTABLE_NAME) (release)..."
	@swift build -c release

## test: Run all unit and component tests
test:
	@echo "==> Running tests..."
	@swift test

## run: Build and run the app directly from SPM
run:
	@echo "==> Running $(EXECUTABLE_NAME)..."
	@swift run $(EXECUTABLE_NAME)

## app: Package the release build into MacStatus.app bundle with icons and Info.plist
app:
	@echo "==> Packaging $(APP_NAME).app..."
	@./scripts/build-app.sh

## icon: Generate AppIcon assets (AppIcon.icns & AppIcon.png)
icon:
	@echo "==> Generating native app icon..."
	@swift scripts/generate-icon.swift

## install: Install MacStatus.app to $(INSTALL_DIR)
install: app
	@echo "==> Installing $(APP_NAME).app to $(INSTALL_DIR)..."
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@cp -R "$(APP_BUNDLE)" "$(INSTALL_DIR)/"
	@echo "==> Successfully installed to $(INSTALL_DIR)/$(APP_NAME).app"

## uninstall: Remove MacStatus.app from $(INSTALL_DIR)
uninstall:
	@echo "==> Removing $(APP_NAME).app from $(INSTALL_DIR)..."
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "==> Uninstalled."

## clean: Remove build artifacts and temporary files
clean:
	@echo "==> Cleaning build artifacts..."
	@swift package clean
	@rm -rf $(BUILD_DIR) .build
	@echo "==> Clean complete."

## help: Show this help message
help:
	@echo "MacStatus Build Commands:"
	@echo ""
	@sed -n 's/^## //p' $(MAKEFILE_LIST) | column -t -s ':'

