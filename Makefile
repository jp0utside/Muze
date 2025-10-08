# Makefile for Muze iOS App
# Makes it easy to build, run, and manage the project from command line

.PHONY: help setup generate clean build run test archive install-tools

# Default target
help:
	@echo "Muze - iOS Music Player"
	@echo ""
	@echo "Available commands:"
	@echo "  make setup          - Install required tools and setup project"
	@echo "  make generate       - Generate Xcode project from project.yml"
	@echo "  make build          - Build the app"
	@echo "  make run            - Build and run on simulator"
	@echo "  make test           - Run tests"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make archive        - Create release archive"
	@echo "  make install-tools  - Install XcodeGen and other tools"
	@echo ""

# Install required command-line tools
install-tools:
	@echo "📦 Installing required tools..."
	@which brew > /dev/null || (echo "❌ Homebrew not found. Install from https://brew.sh" && exit 1)
	@which xcodegen > /dev/null || brew install xcodegen
	@echo "✅ Tools installed"

# Setup project for first time
setup: install-tools
	@echo "🔧 Setting up Muze project..."
	@make generate
	@echo "✅ Project setup complete!"
	@echo ""
	@echo "Next steps:"
	@echo "1. Update DEVELOPMENT_TEAM in project.yml with your Team ID"
	@echo "2. Run 'make build' to build the project"
	@echo "3. Run 'make run' to launch in simulator"

# Generate Xcode project from project.yml
generate:
	@echo "🔨 Generating Xcode project..."
	@xcodegen generate
	@echo "✅ Xcode project generated: Muze.xcodeproj"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf DerivedData/
	@xcodebuild clean -project Muze.xcodeproj -scheme Muze 2>/dev/null || true
	@echo "✅ Clean complete"

# Build the app for simulator
build:
	@echo "🔨 Building Muze..."
	@xcodebuild build \
		-project Muze.xcodeproj \
		-scheme Muze \
		-sdk iphonesimulator \
		-destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
		-configuration Debug \
		| xcpretty || xcodebuild build \
		-project Muze.xcodeproj \
		-scheme Muze \
		-sdk iphonesimulator \
		-destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
		-configuration Debug

# Build and run on simulator
run:
	@echo "🚀 Building and launching Muze..."
	@xcodebuild build \
		-project Muze.xcodeproj \
		-scheme Muze \
		-sdk iphonesimulator \
		-destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
		-configuration Debug \
		-derivedDataPath build \
		| xcpretty || true
	@echo "📱 Starting simulator..."
	@open -a Simulator
	@sleep 3
	@echo "🔍 Finding app bundle..."
	@APP_PATH=$$(find build -name "Muze.app" -type d | head -n 1); \
	if [ -n "$$APP_PATH" ]; then \
		echo "📦 Installing app: $$APP_PATH"; \
		xcrun simctl boot "iPhone 16 Pro" 2>/dev/null || true; \
		xcrun simctl install booted "$$APP_PATH" && \
		echo "🚀 Launching Muze..." && \
		xcrun simctl launch booted com.muze.app; \
	else \
		echo "❌ Could not find Muze.app bundle"; \
		exit 1; \
	fi

# Run tests (when you add them)
test:
	@echo "🧪 Running tests..."
	@xcodebuild test \
		-project Muze.xcodeproj \
		-scheme Muze \
		-sdk iphonesimulator \
		-destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
		| xcpretty || xcodebuild test \
		-project Muze.xcodeproj \
		-scheme Muze \
		-sdk iphonesimulator \
		-destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Create release archive
archive:
	@echo "📦 Creating release archive..."
	@xcodebuild archive \
		-project Muze.xcodeproj \
		-scheme Muze \
		-archivePath build/Muze.xcarchive \
		-configuration Release \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO
	@echo "✅ Archive created at build/Muze.xcarchive"

# List available simulators
list-simulators:
	@echo "📱 Available iOS Simulators:"
	@xcrun simctl list devices iOS | grep "iPhone"

# Open in Xcode (if you need to)
xcode:
	@open Muze.xcodeproj

# Check Swift version
swift-version:
	@swift --version

# Validate project.yml
validate:
	@echo "✅ Validating project configuration..."
	@xcodegen generate --spec project.yml --use-cache false
	@echo "✅ Configuration is valid"

