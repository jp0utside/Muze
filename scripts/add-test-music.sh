#!/bin/bash
# Add test music files to simulator's iCloud Drive
# This script helps you easily add test audio files for development

set -e

echo "🎵 Muze - Add Test Music to Simulator"
echo ""

# Find booted simulator's UDID
BOOTED_UDID=$(xcrun simctl list devices | grep "Booted" | grep -oE "[A-F0-9]{8}-([A-F0-9]{4}-){3}[A-F0-9]{12}" | head -n 1)

if [ -z "$BOOTED_UDID" ]; then
    echo "❌ No booted simulator found"
    echo ""
    echo "Please start the simulator first:"
    echo "  make run"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "✅ Found booted simulator: $BOOTED_UDID"
echo ""

# Construct iCloud path
ICLOUD_BASE=~/Library/Developer/CoreSimulator/Devices/$BOOTED_UDID/data/Library/Mobile\ Documents
ICLOUD_PATH="$ICLOUD_BASE/iCloud~com~muze~app/Documents/Muze/Music"

# Check if iCloud directory exists (means app has been run at least once)
if [ ! -d "$ICLOUD_BASE" ]; then
    echo "⚠️  iCloud directory not found for simulator"
    echo ""
    echo "The app needs to run at least once to create the iCloud container."
    echo "Please run:"
    echo "  make run"
    echo ""
    echo "Wait for the app to launch, then run this script again."
    exit 1
fi

# Create the Muze/Music directory if it doesn't exist
mkdir -p "$ICLOUD_PATH"
echo "📁 iCloud Music folder: $ICLOUD_PATH"
echo ""

# Check if test_music directory exists
if [ ! -d "test_music" ]; then
    echo "📂 No 'test_music' folder found in project directory"
    echo ""
    echo "Creating test_music folder for you..."
    mkdir test_music
    echo "✅ Created test_music/ directory"
    echo ""
    echo "Please add some audio files to test_music/ folder:"
    echo "  cp ~/Music/*.mp3 test_music/"
    echo "  cp ~/Music/*.m4a test_music/"
    echo ""
    echo "Supported formats: mp3, m4a, wav, aac, flac, aiff, caf"
    echo ""
    echo "Then run this script again to copy them to the simulator."
    exit 0
fi

# Count files in test_music
TEST_FILE_COUNT=$(ls -1 test_music/*.{mp3,m4a,wav,aac,flac,aiff,caf} 2>/dev/null | wc -l | tr -d ' ')

if [ "$TEST_FILE_COUNT" -eq "0" ]; then
    echo "📂 test_music/ folder is empty"
    echo ""
    echo "Please add some audio files:"
    echo "  cp ~/Music/*.mp3 test_music/"
    echo "  cp ~/Music/*.m4a test_music/"
    echo ""
    echo "Supported formats: mp3, m4a, wav, aac, flac, aiff, caf"
    exit 1
fi

# Copy test files
echo "📋 Copying $TEST_FILE_COUNT test music file(s)..."
echo ""

COPIED=0
for ext in mp3 m4a wav aac flac aiff caf; do
    for file in test_music/*.$ext; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            cp "$file" "$ICLOUD_PATH/"
            echo "  ✓ $filename"
            COPIED=$((COPIED + 1))
        fi
    done
done

echo ""
echo "✅ Done! Copied $COPIED file(s) to simulator's iCloud Drive"
echo ""
echo "📍 Location: $ICLOUD_PATH"
echo ""

# List current files
TOTAL_FILES=$(ls -1 "$ICLOUD_PATH" 2>/dev/null | wc -l | tr -d ' ')
echo "📊 Total files in simulator's iCloud: $TOTAL_FILES"
echo ""

# Show the files
if [ "$TOTAL_FILES" -gt "0" ]; then
    echo "Current files:"
    ls -1 "$ICLOUD_PATH" | sed 's/^/  • /'
    echo ""
fi

echo "🔄 Now restart the app to scan for new files:"
echo "  make run"
echo ""
echo "Or if app is already running, pull to refresh in the Library view."

