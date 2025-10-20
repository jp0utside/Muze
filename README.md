# Muze - Unified Music Player

A modern iOS music player that seamlessly integrates Spotify and local audio files into a unified playback experience.

## ✨ Features

### 🎵 Unified Music Library
- **Mixed Sources**: Browse Spotify tracks and local audio files in one library
- **Unified Playback**: Seamless transitions between Spotify and local files
- **Smart Organization**: Filter by source, search across all tracks
- **Rich Metadata**: Title, artist, album, duration, genre, artwork

### 📝 Flexible Playlists
- **Mixed-Source Playlists**: Combine Spotify and local tracks in the same playlist
- **Queue Management**: Full control with shuffle and repeat modes
- **Persistent State**: All playlists and queue state saved automatically
- **Easy Organization**: Create, edit, and manage playlists effortlessly

### ☁️ iCloud Drive Integration
- **Automatic Sync**: Music files sync across all your devices
- **Auto-Discovery**: New files detected and imported automatically
- **On-Demand Downloads**: Files download only when needed
- **Smart Storage**: Only downloaded files use device storage
- **Local Fallback**: Works without iCloud (device-local storage)

### 🎼 Spotify Integration
- **OAuth Authentication**: Secure login with your Spotify account
- **Import Liked Songs**: Import all your Spotify favorites
- **Full Playback Control**: Play, pause, seek, skip through Spotify tracks
- **No Duplicates**: Smart detection prevents duplicate imports
- **Unified Experience**: Spotify tracks work just like local files

### 🎨 Modern Interface
- **SwiftUI Design**: Clean, native iOS interface
- **Dark Mode**: Full dark mode support
- **Smooth Animations**: Polished transitions and interactions
- **Mini Player**: Persistent mini player for quick access
- **Full Player**: Beautiful full-screen player with artwork

## 🚀 Quick Start

### Prerequisites

- macOS with Xcode 15.0+
- iOS 17.0+ device or simulator
- Apple Developer account (for code signing)
- Optional: Spotify account for Spotify integration

### Installation

#### Option 1: Command-Line Setup (Recommended)

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/muze.git
cd muze

# 2. Run automated setup
./setup.sh

# 3. Build and run on simulator
make run
```

#### Option 2: Xcode Setup

```bash
# 1. Generate Xcode project
make generate

# 2. Open in Xcode
open Muze.xcodeproj

# 3. Select your development team in Signing & Capabilities
# 4. Build and run (⌘R)
```

### First Launch

1. **Enable iCloud** (optional but recommended):
   - Simulator: Settings → Sign in → Enable iCloud Drive
   - Device: Settings → [Your Name] → iCloud → Enable iCloud Drive

2. **Connect Spotify** (optional):
   - Open Muze → Settings → Spotify
   - Sign in with your Spotify account
   - Import your liked songs

3. **Add Music**:
   - Add audio files to `iCloud Drive/Muze/Music/` folder
   - Or use the Files app on device to add to local storage
   - Files appear automatically in your library

## 📱 Using Muze

### Adding Music

#### Via iCloud Drive

1. Open **Files** app on iOS or **Finder** on macOS
2. Navigate to **iCloud Drive**
3. Create/navigate to `Muze/Music/` folder
4. Add your audio files (MP3, M4A, FLAC, WAV, etc.)
5. Files appear automatically in Muze

#### Via Local Storage (No iCloud)

1. Open **Files** app on your device
2. Go to **"On My iPhone"** → **"Muze"**
3. Navigate to **Documents → Muze → Music**
4. Add files by dragging from other locations or using Share Sheet
5. Files appear immediately in Muze

#### Supported Audio Formats

- **MP3** (.mp3)
- **M4A/AAC** (.m4a, .aac)
- **WAV** (.wav)
- **FLAC** (.flac) - Lossless
- **AIFF** (.aiff)
- **CAF** (.caf)

### Connecting Spotify

1. **Create Spotify Developer App**:
   - Visit [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard)
   - Create new app
   - Set redirect URI: `muze://callback`
   - Copy your Client ID

2. **Configure Muze**:
   - Edit `Muze/Utilities/Constants.swift`
   - Add your Client ID:
     ```swift
     enum Spotify {
         static let clientID = "YOUR_CLIENT_ID_HERE"
         static let redirectURI = "muze://callback"
     }
     ```

3. **Connect in App**:
   - Open Muze → Settings → Spotify
   - Tap "Sign in with Spotify"
   - Authorize in Safari
   - Tap "Import Liked Songs"

**Requirements for Playback**:
- Spotify app installed on device
- Spotify Premium account (SDK requirement)
- Internet connection

For detailed Spotify setup, see [DEVELOPMENT.md](DEVELOPMENT.md).

### Creating Playlists

1. **Create Playlist**:
   - Go to **Playlists** tab
   - Tap **"+"** button
   - Enter name and description
   - Tap **Save**

2. **Add Tracks**:
   - Open playlist
   - Tap **"Add Tracks"**
   - Select tracks (from any source)
   - Tap **Done**

3. **Play Playlist**:
   - Tap any track to start
   - Use shuffle and repeat as desired
   - Queue shows all tracks

### Playback Controls

- **Play/Pause**: Tap play button
- **Next/Previous**: Swipe or tap skip buttons
- **Seek**: Drag progress slider
- **Shuffle**: Tap shuffle button to toggle
- **Repeat**: Tap repeat button (Off → All → One)
- **Queue**: View upcoming tracks

### Library Management

- **Search**: Use search bar to find tracks
- **Filter**: Tap filter button to show local or Spotify only
- **Sort**: Sort by name, artist, or date added
- **Delete**: Swipe left on track to remove

## 🛠️ Configuration

### App Settings

Edit `Muze/Utilities/Constants.swift`:

#### Spotify Configuration

```swift
enum Spotify {
    static let clientID = "YOUR_SPOTIFY_CLIENT_ID"
    static let redirectURI = "muze://callback"
    
    static let scopes = [
        "user-read-playback-state",
        "user-modify-playback-state",
        "user-read-currently-playing",
        "app-remote-control",
        "streaming",
        "user-library-read"
    ]
}
```

#### iCloud Settings

```swift
enum iCloud {
    // Container identifier (nil = default)
    static let containerIdentifier: String? = nil
    
    // Folder name in iCloud Drive
    static let musicFolderName = "Muze/Music"
    
    // Auto-sync on app launch
    static let autoSyncOnLaunch = true
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
  PRODUCT_BUNDLE_IDENTIFIER: com.yourname.muze
  DEVELOPMENT_TEAM: YOUR_TEAM_ID
```

Then run: `make generate`

**Via Xcode** (GUI):
1. Select project → General tab
2. Change Bundle Identifier
3. Select your Development Team

## 📋 Build Commands

### Make Commands

```bash
make help              # Show all available commands
make setup             # First-time project setup
make generate          # Regenerate Xcode project
make build             # Build the app
make run               # Build and run on simulator
make clean             # Clean build artifacts
make test              # Run unit tests
make list-simulators   # List available simulators
```

### Xcode Commands

- **Build**: `⌘B`
- **Run**: `⌘R`
- **Stop**: `⌘.`
- **Clean**: `⌘⇧K`
- **Test**: `⌘U`

## 📖 Documentation

- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Architecture, design decisions, and development roadmap
- **[TESTING.md](TESTING.md)** - Complete testing guide for all environments

## 📊 Project Status

### ✅ Completed Features

#### Core Functionality
- ✅ Clean MVVM + Coordinator architecture
- ✅ Complete SwiftUI interface (11 views)
- ✅ Data models (Track, Playlist, PlaybackQueue, TrackSource)
- ✅ SwiftData persistence

#### Local Audio
- ✅ iCloud Drive integration with auto-discovery
- ✅ Local storage fallback (works without iCloud)
- ✅ On-demand file downloading with progress
- ✅ Metadata extraction from audio files
- ✅ Local audio playback with AVFoundation
- ✅ File sharing via Files app

#### Spotify Integration
- ✅ OAuth authentication with PKCE
- ✅ Spotify liked songs import
- ✅ Spotify playback via App Remote
- ✅ Web API integration
- ✅ Token management and refresh

#### Playback & Organization
- ✅ PlaybackCoordinator with service orchestration
- ✅ Unified queue management
- ✅ Shuffle and repeat modes
- ✅ Mixed-source playlists
- ✅ Playlist management with storage

### 🚧 Planned Features

- Background playback and lock screen controls
- Artwork extraction and caching
- Advanced playback features (crossfade, EQ, sleep timer)
- Playlist sharing and export
- Lyrics support

### 📈 Progress

**Overall**: ~85% complete for full-featured MVP

| Feature Category | Status |
|-----------------|--------|
| Architecture | ✅ 100% |
| Local Audio Playback | ✅ 100% |
| iCloud Drive Sync | ✅ 100% |
| Spotify Integration | ✅ 100% |
| Playlist Management | ✅ 100% |
| Data Persistence | ✅ 100% |
| UI/UX | ✅ 100% |
| Background Playback | ⏳ 0% |
| Lock Screen Controls | ⏳ 0% |
| Advanced Features | ⏳ 0% |

## 🏗️ Architecture Overview

### Design Pattern: MVVM + Coordinator

```
Views (SwiftUI)
    ↓
PlaybackCoordinator (Business Logic)
    ↓
Services (LocalAudioService, SpotifyService, iCloudDriveManager)
    ↓
Models (Track, Playlist, PlaybackQueue)
```

### Key Components

- **Models**: Track, Playlist, PlaybackQueue, TrackSource
- **Coordinators**: PlaybackCoordinator (central controller)
- **Services**: LocalAudioService, SpotifyService, iCloudDriveManager, PlaylistManager
- **Views**: 11 SwiftUI views with reusable components
- **Utilities**: Constants, Extensions, Logger

### Design Principles

1. **Source-Agnostic**: Single Track model for all sources
2. **Coordinator Pattern**: Centralized playback state management
3. **Service Layer**: Modular, testable services
4. **Observable Objects**: Reactive UI updates
5. **SwiftData Persistence**: Modern, type-safe data storage

For detailed architecture documentation, see [DEVELOPMENT.md](DEVELOPMENT.md).

## 🧪 Testing

### Quick Test

```bash
# 1. Build and run on simulator
make run

# 2. Add test music
mkdir test_music
cp ~/Music/test-song.mp3 test_music/
make add-music

# 3. Test in app!
```

### Testing Environments

- **Simulator**: Best for development and iCloud testing
- **Device (Local Storage)**: Test without iCloud, perfect for Spotify
- **Device (iCloud)**: Full testing with all features

For complete testing guide, see [TESTING.md](TESTING.md).

## 🔐 Required Capabilities

The app uses these iOS capabilities:

- **iCloud → iCloud Documents** (optional, for cloud sync)
- **Background Modes → Audio** (planned, for background playback)
- **File Sharing** (enabled, for Files app access)

## 🤝 Contributing

This project uses:
- **Swift 5.9+**
- **SwiftUI** for UI
- **SwiftData** for persistence
- **AVFoundation** for local playback
- **Spotify iOS SDK** for Spotify integration
- **XcodeGen** for project generation

### Development Workflow

1. Make changes to Swift files
2. Build and test: `make run`
3. For project structure changes: `make generate`
4. Run tests: `make test`
5. Commit changes (don't commit `.xcodeproj/`)

## 📄 License

This project is provided as-is for development and educational purposes.

## 🐛 Known Issues

- Background playback not yet implemented
- Spotify requires Premium for playback (SDK limitation)
- First Spotify connection may require playing in Spotify app first

## 💡 Tips

### Storage Optimization
- iCloud files are downloaded on-demand
- Delete downloaded files to free space
- Local storage mode uses less cloud quota

### Spotify Tips
- Open Spotify app and play a song before using Muze
- This "primes" the remote control connection
- Re-import liked songs to get new additions

### Performance
- Works great with 1000+ tracks
- Metadata extraction is fast
- Smooth scrolling even with large libraries

## 📞 Support

For issues and questions:
1. Check [TESTING.md](TESTING.md) for troubleshooting
2. Review [DEVELOPMENT.md](DEVELOPMENT.md) for architecture details
3. Check console logs for error messages

---

**Version**: 1.0.0  
**Last Updated**: October 20, 2025  
**Minimum iOS**: 17.0  
**Status**: Fully functional music player with Spotify integration! 🎵

**What's New**: Complete documentation consolidation with comprehensive testing guide
