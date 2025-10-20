# Muze Testing Guide

Complete guide to testing Muze across different environments and configurations.

## 📋 Table of Contents

- [Testing Overview](#testing-overview)
- [Simulator Testing](#simulator-testing)
- [Physical Device Testing](#physical-device-testing)
- [Testing Local Storage](#testing-local-storage)
- [Testing iCloud Integration](#testing-icloud-integration)
- [Testing Spotify Integration](#testing-spotify-integration)
- [Using Files App for Testing](#using-files-app-for-testing)
- [Testing Checklist](#testing-checklist)
- [Troubleshooting](#troubleshooting)

---

## Testing Overview

### Testing Environments

Muze can be tested in several environments, each with different capabilities:

| Environment | Setup Time | Code Signing | iCloud | Best For |
|------------|------------|--------------|--------|----------|
| **Simulator** | 2 min | Not required | Full support | Development & iteration |
| **Device (Local)** | 10 min | Personal Team (free) | Not available | Spotify testing |
| **Device (iCloud)** | 15 min | Paid developer ($99/yr) | Full support | Final testing |

### What to Test Where

| Feature | Simulator | Device (Local) | Device (iCloud) |
|---------|-----------|----------------|-----------------|
| Local Music Playback | ✅ Yes | ✅ Yes | ✅ Yes |
| iCloud Sync | ✅ Yes | ❌ No | ✅ Yes |
| Spotify Integration | ⚠️ Limited | ✅ Yes | ✅ Yes |
| Background Playback | ⚠️ Limited | ✅ Yes | ✅ Yes |
| Audio Quality | ⚠️ Simulated | ✅ Real | ✅ Real |
| Performance | ⚠️ Depends on Mac | ✅ Real | ✅ Real |

**Recommendation**: Use simulator for 90% of development, device for Spotify and final testing.

---

## Simulator Testing

### Quick Start (Recommended for Development)

```bash
# 1. Generate project and build
make run

# 2. Add test music files
make add-music

# 3. Test!
```

### Command-Line Workflow

#### Initial Setup

```bash
# Install tools (first time only)
make setup

# Generate Xcode project
make generate

# Build the app
make build
```

#### Daily Development

```bash
# Build and run on simulator
make run

# The simulator will boot automatically
# App will install and launch
```

#### Available Commands

```bash
make help              # Show all commands
make build             # Build for simulator
make run               # Build and launch
make clean             # Clean build artifacts
make test              # Run unit tests (when added)
make list-simulators   # See available simulators
```

#### Changing Simulator Device

Edit `Makefile` line 64 and 80:
```makefile
-destination 'platform=iOS Simulator,name=iPhone 15 Pro'  # Change device here
```

Or run manually:
```bash
# List available devices
make list-simulators

# Boot specific device
xcrun simctl boot "iPhone SE (3rd generation)"
open -a Simulator

# Then build for it
make build
```

### Xcode Workflow

#### Using Xcode GUI

1. **Open Project**:
   ```bash
   open Muze.xcodeproj
   # Or: make xcode
   ```

2. **Select Simulator**:
   - Top toolbar → Click device selector
   - Choose iPhone/iPad model

3. **Build and Run**:
   - Press `⌘R` or click Play button
   - Simulator launches automatically

4. **Debug**:
   - Set breakpoints in code
   - View console output
   - Inspect variables

#### Xcode Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘R` | Build and run |
| `⌘B` | Build only |
| `⌘.` | Stop running |
| `⌘⇧K` | Clean build folder |
| `⌘⇧O` | Quick open file |
| `⌘L` | Jump to line |

### Testing with iCloud (Simulator)

The simulator supports full iCloud functionality without code signing!

#### Setup iCloud in Simulator

```bash
# 1. Start simulator
make run

# 2. Open Settings app in simulator
# Settings → Sign in to your device → Enter Apple ID

# 3. Enable iCloud Drive
# Settings → [Your Name] → iCloud → Toggle iCloud Drive ON

# 4. Verify app permissions
# Settings → [Your Name] → iCloud → Apps Using iCloud
# Muze should appear in the list
```

**Important**: If Muze doesn't appear in iCloud apps list, your entitlements may be missing. See [Troubleshooting](#troubleshooting).

#### Adding Test Music to iCloud (Simulator)

**Method 1: Helper Script (Easiest)**

```bash
# 1. Create test_music folder and add files
mkdir -p test_music
cp ~/Music/test-song.mp3 test_music/
cp ~/Music/another-song.m4a test_music/

# 2. Run script
make add-music

# Output:
# 🎵 Muze - Add Test Music to Simulator
# ✅ Found booted simulator: ABC123...
# 📋 Copying 2 test music file(s)...
#   ✓ test-song.mp3
#   ✓ another-song.m4a
# ✅ Done!
```

**Method 2: Manual Copy**

```bash
# Find simulator's iCloud path
UDID=$(xcrun simctl list devices | grep "Booted" | grep -oE "[A-F0-9-]{36}" | head -n 1)
ICLOUD_PATH=~/Library/Developer/CoreSimulator/Devices/$UDID/data/Library/Mobile\ Documents/iCloud~com~muze~app/Documents/Muze/Music/

# Copy files
cp ~/Music/*.mp3 "$ICLOUD_PATH"

# Verify
ls -la "$ICLOUD_PATH"
```

**Method 3: Via Finder**

```bash
# Open iCloud folder in Finder
UDID=$(xcrun simctl list devices | grep "Booted" | grep -oE "[A-F0-9-]{36}" | head -n 1)
open ~/Library/Developer/CoreSimulator/Devices/$UDID/data/Library/Mobile\ Documents/iCloud~com~muze~app/Documents/Muze/Music/

# Drag and drop files in Finder
```

#### Verifying iCloud Sync

**Console Logs to Look For**:
```
✅ iCloud Drive is available
📁 Created Muze music folder in iCloud Drive
🔍 Found 3 audio files in iCloud Drive
📥 Imported track: test-song.mp3
```

**Check in App**:
1. Open Library view
2. Tap sync button (☁️🔄)
3. Files should appear
4. Cloud icons indicate iCloud files

---

## Physical Device Testing

### Option 1: Testing Without iCloud (Free Developer Account)

Perfect for testing Spotify integration and basic functionality.

#### Setup

1. **Disable iCloud Capability**:
   ```bash
   # Open in Xcode
   open Muze.xcodeproj
   
   # In Xcode:
   # 1. Select Muze target
   # 2. Signing & Capabilities tab
   # 3. Click "-" next to iCloud to remove it
   ```

2. **Select Personal Team**:
   - Signing & Capabilities
   - Team dropdown → Select your Personal Team

3. **Connect Device and Build**:
   - Connect iPhone/iPad via USB
   - Select device in Xcode toolbar
   - Press `⌘R` to build and run

4. **Trust Developer on Device**:
   - Settings → General → VPN & Device Management
   - Tap your developer certificate
   - Tap "Trust"

#### Adding Test Music (Local Storage)

**Method A: Using Files App** (Easiest!)

File sharing is enabled, so you can use the Files app:

1. Open **Files** app on device
2. Go to **"On My iPhone"** → **"Muze"**
3. Navigate to: **Documents → Muze → Music**
4. Drag music files from iCloud Drive, Dropbox, etc.
5. Files appear immediately in Muze!

See [Using Files App](#using-files-app-for-testing) for details.

**Method B: Using Finder/iTunes**

1. Connect device to Mac
2. Open Finder (macOS Catalina+) or iTunes
3. Select your device
4. Go to Files → Muze
5. Drag music files to Documents folder

**Method C: Helper Script (Simulator Only)**

```bash
# For simulator testing of local storage fallback
make add-music-local
```

#### What Works

| Feature | Status |
|---------|--------|
| Spotify Authentication | ✅ Full support |
| Spotify Playback | ✅ Full support |
| Local Music Playback | ✅ Full support |
| Playlist Management | ✅ Full support |
| iCloud Sync | ❌ Not available |
| Cross-Device Sync | ❌ Not available |

**Console Logs**:
```
⚠️ iCloud Drive not available - using local storage fallback
📁 Created Muze music folder in local storage
```

### Option 2: Testing With iCloud (Paid Developer Account)

Required for testing full iCloud functionality.

#### Requirements

- Apple Developer Program membership ($99/year)
- Paid team ID in Xcode

#### Setup

1. **Update Team in project.yml**:
   ```yaml
   settings:
     DEVELOPMENT_TEAM: ABC123DEF4  # Your paid team ID
   ```

2. **Regenerate and Build**:
   ```bash
   make generate
   # Then build via Xcode to device
   ```

3. **Enable iCloud on Device**:
   - Settings → [Your Name] → iCloud
   - Enable iCloud Drive

4. **Add Test Music**:
   - Use Files app on device
   - Navigate to iCloud Drive → Muze → Music
   - Add files

#### What Works

Everything! Full functionality including:
- ✅ iCloud Drive sync
- ✅ Cross-device sync
- ✅ Spotify integration
- ✅ Background playback
- ✅ All features

---

## Testing Local Storage

Test the app's fallback mode when iCloud is unavailable.

### When to Test Local Storage

- Using Personal Team (free developer account)
- Testing without iCloud entitlement
- Verifying fallback behavior
- Testing on device without iCloud account

### Setup for Local Storage Testing

#### On Simulator

```bash
# 1. Temporarily disable iCloud entitlement
# Comment out iCloud keys in Muze.entitlements

# 2. Clean and rebuild
make clean
make generate
make run

# 3. Add test music to local storage
make add-music-local

# 4. Verify logs show local storage mode
```

#### On Physical Device

```bash
# 1. Remove iCloud capability in Xcode
# (See "Physical Device Testing - Option 1" above)

# 2. Build to device

# 3. Add music via Files app or iTunes
```

### Verifying Local Storage Mode

**Console Logs**:
```
⚠️ iCloud Drive not available - using local storage fallback
📁 Created Muze music folder in local storage: /var/.../Documents/Muze/Music
🔍 Found X audio files in local storage
```

**Storage Locations**:

| Mode | Path |
|------|------|
| iCloud | `iCloud Drive/Muze/Music/` |
| Local | `App Container/Documents/Muze/Music/` |

### Testing Checklist

- [ ] App launches without crashing
- [ ] Local storage path is created
- [ ] Can add music files via Files app
- [ ] Files appear in Library
- [ ] Can play local music
- [ ] Playback controls work
- [ ] Can create playlists
- [ ] Data persists after app restart
- [ ] Spotify still works (if configured)

---

## Testing iCloud Integration

### Prerequisites

- iCloud account signed in
- iCloud Drive enabled
- Proper entitlements configured
- Internet connection

### Testing Scenarios

#### Scenario 1: File Auto-Discovery

```bash
# 1. Start with empty library
# 2. Add files to iCloud Drive/Muze/Music/
# 3. Tap sync button in app
# 4. Verify files appear in library
```

**Expected**:
- Files detected automatically
- Metadata extracted (title, artist, album)
- Files playable immediately

#### Scenario 2: On-Demand Download

```bash
# 1. Add large file to iCloud (not downloaded)
# 2. Tap to play in app
# 3. Watch download progress
# 4. Playback starts automatically
```

**Expected**:
- Download progress indicator
- File plays after download
- File marked as downloaded for offline use

#### Scenario 3: Cross-Device Sync

**Requirements**: Paid developer account, multiple devices

```bash
# Device 1:
# 1. Add files to iCloud via Files app
# 2. Wait for sync

# Device 2:
# 3. Open Muze
# 4. Tap sync button
# 5. Verify same files appear
```

**Expected**:
- Files sync between devices
- Same library on all devices
- Metadata consistent

#### Scenario 4: File Monitoring

```bash
# 1. Open Muze app
# 2. Keep app running
# 3. Add new file to iCloud Drive
# 4. Wait 30 seconds
# 5. Check if file appears without manual sync
```

**Expected** (if file monitoring implemented):
- New files detected automatically
- No manual sync needed

### Monitoring iCloud Sync

**macOS Console App**:
1. Open Console.app
2. Select simulator/device
3. Filter for "cloudd" or "Muze"
4. See real-time sync activity

**Watch Folder Changes**:
```bash
# Monitor iCloud folder in real-time
watch -n 2 'ls -lh ~/Library/Mobile\ Documents/iCloud~com~muze~app/Documents/Muze/Music/ 2>/dev/null'
```

**Check App Logs**:
```
[iCloudDrive] Scanning for audio files...
[iCloudDrive] Found 5 files
[iCloudDrive] File is downloaded: song.mp3
[iCloudDrive] Downloading file: large-file.flac
[iCloudDrive] Download progress: 45%
```

---

## Testing Spotify Integration

### Prerequisites

- Spotify Developer app created
- Client ID configured in Constants.swift
- Spotify app installed on test device
- Spotify account (Premium for playback)

### Setup Spotify Testing

1. **Create Spotify Developer App**:
   - Go to https://developer.spotify.com/dashboard
   - Create app
   - Set redirect URI: `muze://callback`
   - Copy Client ID

2. **Configure Constants**:
   ```swift
   // Muze/Utilities/Constants.swift
   enum Spotify {
       static let clientID = "YOUR_CLIENT_ID"
       static let redirectURI = "muze://callback"
   }
   ```

3. **Build and Test**:
   ```bash
   # Must test on physical device (Spotify SDK limitation)
   # Build via Xcode to device
   ```

### Testing Scenarios

#### Scenario 1: Authentication

1. Open Muze → Settings → Spotify
2. Tap "Sign in with Spotify"
3. Authorize in Safari
4. Redirected back to Muze

**Expected**:
- OAuth flow completes
- Shows "Connected" status
- Displays Spotify username

**Console Logs**:
```
[SpotifyAuth] Starting authentication...
[SpotifyAuth] Authorization successful
[SpotifyAuth] Token obtained
```

#### Scenario 2: Import Liked Songs

1. After authentication, tap "Import Liked Songs"
2. Watch progress indicator
3. Wait for import to complete

**Expected**:
- Progress shows (e.g., "Importing 45/200")
- All liked songs added to library
- Green Spotify icon on tracks
- No duplicates on re-import

**Console Logs**:
```
[SpotifyWebAPI] Fetching liked tracks...
[SpotifyWebAPI] Retrieved 50 tracks (offset 0)
[PlaylistManager] Imported Spotify track: Song Name
```

#### Scenario 3: Spotify Playback

**Prerequisites**:
- Spotify Premium account
- Spotify app installed and logged in

**Important**: Start playback in Spotify app first!

```bash
# On test device:
# 1. Open Spotify app
# 2. Play any song in Spotify
# 3. Keep Spotify running
# 4. Return to Muze
# 5. Try playing a Spotify track
```

**Expected**:
- Track plays through Spotify
- Playback controls work in Muze
- Can pause, skip, seek
- Now Playing updates

**Console Logs**:
```
[SpotifyService] Connecting to Spotify...
[SpotifyService] Connected successfully
[SpotifyService] Starting playback: spotify:track:...
[SpotifyService] Playback started
```

#### Scenario 4: Mixed Playlists

1. Create new playlist
2. Add local tracks
3. Add Spotify tracks
4. Play playlist

**Expected**:
- Both source types in same playlist
- Seamless transition between sources
- Queue shows all tracks
- Correct icons for each source

### Common Spotify Issues

**"Connection refused" or "Can't connect"**:

Solution:
1. Open Spotify app
2. **Play a song in Spotify first** (important!)
3. Keep Spotify running in background
4. Return to Muze and try again

This "primes" the Spotify app's remote control server.

**"Playback failed"**:

Check:
- [ ] Spotify Premium account? (Required)
- [ ] Spotify app logged in?
- [ ] Internet connection active?
- [ ] Played song in Spotify app first?

**"Authentication failed"**:

Check:
- [ ] Correct Client ID in Constants.swift?
- [ ] Redirect URI exactly: `muze://callback`?
- [ ] Same redirect URI in Spotify Dashboard?

---

## Using Files App for Testing

When testing without iCloud capability (local storage mode), the Files app provides easy access.

### Setup

File sharing is already enabled in `Info.plist`:
```xml
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

### Accessing App Files

#### On Device

1. Open **Files** app
2. Tap **Browse** (bottom tab)
3. Tap **"On My iPhone"** (or iPad)
4. Find **"Muze"** folder
5. Navigate: **Documents → Muze → Music**

#### File Operations

**Add Files**:
1. In Files app, navigate to Muze/Music
2. Tap **Select**
3. Drag files from other locations
4. Drop into Music folder

**From Other Apps**:
1. In Safari, Mail, etc.
2. Tap **Share** button
3. Choose **"Save to Files"**
4. Navigate to: On My iPhone → Muze → Documents → Muze → Music
5. Tap **Save**

**Organize**:
1. Create folders for artists/albums
2. Move files between folders
3. Rename files

**Delete**:
1. Long-press file
2. Tap **Delete**

### Supported Formats

All these formats work:
- MP3 (.mp3)
- M4A (.m4a)
- AAC (.aac)
- WAV (.wav)
- FLAC (.flac)
- AIFF (.aiff)
- CAF (.caf)

### Folder Structure

You can organize files in subfolders:
```
Documents/Muze/Music/
├── Artist 1/
│   ├── Album A/
│   │   └── songs...
│   └── Album B/
│       └── songs...
├── Artist 2/
│   └── songs...
└── Various/
    └── songs...
```

The app scans all subdirectories recursively.

### Verifying Files

**Check if files appear in app**:
1. Open Muze
2. Go to Library view
3. Pull down to refresh
4. Files should appear

**Console logs**:
```
📁 Scanning local storage...
🔍 Found 10 audio files
📥 Importing: Artist - Song Name.mp3
✅ Import complete
```

---

## Testing Checklist

### Initial Setup Testing

- [ ] App builds without errors
- [ ] App launches on simulator
- [ ] App launches on device
- [ ] No crash on startup
- [ ] UI loads correctly
- [ ] All tabs accessible

### Local Storage Testing

- [ ] Storage folder created
- [ ] Can add files via Files app
- [ ] Files appear in Library
- [ ] Metadata extracted correctly
- [ ] Local playback works
- [ ] Console shows local storage mode

### iCloud Testing

- [ ] iCloud Drive enabled
- [ ] App appears in iCloud settings
- [ ] Music folder created in iCloud
- [ ] Can add files to iCloud folder
- [ ] Files sync to app
- [ ] On-demand download works
- [ ] Download progress shown
- [ ] Cross-device sync works (if multiple devices)

### Spotify Testing

- [ ] Authentication completes
- [ ] Token stored and refreshed
- [ ] Can import liked songs
- [ ] Import progress shown
- [ ] All tracks imported
- [ ] No duplicates on re-import
- [ ] Can play Spotify tracks
- [ ] Playback controls work
- [ ] Mixed playlists work

### Playback Testing

- [ ] Play button starts playback
- [ ] Pause button works
- [ ] Seek slider works
- [ ] Next track works
- [ ] Previous track works
- [ ] Shuffle works
- [ ] Repeat modes work
- [ ] Queue management works
- [ ] Volume controls work

### Playlist Testing

- [ ] Can create playlist
- [ ] Can add tracks to playlist
- [ ] Can remove tracks from playlist
- [ ] Can reorder tracks
- [ ] Can play playlist
- [ ] Can delete playlist
- [ ] Playlists persist after restart
- [ ] Mixed-source playlists work

### UI/UX Testing

- [ ] All buttons respond
- [ ] Navigation works
- [ ] Search works
- [ ] Pull to refresh works
- [ ] Loading states shown
- [ ] Error messages display
- [ ] Empty states shown
- [ ] Now Playing updates
- [ ] Mini player works
- [ ] Full player works

### Data Persistence Testing

- [ ] Tracks persist after restart
- [ ] Playlists persist after restart
- [ ] Queue state persists
- [ ] Settings persist
- [ ] Playback position remembered
- [ ] Spotify auth token persists

### Performance Testing

- [ ] App launches quickly
- [ ] Scrolling is smooth
- [ ] No lag on track selection
- [ ] Playback starts quickly
- [ ] Search is responsive
- [ ] No memory leaks
- [ ] Works with large libraries (1000+ tracks)

---

## Troubleshooting

### General Issues

#### "App won't build"

```bash
# Clean everything
make clean

# Regenerate project
make generate

# Try building again
make build
```

#### "App crashes on launch"

Check:
- [ ] Console for error messages
- [ ] Info.plist is valid
- [ ] Entitlements file exists
- [ ] All capabilities configured
- [ ] No code signing issues

Solution:
```bash
# Clean rebuild
make clean
xcrun simctl erase booted  # Reset simulator
make run
```

### Simulator Issues

#### "Simulator won't boot"

```bash
# Kill all simulator processes
killall Simulator

# Reset simulator
xcrun simctl erase booted

# Try again
make run
```

#### "Can't find simulator"

```bash
# List available simulators
make list-simulators

# Check if any are booted
xcrun simctl list devices | grep Booted

# Boot manually
xcrun simctl boot "iPhone 16 Pro"
open -a Simulator
```

### iCloud Issues

#### "iCloud Drive not available"

**On Simulator**:
1. Open Settings in simulator
2. Sign in with Apple ID
3. Enable iCloud Drive
4. Wait for sync to complete

**On Device**:
1. Settings → [Your Name] → iCloud
2. Enable iCloud Drive
3. Ensure internet connected

#### "App not in iCloud settings" (Most Common!)

This means entitlements are missing or not applied.

**Solution**:

1. Check entitlements file:
   ```bash
   cat Muze.entitlements
   ```

2. If shows just `<dict/>`, fix it:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
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

3. Clean rebuild:
   ```bash
   xcrun simctl uninstall booted com.muze.app
   make clean
   make generate
   make run
   ```

4. Verify entitlements applied:
   ```bash
   codesign -d --entitlements :- build/Build/Products/Debug-iphonesimulator/Muze.app | grep icloud
   ```

5. Check in Settings → iCloud → Apps Using iCloud → Muze should appear

#### "Files not syncing"

- Wait 30 seconds and retry
- Tap sync button manually
- Check internet connection
- Restart app
- Check Console.app for iCloud errors

#### "Can't add files to iCloud"

- Verify correct path: `iCloud Drive/Muze/Music/`
- Check iCloud storage not full
- Ensure iCloud Drive enabled
- Try adding via different method

### Device Issues

#### "Cannot create provisioning profile"

With iCloud:
- Need paid developer account
- Update Team ID in project.yml

Without iCloud:
- Remove iCloud capability
- Use Personal Team

#### "No music files appear"

Check:
- [ ] Files in correct folder?
- [ ] Pulled to refresh?
- [ ] Console logs show import?
- [ ] File format supported?
- [ ] File not corrupted?

Find storage location in logs:
```
📁 Created Muze music folder: /path/to/storage
```

Browse to that location and verify files exist.

### Spotify Issues

#### "Authentication fails"

Check:
- [ ] Client ID correct in Constants.swift?
- [ ] Redirect URI: `muze://callback` (exact)?
- [ ] Same redirect URI in Spotify Dashboard?
- [ ] Internet connection?

#### "Can't connect to Spotify"

**Solution (90% of cases)**:
1. Open Spotify app
2. **Play any song in Spotify**
3. Keep Spotify running
4. Return to Muze and try again

#### "Playback fails"

Check:
- [ ] Spotify Premium account?
- [ ] Spotify app logged in?
- [ ] Played song in Spotify first?
- [ ] Internet connected?
- [ ] Not using VPN?

### Performance Issues

#### "App is slow"

- Test on physical device (simulator performance varies)
- Check for large library (1000+ tracks)
- Monitor memory usage in Xcode
- Profile with Instruments

#### "Scrolling laggy"

- Reduce image sizes
- Implement lazy loading
- Test on real device
- Check for memory leaks

### Data Issues

#### "Data not persisting"

Check:
- [ ] SwiftData container initialized?
- [ ] ModelContext saving correctly?
- [ ] No errors in console?
- [ ] App not being deleted between tests?

#### "Duplicates appearing"

- Check import logic
- Verify UUID uniqueness
- Look for duplicate file references

### Console Warnings

**"iCloud Drive not available"**:
- Expected in local storage mode
- Otherwise, check iCloud setup

**"Spotify connection refused"**:
- Open Spotify app first
- Play a song in Spotify
- Try again

**"File not found"**:
- File may not be downloaded
- Check download status
- Verify file URL correct

---

## Test Scripts

### Automated Testing (Future)

```bash
# Run unit tests
make test

# Run UI tests
xcodebuild test -scheme MuzeUITests ...

# Run specific test
xcodebuild test -only-testing:MuzeTests/PlaybackTests/testPlayTrack
```

### Performance Testing

```bash
# Profile with Instruments
xcodebuild build-for-testing ...
xcrun xctrace record --template 'Time Profiler' --launch Muze
```

### Manual Test Script

Save as `test-checklist.sh`:

```bash
#!/bin/bash
echo "🧪 Muze Testing Script"
echo ""
echo "Running pre-flight checks..."

# Check if app builds
echo -n "Building app... "
make build &>/dev/null && echo "✅" || echo "❌"

# Check if simulator boots
echo -n "Booting simulator... "
xcrun simctl boot "iPhone 16 Pro" 2>/dev/null && echo "✅" || echo "✅ (already booted)"

# Check if test files exist
echo -n "Test files present... "
[ -d "test_music" ] && echo "✅" || echo "⚠️  (create test_music folder)"

# Check entitlements
echo -n "iCloud entitlements... "
grep -q "icloud-container-identifiers" Muze.entitlements && echo "✅" || echo "❌"

echo ""
echo "✅ Pre-flight complete!"
echo "Run: make run"
```

---

## Summary

### Quick Reference

**Start testing**: `make run`  
**Add test music**: `make add-music`  
**Test Spotify**: Build to device  
**Test iCloud**: Simulator or paid dev device  
**Test local storage**: Remove iCloud capability  

### Test Coverage Priority

1. **High Priority**:
   - App launches
   - Local playback works
   - Spotify authentication
   - Playlist management

2. **Medium Priority**:
   - iCloud sync
   - Download progress
   - Mixed playlists
   - Queue management

3. **Low Priority**:
   - Edge cases
   - Performance optimization
   - Advanced features

### When to Test Where

- **Daily development**: Simulator with `make run`
- **Spotify testing**: Physical device
- **iCloud testing**: Simulator (easiest) or device
- **Final validation**: Physical device with iCloud

---

**Last Updated**: October 20, 2025  
**Version**: 1.0.0  
**Status**: Complete Testing Guide

