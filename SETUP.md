# Muze Setup Guide

Complete setup instructions for Muze, covering both command-line and GUI approaches, plus iCloud Drive configuration.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Command-Line Setup](#command-line-setup)
- [Traditional Xcode Setup](#traditional-xcode-setup)
- [iCloud Drive Configuration](#icloud-drive-configuration)
- [Simulator Testing with iCloud](#simulator-testing-with-icloud)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required

- macOS with Xcode 15.0+
- iOS 17.0+ target
- Apple Developer account (for code signing)

### For Command-Line Setup

- Homebrew package manager
- Terminal

### For iCloud Features

- iCloud account
- iCloud Drive enabled

---

## Quick Start

### Automated Setup (Recommended)

```bash
# 1. Run the setup script
./setup.sh

# 2. Build and run
make run
```

That's it! The setup script will:
- Install required tools (XcodeGen)
- Detect your Apple Developer Team ID
- Generate the Xcode project
- Configure everything automatically

---

## Command-Line Setup

### Philosophy

Build and run entirely from the command line without using Xcode's GUI:
- **Configuration files** (`project.yml`, `Makefile`) define the project
- **XcodeGen** generates the Xcode project from config
- **Command-line tools** (`xcodebuild`, `make`) build and run
- **Version control** - track only source files, regenerate project files

### Installation

```bash
# Install XcodeGen
brew install xcodegen

# Optional: prettier output
gem install xcpretty
```

### Manual Setup

```bash
# 1. Generate Xcode project from config
xcodegen generate

# 2. Build the app
make build

# 3. Run on simulator
make run
```

### Available Commands

```bash
make help              # Show all available commands
make setup             # First-time setup
make generate          # Generate/regenerate Xcode project
make build             # Build the app
make run               # Build and run on simulator
make test              # Run tests
make clean             # Clean build artifacts
make archive           # Create release archive
make list-simulators   # List available simulators
make xcode             # Open in Xcode (if needed)
```

### Configuration Files

#### `project.yml` - XcodeGen Configuration

Defines your entire Xcode project:

```yaml
name: Muze
targets:
  Muze:
    type: application
    platform: iOS
    sources:
      - path: Muze
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.muze.app
      DEVELOPMENT_TEAM: YOUR_TEAM_ID  # Update this!
      MARKETING_VERSION: "1.0.0"
    entitlements:
      path: Muze.entitlements
```

**Key settings to customize:**
- `PRODUCT_BUNDLE_IDENTIFIER`: Your app's bundle ID
- `DEVELOPMENT_TEAM`: Your Apple Developer Team ID
- `MARKETING_VERSION`: App version number

#### Finding Your Team ID

**Automatic** (during setup):
```bash
./setup.sh  # Detects team ID automatically
```

**Manual**:
1. Visit https://developer.apple.com/account
2. Find your Team ID in Membership section
3. Update `project.yml`:
   ```yaml
   settings:
     DEVELOPMENT_TEAM: ABC123DEF4  # Your Team ID
   ```
4. Regenerate project:
   ```bash
   make generate
   ```

### Workflow

#### Daily Development

```bash
# 1. Make changes to Swift files in Muze/ directory
vim Muze/Views/ContentView.swift

# 2. Build and run
make run

# 3. Repeat as needed
```

#### After Changing Project Structure

```bash
# If you add/remove files or change settings:
make generate  # Regenerate Xcode project
make build     # Build with new configuration
```

#### Before Committing

```bash
# Verify project can be regenerated
make clean
make generate
make build
```

### Version Control

**✅ Commit:**
- `project.yml` (XcodeGen config)
- `Muze.entitlements` (capabilities)
- `Makefile` (build commands)
- `setup.sh` (setup script)
- `Package.swift` (SPM config)
- All source files (`Muze/*.swift`)
- Documentation (`*.md`)
- `.gitignore`

**❌ Don't Commit:**
- `Muze.xcodeproj/` (generated from project.yml)
- `build/` (build artifacts)
- `DerivedData/` (Xcode cache)
- `.DS_Store` (macOS files)

### Benefits of Command-Line Approach

1. **Version Control Friendly** - No merge conflicts in .xcodeproj files
2. **Reproducible** - Anyone can clone and build
3. **Scriptable** - Easy CI/CD integration
4. **Maintainable** - Configuration in human-readable YAML
5. **Team Friendly** - Everyone uses same configuration

---

## Traditional Xcode Setup

### Step 1: Open Project (2 minutes)

If the Xcode project doesn't exist, generate it first:

```bash
make generate
```

Then:
1. Open `Muze.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Choose a bundle identifier (e.g., `com.yourname.muze`)

### Step 2: Configure Capabilities (3 minutes)

1. Select project in navigator
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **iCloud**:
   - Check ☑️ **iCloud Documents**
   - Use default container or create custom
5. Add **Background Modes**:
   - Check ☑️ **Audio, AirPlay, and Picture in Picture**

### Step 3: Build & Run (1 minute)

1. Select a simulator (iPhone 15 Pro recommended)
2. Press **⌘R** to build and run
3. Explore the interface!

---

## iCloud Drive Configuration

iCloud Drive enables automatic sync of your music library across all devices.

### How It Works

Muze creates a folder in your iCloud Drive:

```
iCloud Drive/
└── Muze/
    └── Music/
        ├── song1.mp3
        ├── song2.m4a
        └── ... (your audio files)
```

**Features:**
- ☁️ **Automatic sync** across all devices
- 📱 **On-demand downloads** - files download when you play them
- 🔄 **Auto-discovery** - new files are detected automatically
- 💾 **Smart storage** - only downloaded files use device storage

### Xcode Setup

#### 1. Enable iCloud Capability

1. Open project in Xcode
2. Select **Muze** target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **iCloud**

#### 2. Configure iCloud Services

In the iCloud capability section:
1. Check ☑️ **iCloud Documents**
2. Choose container:
   - **Default**: `iCloud.$(CFBundleIdentifier)`
   - **Custom**: `iCloud.com.yourname.muze`

#### 3. Verify Entitlements

Your `Muze.entitlements` should include:

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.$(CFBundleIdentifier)</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudDocuments</string>
</array>
```

These are added automatically when you enable the capability.

### User Setup

#### On Device

1. **Enable iCloud Drive**:
   - Settings → [Your Name] → iCloud
   - Enable **iCloud Drive**

2. **Allow Muze Access** (if prompted):
   - Settings → Muze
   - Enable **iCloud Drive**

#### Adding Music Files

**Option 1: Files App (iOS)**
1. Open **Files** app
2. Navigate to **iCloud Drive**
3. Create/navigate to `Muze/Music/` folder
4. Add audio files

**Option 2: Finder (macOS)**
1. Open **Finder**
2. Go to **iCloud Drive** in sidebar
3. Create/navigate to `Muze/Music/` folder
4. Copy audio files into the folder

**Option 3: Drag & Drop (macOS)**
1. Open Finder to iCloud Drive location
2. Drag audio files from any location
3. Drop into `Muze/Music/` folder

### Supported Audio Formats

- **MP3** (.mp3)
- **M4A/AAC** (.m4a)
- **WAV** (.wav)
- **FLAC** (.flac)
- **AIFF** (.aiff)
- **CAF** (.caf)

### Visual Indicators

The app shows file status:
- ☁️ **Cloud icon**: File not downloaded yet
- ⬇️ **Downloading**: File is downloading
- ✓ **Downloaded**: File ready to play offline

---

## Simulator Testing with iCloud

Testing with the iOS Simulator and iCloud is the **easiest and fastest way** to develop and test the app. No device setup, no code signing, and full iCloud functionality!

### Why Use Simulator for Testing?

✅ **Advantages:**
- No Apple Developer Team ID required
- No code signing or certificates needed
- Instant builds and deployment (faster than device)
- Easy file access from your Mac
- Can sign in with your real iCloud account safely
- Separate iCloud container (won't affect your real files)
- Perfect for rapid development and testing

❌ **Limitations:**
- Some hardware features unavailable (camera, sensors)
- Performance different from real device
- Testing final audio quality requires real device

**Recommendation:** Use simulator for 95% of development, switch to real device only for final testing.

### Quick Start

```bash
# 1. Verify entitlements are properly configured (IMPORTANT!)
cat Muze.entitlements | grep "icloud"
# Should show iCloud entitlement keys. If empty, see troubleshooting below.

# 2. Build and run (no Team ID needed!)
make run

# 3. In simulator: Settings → Sign in with Apple ID → Enable iCloud Drive
# (See detailed steps below)

# 4. Verify app appears in iCloud settings
# Settings → [Your Name] → iCloud → Apps Using iCloud → Muze should be listed

# 5. Add test music files
./scripts/add-test-music.sh

# 6. Sync and see your music in the app!
# Tap the cloud sync button (☁️🔄) in Library view
```

**Important:** If the app doesn't appear in iCloud settings, your entitlements file may be empty. See the [Troubleshooting](#troubleshooting) section below.

### Step-by-Step Setup

#### 0. Verify Entitlements (REQUIRED FIRST!)

**Before running the app**, verify the entitlements file is properly configured:

```bash
# Check entitlements file
cat Muze.entitlements
```

**Expected output:**
```xml
<dict>
	<!-- iCloud Documents Access -->
	<key>com.apple.developer.icloud-container-identifiers</key>
	...
</dict>
```

**If you see just `<dict/>`** (empty), the entitlements are missing! Fix it now:

```bash
# The entitlements file should have iCloud keys
# If empty, see the Troubleshooting section for the full content
# Or copy from the template in this document
```

Without proper entitlements, the app **will not** access iCloud Drive and **will not** appear in Settings → iCloud → Apps.

#### 1. Start the Simulator

```bash
# Build and launch the app
make run

# This will:
# - Build for simulator (no signing required)
# - Boot iPhone 16 Pro simulator
# - Install and launch the app
```

Wait for the simulator to boot and the app to launch.

**Check the console logs** for:
```
[LocalAudio] iCloud Drive is available  ✅ Good!
```

or

```
Manual sync failed: notAvailable  ❌ Entitlements missing!
```

#### 2. Sign Into iCloud on Simulator

In the **Simulator** device:

1. Open **Settings** app
2. Tap **Sign in to your iPhone** (at the top)
3. Enter your **Apple ID** and password
4. Complete **2FA** (two-factor authentication) if prompted
   - You'll get the code on your Mac or other devices
   - Enter the code in the simulator

**Is this safe?** Yes! The simulator uses a completely isolated iCloud container. It won't touch your real iCloud files.

Alternatively, you can open Settings directly via command line:

```bash
# Open iOS Settings app in simulator
xcrun simctl openurl booted "prefs:root=APPLE_ACCOUNT"
```

#### 3. Enable iCloud Drive

Still in **Simulator Settings**:

1. Tap your name at the top
2. Tap **iCloud**
3. Toggle **iCloud Drive** to **ON**
4. Wait for it to sync (a few seconds)

You should see "iCloud Drive" with a green checkmark.

#### 4. Verify App Permissions ⚠️ IMPORTANT

After launching Muze with proper entitlements:

1. In simulator Settings → [Your Name] → **iCloud**
2. Scroll down to **Apps Using iCloud**
3. Look for **Muze** in the list
4. Make sure it's toggled **ON**

**If Muze is NOT in the list:**
- ❌ Your entitlements are empty or not applied
- Go to [Troubleshooting](#troubleshooting) section
- Fix the entitlements and rebuild
- The app MUST appear here to access iCloud Drive

#### 5. Add Test Music Files

Now you have two options to add test audio files:

**Option A: Using the Helper Script (Recommended)**

```bash
# 1. Create test_music folder and add some audio files
mkdir -p test_music
cp ~/Music/some-song.mp3 test_music/
cp ~/Music/another-song.m4a test_music/

# 2. Run the helper script
./scripts/add-test-music.sh

# The script will:
# - Find your running simulator
# - Copy files to the simulator's iCloud Drive
# - Show you where files are located
```

**Option B: Manual File Copy**

```bash
# 1. Find your booted simulator's UDID
xcrun simctl list devices | grep "Booted"

# 2. Navigate to simulator's iCloud folder
# Replace [UDID] with your simulator's ID
cd ~/Library/Developer/CoreSimulator/Devices/[UDID]/data/Library/Mobile\ Documents/iCloud~com~muze~app/Documents/Muze/Music/

# 3. Copy test files
cp ~/Music/*.mp3 .
```

#### 6. Test the App

```bash
# Restart the app to trigger iCloud sync
make run
```

In the app:
1. Go to **Library** tab
2. Tap the **iCloud sync button** (☁️🔄) in the top-left
3. You should see your test music files appear!
4. Tap a song to play it

**Check console logs** for success:
```
[LocalAudio] iCloud Drive is available
[LocalAudio] Found 3 audio files in iCloud Drive
[Playlist] Imported track: test-song.mp3
```

**If you see errors**, go to [Troubleshooting](#troubleshooting)

### Helper Script Details

The `scripts/add-test-music.sh` script makes testing super easy:

**What it does:**
- Finds your running simulator automatically
- Creates the iCloud Drive path if needed
- Copies files from `test_music/` folder
- Shows file count and location
- Handles multiple audio formats

**Usage:**

```bash
# Create test_music folder (first time only)
mkdir test_music

# Add some test audio files
cp ~/Music/test-song-1.mp3 test_music/
cp ~/Music/test-song-2.m4a test_music/
cp ~/Downloads/test-audio.wav test_music/

# Run the script
./scripts/add-test-music.sh

# Output:
# 🎵 Muze - Add Test Music to Simulator
# ✅ Found booted simulator: ABC123...
# 📋 Copying 3 test music file(s)...
#   ✓ test-song-1.mp3
#   ✓ test-song-2.m4a
#   ✓ test-audio.wav
# ✅ Done! Copied 3 file(s)
```

**Supported formats:**
- MP3 (.mp3)
- M4A/AAC (.m4a)
- WAV (.wav)
- AAC (.aac)
- FLAC (.flac)
- AIFF (.aiff)
- CAF (.caf)

### Accessing Simulator's iCloud Files

Want to see or modify files directly on your Mac?

**Find the location:**

```bash
# Get booted simulator's UDID
UDID=$(xcrun simctl list devices | grep "Booted" | grep -oE "[A-F0-9]{8}-([A-F0-9]{4}-){3}[A-F0-9]{12}" | head -n 1)

# iCloud Drive location
echo ~/Library/Developer/CoreSimulator/Devices/$UDID/data/Library/Mobile\ Documents/iCloud~com~muze~app/Documents/Muze/Music/

# Open in Finder
open ~/Library/Developer/CoreSimulator/Devices/$UDID/data/Library/Mobile\ Documents/iCloud~com~muze~app/Documents/Muze/Music/
```

**Add to bash profile for easy access:**

```bash
# Add to ~/.bashrc or ~/.zshrc
alias muze-icloud='cd ~/Library/Developer/CoreSimulator/Devices/$(xcrun simctl list | grep Booted | grep -oE "[A-F0-9]{8}-([A-F0-9]{4}-){3}[A-F0-9]{12}" | head -n 1)/data/Library/Mobile\ Documents/iCloud~com~muze~app/Documents/Muze/Music/'

# Usage:
muze-icloud
ls
```

### Monitoring iCloud Sync

**Check Console Logs:**

```bash
# In Xcode console while app is running, you'll see:
# [LocalAudio] iCloud Drive is available
# [LocalAudio] Found 3 audio files in iCloud Drive
# [LocalAudio] Imported track: test-song-1.mp3
```

**Use macOS Console App:**

1. Open **Console.app** on your Mac
2. Select your simulator in the devices list
3. Filter for "cloudd" or "ubiquity"
4. See real-time iCloud sync activity

**Watch the folder:**

```bash
# Monitor file changes in real-time
watch -n 2 'ls -lh ~/Library/Developer/CoreSimulator/Devices/*/data/Library/Mobile\ Documents/iCloud~com~muze~app/Documents/Muze/Music/ 2>/dev/null | tail -20'
```

### Testing Workflow

**Typical development cycle:**

```bash
# 1. Make code changes in your editor

# 2. Build and run
make run

# 3. Add/modify test files
cp ~/Music/new-song.mp3 test_music/
./scripts/add-test-music.sh

# 4. Restart app to see changes
make run

# 5. Check logs for any issues
# (logs appear in terminal)
```

### Resetting Test Environment

**Clear simulator data:**

```bash
# Erase just the booted simulator
xcrun simctl erase booted

# Or erase all simulators
xcrun simctl erase all
```

**Remove test files:**

```bash
# Remove all test music from simulator
rm -rf ~/Library/Developer/CoreSimulator/Devices/*/data/Library/Mobile\ Documents/iCloud~com~muze~app/
```

**Fresh start:**

```bash
# 1. Clean build
make clean

# 2. Erase simulator
xcrun simctl erase booted

# 3. Rebuild
make generate
make run

# 4. Re-sign into iCloud
# (in simulator Settings)

# 5. Add test files
./scripts/add-test-music.sh
```

### Multiple Simulators

You can test with different device types:

```bash
# List available simulators
make list-simulators

# Edit Makefile to change device (line 60, 76)
# Change: 'iPhone 16 Pro' to 'iPhone SE (3rd generation)'

# Or run specific simulator manually
xcrun simctl boot "iPhone SE (3rd generation)"
open -a Simulator
# Then build for that device
```

### Troubleshooting

**"App Not Appearing in iCloud Settings" (MOST COMMON ISSUE)**

This happens when the entitlements file is empty or not properly applied. Follow these steps:

1. **Verify Entitlements File**

```bash
# Check if Muze.entitlements has content
cat Muze.entitlements
```

It should contain iCloud entitlements, NOT just `<dict/>`. If empty, it needs to be fixed.

2. **Fix Empty Entitlements**

If the file shows `<dict/>`, replace the entire contents with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<!-- iCloud Documents Access -->
	<key>com.apple.developer.icloud-container-identifiers</key>
	<array>
		<string>iCloud.$(CFBundleIdentifier)</string>
	</array>
	
	<key>com.apple.developer.ubiquity-container-identifiers</key>
	<array>
		<string>iCloud.$(CFBundleIdentifier)</string>
	</array>
	
	<key>com.apple.developer.icloud-services</key>
	<array>
		<string>CloudDocuments</string>
	</array>
</dict>
</plist>
```

3. **Clean Rebuild**

```bash
# Uninstall old app from simulator
xcrun simctl uninstall booted com.muze.app

# Clean build
make clean

# Regenerate project
xcodegen generate

# Rebuild and run
make run
```

4. **Verify Entitlements Were Applied**

```bash
# Check the built app's entitlements
codesign -d --entitlements :- build/Build/Products/Debug-iphonesimulator/Muze.app | grep "icloud"
```

You should see "icloud" in the output. If not, the entitlements weren't applied.

5. **Check in Simulator**

After launching the app with proper entitlements:
- Settings → [Your Name] → iCloud → Apps Using iCloud
- **Muze** should now appear in the list
- The app will show logs like: `[LocalAudio] iCloud Drive is available`

**"iCloud Drive Not Available" Error in Console**

If you see `Manual sync failed: notAvailable` in logs:
- This means entitlements are missing or not applied
- Follow the steps above to fix entitlements
- The app won't appear in iCloud settings without proper entitlements

**"No Files Appearing in App"**
- Check files are in correct location (use helper script)
- Look at console logs for iCloud errors
- Tap the sync button (☁️🔄) in Library view
- Verify app has iCloud permission (Settings → iCloud → Apps)
- Make sure entitlements are properly applied (see above)

**"Simulator Won't Boot"**
```bash
# Kill all simulator processes
killall Simulator

# Reset simulator
xcrun simctl erase booted

# Try again
make run
```

**"Script Can't Find Simulator"**
```bash
# Check if simulator is running
xcrun simctl list devices | grep Booted

# If nothing, start it:
make run
```

**"Files Not Syncing"**
- iCloud sync in simulator can take a few seconds
- Restart the app after adding files
- Check Console.app for iCloud errors
- Verify internet connection (simulator uses Mac's connection)

### Comparison: Simulator vs Real Device

| Feature | Simulator | Real Device |
|---------|-----------|-------------|
| Setup Time | 2 minutes | 10-15 minutes |
| Code Signing | Not required | Required |
| Team ID Needed | No | Yes |
| Build Speed | Fast | Slower |
| iCloud Access | Full support | Full support |
| File Management | Easy (Mac filesystem) | Via Files app only |
| Audio Quality | Simulated | Real hardware |
| Performance | Depends on Mac | Real device speed |
| Background Audio | Limited | Full support |
| Best For | Development & testing | Final testing & production |

**When to use simulator:**
- All development and testing (95% of the time)
- Rapid iteration on features
- Testing iCloud sync
- UI/UX development
- Debugging

**When to use real device:**
- Final audio quality testing
- Background playback testing
- Performance validation
- Pre-release testing
- App Store screenshots

---

## Configuration

### App Constants

Edit `Muze/Utilities/Constants.swift`:

#### Spotify Settings

```swift
enum Spotify {
    static let clientID = "YOUR_SPOTIFY_CLIENT_ID"
    static let redirectURI = "muze://callback"
}
```

To get Spotify credentials:
1. Visit [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Create a new app
3. Copy Client ID
4. Set redirect URI to `muze://callback`

#### iCloud Settings

```swift
enum iCloud {
    // Container identifier (nil = default)
    static let containerIdentifier: String? = nil
    
    // Folder name in iCloud Drive
    static let musicFolderName = "Muze/Music"
    
    // Auto-sync on app launch
    static let autoSyncOnLaunch = true
    
    // Background sync interval (minutes)
    static let syncIntervalMinutes: TimeInterval = 30
}
```

#### Audio Settings

```swift
enum Audio {
    static let supportedLocalFormats = [
        "mp3", "m4a", "wav", "aac",
        "flac", "aiff", "caf"
    ]
}
```

### Bundle Identifier

**Via project.yml** (command-line):
```yaml
settings:
  base:
    PRODUCT_BUNDLE_IDENTIFIER: com.yourname.muze
```
Then run: `make generate`

**Via Xcode** (GUI):
1. Select project → General
2. Change Bundle Identifier
3. Update iCloud container if using custom identifier

### Deployment Target

**Via project.yml**:
```yaml
deploymentTarget:
  iOS: "17.0"  # Change to your minimum iOS version
```

**Via Xcode**:
1. Select project → General
2. Change Minimum Deployments

---

## Troubleshooting

### Command-Line Issues

#### "xcodegen: command not found"
```bash
brew install xcodegen
```

#### "No such file: Muze.xcodeproj"
```bash
make generate  # Generate the project first
```

#### "Signing requires a development team"
Edit `project.yml` and add your Team ID:
```yaml
settings:
  DEVELOPMENT_TEAM: ABC123DEF4  # Your Team ID
```
Then: `make generate && make build`

#### Build Fails After Changing project.yml
```bash
make clean
make generate
make build
```

### iCloud Issues

#### "iCloud Drive Not Available"
**Solution:**
- Settings → [Your Name] → iCloud
- Ensure iCloud Drive is enabled
- Sign in to iCloud if needed

#### Files Not Appearing
**Solution:**
- Verify files are in `iCloud Drive/Muze/Music/`
- Pull to refresh in app
- Wait for automatic sync (up to 30 minutes)
- Manually trigger sync in app settings

#### Playback Fails
**Solution:**
- Check internet connection
- Ensure sufficient iCloud storage
- Verify file format is supported
- Check that file isn't corrupted

#### Files Not Syncing Between Devices
**Solution:**
- Check internet connection on both devices
- Verify same iCloud account on both devices
- Ensure iCloud storage isn't full
- Force quit and reopen Muze

### General Issues

#### "Cannot find PlaybackCoordinator in scope"
- Ensure all files are added to target in Xcode
- Clean build folder (⌘⇧K)
- Rebuild project

#### Simulator Won't Boot
```bash
xcrun simctl shutdown all
xcrun simctl erase all
```

#### Build Succeeds but App Crashes
- Check Console for error messages
- Verify Info.plist is properly configured
- Ensure all capabilities are enabled
- Test on physical device if simulator issues persist

---

## Next Steps

Once setup is complete:

1. **Add Music**: Drop audio files into `iCloud Drive/Muze/Music/`
2. **Test Playback**: Launch app and try playing tracks
3. **Create Playlists**: Organize your music
4. **Explore Code**: See [DEVELOPMENT.md](DEVELOPMENT.md) for architecture details

---

## Additional Resources

- [XcodeGen Documentation](https://github.com/yonaskolb/XcodeGen)
- [xcodebuild Man Page](https://developer.apple.com/library/archive/technotes/tn2339/)
- [iCloud for Developers](https://developer.apple.com/icloud/)
- [AVFoundation Guide](https://developer.apple.com/av-foundation/)
- [Spotify iOS SDK](https://developer.spotify.com/documentation/ios/)

---

## 🎉 Current Features

As of the latest update, **you have a fully functional local music player!**

### ✅ Working Now

✅ **Add music** to `iCloud Drive/Muze/Music/`  
✅ **Automatic discovery** - Files are found and imported automatically  
✅ **Play local audio** - Full playback controls working  
✅ **On-demand downloads** - iCloud files download when you play them  
✅ **View metadata** - Title, artist, album, duration, genre extracted  
✅ **Manage playlists** - Create and organize (saved with SwiftData!)  
✅ **Queue navigation** - Next, previous, shuffle, repeat modes  
✅ **Data persistence** - Everything saved between app launches  

### ⏳ Coming Soon

- Spotify integration (OAuth and playback)
- Background playback
- Lock screen controls
- Artwork extraction and caching
- Advanced features (crossfade, EQ, sleep timer)

---

**Last Updated**: October 8, 2025  
**Status**: ✅ Ready to Use  
**Latest**: Local playback & iCloud Drive fully functional!

