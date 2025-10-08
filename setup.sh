#!/bin/bash
# Automated setup script for Muze iOS App
# This script sets up the entire project from command line

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          🎵 Muze - Automated Project Setup 🎵              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if Homebrew is installed
check_homebrew() {
    print_info "Checking for Homebrew..."
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew not found!"
        echo ""
        echo "Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    print_success "Homebrew is installed"
}

# Install XcodeGen
install_xcodegen() {
    print_info "Checking for XcodeGen..."
    if ! command -v xcodegen &> /dev/null; then
        print_warning "XcodeGen not found. Installing..."
        brew install xcodegen
        print_success "XcodeGen installed"
    else
        print_success "XcodeGen is already installed"
    fi
}

# Install xcpretty (optional, for prettier build output)
install_xcpretty() {
    print_info "Checking for xcpretty..."
    if ! command -v xcpretty &> /dev/null; then
        print_warning "xcpretty not found. Installing..."
        gem install xcpretty || sudo gem install xcpretty
        print_success "xcpretty installed"
    else
        print_success "xcpretty is already installed"
    fi
}

# Check if Xcode is installed
check_xcode() {
    print_info "Checking for Xcode..."
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode not found!"
        echo ""
        echo "Please install Xcode from the App Store"
        exit 1
    fi
    print_success "Xcode is installed"
    
    # Show Xcode version
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    print_info "Using: $XCODE_VERSION"
}

# Get Apple Developer Team ID
get_team_id() {
    print_info "Getting Apple Developer Team ID..."
    echo ""
    
    # Try to find team ID automatically
    TEAM_ID=$(security find-certificate -a -c "Apple Development" -Z | grep "alis" | head -n 1 | sed 's/.*"\(.*\)".*/\1/' | cut -d '(' -f 2 | cut -d ')' -f 1 || echo "")
    
    if [ -z "$TEAM_ID" ]; then
        print_warning "Could not automatically detect Team ID"
        echo ""
        echo "To find your Team ID:"
        echo "1. Go to https://developer.apple.com/account"
        echo "2. Sign in with your Apple ID"
        echo "3. Look for 'Team ID' in the membership details"
        echo ""
        read -p "Enter your Apple Developer Team ID (or press Enter to skip): " INPUT_TEAM_ID
        
        if [ -z "$INPUT_TEAM_ID" ]; then
            print_warning "No Team ID provided. You'll need to set it manually later."
            TEAM_ID="YOUR_TEAM_ID"
        else
            TEAM_ID="$INPUT_TEAM_ID"
            print_success "Team ID set to: $TEAM_ID"
        fi
    else
        print_success "Found Team ID: $TEAM_ID"
    fi
    
    # Update project.yml with Team ID
    if [ "$TEAM_ID" != "YOUR_TEAM_ID" ]; then
        sed -i '' "s/DEVELOPMENT_TEAM: YOUR_TEAM_ID/DEVELOPMENT_TEAM: $TEAM_ID/" project.yml
        print_success "Updated project.yml with Team ID"
    fi
}

# Generate Xcode project
generate_project() {
    print_info "Generating Xcode project..."
    echo ""
    
    xcodegen generate
    
    if [ -f "Muze.xcodeproj/project.pbxproj" ]; then
        print_success "Xcode project generated successfully!"
    else
        print_error "Failed to generate Xcode project"
        exit 1
    fi
}

# Create .gitignore if it doesn't exist
setup_gitignore() {
    if [ ! -f ".gitignore" ]; then
        print_info "Creating .gitignore..."
        cat > .gitignore << 'EOF'
# Xcode
build/
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata/
*.xccheckout
*.moved-aside
DerivedData/
*.hmap
*.ipa
*.xcuserstate
*.xcodeproj/*
!*.xcodeproj/project.pbxproj
!*.xcodeproj/xcshareddata/

# Swift Package Manager
.build/
Packages/
Package.resolved

# CocoaPods
Pods/

# macOS
.DS_Store

# XcodeGen
Muze.xcodeproj
EOF
        print_success "Created .gitignore"
    fi
}

# Main setup flow
main() {
    echo "Starting automated setup..."
    echo ""
    
    check_homebrew
    echo ""
    
    install_xcodegen
    echo ""
    
    install_xcpretty
    echo ""
    
    check_xcode
    echo ""
    
    get_team_id
    echo ""
    
    generate_project
    echo ""
    
    setup_gitignore
    echo ""
    
    # Success message
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                    ✅ Setup Complete! ✅                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    print_success "Your Muze project is ready!"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  📱 Build the app:"
    echo "     make build"
    echo ""
    echo "  🚀 Run on simulator:"
    echo "     make run"
    echo ""
    echo "  🔨 Open in Xcode (optional):"
    echo "     make xcode"
    echo ""
    echo "  📚 View all commands:"
    echo "     make help"
    echo ""
    print_info "The Xcode project will be regenerated from project.yml"
    print_info "Do not commit Muze.xcodeproj to git - regenerate it instead"
    echo ""
}

# Run main function
main

