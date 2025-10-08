# Muze - Unified Music Player

A modern iOS music player that seamlessly integrates Spotify and local audio files into a unified playback experience.

## ✨ Features

- 🎵 **Unified Library**: Browse both Spotify tracks and local audio files in one place
- 📝 **Mixed Playlists**: Create playlists that combine tracks from both sources
- 🎼 **Seamless Playback**: Unified queue that transitions smoothly between Spotify and local files
- ☁️ **iCloud Drive Sync**: Automatic sync of local files across all your devices
- 🎨 **Modern SwiftUI Interface**: Clean, intuitive design built with SwiftUI
- 📱 **On-Demand Downloads**: Files download automatically when needed
- 🔍 **Auto-Discovery**: Automatically finds and imports music from iCloud Drive

## 🚀 Quick Start

### Prerequisites

- macOS with Xcode 15.0+
- iOS 17.0+ target device
- Apple Developer account (for code signing)

### Option 1: Command-Line Setup (Recommended)

```bash
# Run automated setup
./setup.sh

# Build and run
make run
```

### Option 2: Traditional Xcode Setup

1. Open `Muze.xcodeproj` in Xcode
2. Select your development team
3. Build and run (⌘R)

**For detailed setup instructions, see [SETUP.md](SETUP.md)**

## 📁 Architecture

```
Muze/
├── Models/              # Data models (Track, Playlist, PlaybackQueue)
├── Coordinators/        # PlaybackCoordinator (app brain)
├── Services/            # LocalAudioService, SpotifyService, iCloudDriveManager
├── Views/               # SwiftUI views and components
└── Utilities/           # Extensions, constants, logging
```

**Design Pattern**: MVVM + Coordinator

- **PlaybackCoordinator**: Central controller managing playback state
- **Service Layer**: Modular services for audio, Spotify, iCloud
- **Source-Agnostic**: Single Track model works for all sources

**For architecture details, see [DEVELOPMENT.md](DEVELOPMENT.md)**

## 📊 Current Status

### ✅ Completed
- Clean architecture with MVVM + Coordinator pattern
- Complete SwiftUI interface (10+ views)
- Data models (Track, Playlist, TrackSource, PlaybackQueue)
- **iCloud Drive integration with auto-discovery** ✨
- **On-demand file downloading with progress tracking** ✨
- **Metadata extraction from audio files** ✨
- **Local audio playback with AVFoundation** ✨
- **PlaybackCoordinator with service orchestration** ✨
- **Data persistence with SwiftData** ✨
- **Playlist management with storage** ✨

### 🚧 Next Steps
- Spotify SDK integration and OAuth
- Background playback and lock screen controls
- Advanced features (crossfade, EQ, sleep timer)
- Artwork extraction and caching

### 🎵 What Works Now
You have a **fully functional local music player**! You can:
- ✅ Add audio files to iCloud Drive (`Muze/Music/`)
- ✅ Automatically discover and import files with metadata
- ✅ Play local audio files with full playback controls
- ✅ Create and manage playlists (saved with SwiftData)
- ✅ Navigate between tracks with queue management
- ✅ Use shuffle and repeat modes
- ✅ Files download on-demand when played
- ✅ Data persists between app launches

## 📚 Documentation

- **[SETUP.md](SETUP.md)** - Complete setup guide (CLI, GUI, iCloud, configuration)
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Architecture details and implementation roadmap
- **[Makefile](Makefile)** - Build commands reference

## 🛠️ Key Commands

```bash
make help              # Show all available commands
make setup             # First-time project setup
make build             # Build the app
make run               # Build and run on simulator
make clean             # Clean build artifacts
make generate          # Regenerate Xcode project from config
```

## 🧪 Testing with Simulator

The easiest way to test the app is using the iOS Simulator with iCloud:

```bash
# 1. Build and run on simulator (no code signing needed!)
make run

# 2. Sign into iCloud in simulator Settings

# 3. Add test music files
mkdir test_music
cp ~/Music/*.mp3 test_music/
./scripts/add-test-music.sh

# 4. Restart app to see your music!
make run
```

**Benefits:**
- ✅ No Team ID or code signing required
- ✅ Fast iteration and testing
- ✅ Easy file access from your Mac
- ✅ Safe (isolated iCloud container)

See [SETUP.md - Simulator Testing](SETUP.md#simulator-testing-with-icloud) for detailed instructions.

## 🎯 Adding Your Music

### Via iCloud Drive

1. Enable iCloud Drive on your device
2. Open Files app → iCloud Drive
3. Create/navigate to `Muze/Music/` folder
4. Add audio files (MP3, M4A, WAV, FLAC, AIFF)
5. Muze will automatically discover and import them

### Supported Formats

MP3, M4A, AAC, WAV, FLAC, AIFF, CAF

## ⚙️ Configuration

Edit `Muze/Utilities/Constants.swift`:

```swift
// Spotify configuration
enum Spotify {
    static let clientID = "YOUR_CLIENT_ID"
    static let redirectURI = "muze://callback"
}

// iCloud Drive settings
enum iCloud {
    static let containerIdentifier: String? = nil  // or custom container
    static let musicFolderName = "Muze/Music"
    static let autoSyncOnLaunch = true
}
```

## 🔐 Required Capabilities

The app requires these capabilities (configured in entitlements):

- **iCloud → iCloud Documents** (for file sync)
- **Background Modes → Audio** (for background playback)

## 🤝 Contributing

This is a foundational structure ready for extension. Key areas:

- Spotify SDK integration
- Data persistence implementation
- Advanced playback features
- UI/UX improvements

## 📝 License

This project is provided as-is for development purposes.

---

**Version**: 1.0.0  
**Last Updated**: October 8, 2025  
**Minimum iOS**: 17.0  
**Latest**: iCloud integration & local playback complete! 🎉
