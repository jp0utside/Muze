# Muze Development Guide

Complete guide to the Muze architecture, project structure, and implementation roadmap.

## 📋 Table of Contents

- [Project Structure](#project-structure)
- [Architecture Overview](#architecture-overview)
- [Core Components](#core-components)
- [Data Flow](#data-flow)
- [Key Design Decisions](#key-design-decisions)
- [Implementation Roadmap](#implementation-roadmap)
- [Testing Strategy](#testing-strategy)
- [Code Style Guidelines](#code-style-guidelines)

---

## Project Structure

### Directory Structure

```
Muze/
├── MuzeApp.swift                      # App entry point
├── Info.plist                         # App configuration
│
├── Models/                            # Data models (SwiftData)
│   ├── Track.swift                   # @Model class with multi-source support
│   ├── Playlist.swift                # @Model class for playlists
│   ├── TrackSource.swift             # Enum for track sources
│   └── PlaybackQueue.swift           # Queue management logic
│
├── Coordinators/                      # Business logic coordinators
│   └── PlaybackCoordinator.swift     # Central playback controller
│
├── Services/                          # Service layer
│   ├── LocalAudioService.swift       # AVFoundation playback
│   ├── SpotifyService.swift          # Spotify SDK integration
│   ├── iCloudDriveManager.swift      # iCloud Drive sync
│   └── PlaylistManager.swift         # Library & playlist management
│
├── Views/                             # SwiftUI views
│   ├── ContentView.swift             # Main tab view
│   ├── LibraryView.swift             # Library with filtering
│   ├── PlaylistsView.swift           # Playlists list
│   ├── PlaylistDetailView.swift      # Individual playlist view
│   ├── CreatePlaylistView.swift      # Playlist creation
│   ├── AddTracksToPlaylistView.swift # Add tracks to playlist
│   ├── SearchView.swift              # Search interface
│   ├── FullPlayerView.swift          # Full-screen player
│   │
│   └── Components/                   # Reusable UI components
│       ├── TrackRowView.swift        # Track list item
│       └── MiniPlayerView.swift      # Mini player bar
│
└── Utilities/                         # Helper files
    ├── Constants.swift               # App-wide constants
    ├── Extensions.swift              # Swift extensions
    └── Logger.swift                  # Centralized logging
```

### File Counts

- **23 Swift source files**
- **4 Models** - Data layer (Track & Playlist use SwiftData @Model)
- **1 Coordinator** - Business logic
- **4 Services** - External integrations
- **10 Views** - UI layer
- **3 Utilities** - Helpers
- **~3,200+ lines of code** (with SwiftData implementation)

---

## Architecture Overview

### Design Pattern: MVVM + Coordinator

```
┌─────────────────────────────────────────────────────────┐
│                        Views                            │
│  (SwiftUI Views - LibraryView, PlaylistView, etc.)     │
└─────────────────────────┬───────────────────────────────┘
                          │ ObservableObject
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    Coordinators                         │
│              (PlaybackCoordinator)                      │
│      • Manages state                                    │
│      • Orchestrates services                            │
│      • Business logic                                   │
└─────────────────────────┬───────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────┐
│                      Services                           │
│   ┌──────────────────┬──────────────────┬─────────────┐│
│   │ LocalAudioService│  SpotifyService  │iCloudMgr    ││
│   │  (AVFoundation)  │  (Spotify SDK)   │(iCloud Sync)││
│   └──────────────────┴──────────────────┴─────────────┘│
└─────────────────────────┬───────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────┐
│                       Models                            │
│          (Track, Playlist, PlaybackQueue)               │
└─────────────────────────────────────────────────────────┘
```

### Why This Architecture?

1. **Coordinator Pattern**: Single source of truth for playback state
2. **Service Layer**: Separates external integrations from business logic
3. **Observable Objects**: Reactive UI updates with SwiftUI
4. **UUID-based References**: Efficient memory management
5. **Source-Agnostic**: Single Track model for all sources

---

## Core Components

### 1. Models

#### Track.swift
**Purpose**: Represents a music track from any source

**Key Features**:
- UUID-based identification
- Source-agnostic design (works for Spotify and local files)
- Rich metadata support (title, artist, album, duration, genre, year)
- Spotify URI for Spotify tracks
- File URL for local tracks
- Artwork support

**Example**:
```swift
struct Track: Identifiable {
    let id: UUID
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let source: TrackSource
    let spotifyURI: String?      // For Spotify
    let localFileURL: URL?       // For local files
    let artworkURL: URL?
}
```

#### Playlist.swift
**Purpose**: Collection of tracks from multiple sources

**Key Features**:
- Stores track references (UUIDs)
- Supports mixed-source playlists
- Add/remove/reorder operations
- Tracks creation and modification dates
- Name and description

#### TrackSource.swift
**Purpose**: Defines available track sources

**Values**:
- `.local` - Local audio files
- `.spotify` - Spotify tracks

Easily extensible for future sources (Apple Music, YouTube Music, etc.)

#### PlaybackQueue.swift
**Purpose**: Manages the playback queue

**Key Features**:
- Current track tracking
- Next/previous navigation
- Shuffle support
- Repeat modes (off, one, all)
- History tracking
- Queue manipulation (add, remove, reorder)

### 2. Coordinators

#### PlaybackCoordinator.swift
**Purpose**: Central controller for all playback operations

**Responsibilities**:
- Switch between audio sources (local/Spotify)
- Manage playback state (play, pause, seek)
- Control playback queue
- Handle shuffle and repeat modes
- Coordinate between UI and services
- Update Now Playing info

**Published Properties**:
```swift
@Published var currentTrack: Track?
@Published var isPlaying: Bool = false
@Published var currentTime: TimeInterval = 0
@Published var duration: TimeInterval = 0
@Published var playbackQueue: PlaybackQueue
@Published var shuffleEnabled: Bool = false
@Published var repeatMode: RepeatMode = .off
```

**Key Methods**:
```swift
func playTracks(_ tracks: [Track], startingAt index: Int)
func play()
func pause()
func next()
func previous()
func seek(to time: TimeInterval)
func toggleShuffle()
func cycleRepeatMode()
```

### 3. Services

#### LocalAudioService.swift
**Purpose**: Handles local file playback using AVFoundation

**Features**:
- AVAudioPlayer management
- iCloud Drive integration
- On-demand file downloading
- Playback control (play, pause, seek)
- Time update callbacks
- Audio session configuration
- Download progress tracking

**Key Methods**:
```swift
func play(url: URL) async throws
func pause()
func seek(to time: TimeInterval)
func isCurrentFileDownloaded() -> Bool
func currentFileDownloadProgress() -> Double?
```

#### SpotifyService.swift
**Purpose**: Integrates with Spotify iOS SDK

**Features** (to be implemented):
- OAuth authentication
- Spotify Connect control
- Track info fetching
- Search integration
- Playlist import

#### iCloudDriveManager.swift
**Purpose**: Manages iCloud Drive sync

**Features**:
- iCloud Drive availability checking
- Automatic folder creation
- Recursive file scanning
- On-demand file downloading
- Download progress tracking
- File monitoring (NSMetadataQuery)
- Metadata extraction (AVAsset)
- File import/delete operations

**Key Methods**:
```swift
func scanForAudioFiles() async throws -> [URL]
func downloadFileIfNeeded(_ url: URL) async throws
func extractMetadata(from url: URL) async throws -> TrackMetadata
func isFileDownloaded(_ url: URL) -> Bool
func downloadProgress(for url: URL) -> Double?
func startMonitoring()
```

#### PlaylistManager.swift
**Purpose**: Manages playlists and track library with SwiftData persistence

**Features**:
- CRUD operations for playlists
- Track library management
- Search functionality
- iCloud Drive sync
- **SwiftData persistence** ✅ IMPLEMENTED
- Automatic save/load functionality
- FetchDescriptor-based queries

**Key Methods**:
```swift
func createPlaylist(name: String) -> Playlist
func addTrack(_ track: Track)
func removeTrack(_ trackID: UUID)
func addTrackToPlaylist(trackID: UUID, playlistID: UUID)
func removeTrackFromPlaylist(trackID: UUID, playlistID: UUID)
func syncWithiCloudDrive() async throws
func importFromiCloudDrive(_ fileURL: URL) async throws -> Track
func searchTracks(query: String) -> [Track]

// SwiftData methods
private func loadData()  // Uses FetchDescriptor
private func saveData()  // Uses ModelContext.save()
```

### 4. Views

#### Main Views
- **ContentView**: Main app container with tab navigation
- **LibraryView**: Displays all tracks with source filtering
- **PlaylistsView**: Lists all playlists
- **PlaylistDetailView**: Shows playlist contents with edit/delete
- **SearchView**: Search interface for tracks
- **FullPlayerView**: Full-screen player with controls

#### Modal Views
- **CreatePlaylistView**: Create new playlist
- **AddTracksToPlaylistView**: Add tracks to existing playlist

#### Components
- **TrackRowView**: Reusable track list item
- **MiniPlayerView**: Persistent mini player bar

### 5. Utilities

#### Constants.swift
- App-wide constants
- Configuration values
- Spotify credentials
- iCloud settings
- Audio formats
- UI dimensions

#### Extensions.swift
- TimeInterval formatting
- Array helpers for tracks
- View modifiers
- Color utilities

#### Logger.swift
- Centralized logging using OSLog
- Category-based logging
- Convenience methods for different log levels

---

## Data Flow

### Playback Flow Example

```
1. User taps track in LibraryView
   ↓
2. View calls playbackCoordinator.playTracks(...)
   ↓
3. PlaybackCoordinator:
   - Determines track source
   - Stops current playback
   - Routes to appropriate service
   ↓
4a. LocalAudioService.play(url:)    OR    4b. SpotifyService.play(spotifyURI:)
   - Checks if iCloud file                - Connects to Spotify
   - Downloads if needed                  - Sends play command
   ↓                                       ↓
5. Service starts playback and sends callbacks
   ↓
6. PlaybackCoordinator updates @Published properties
   ↓
7. SwiftUI views automatically update
```

### iCloud Sync Flow

```
1. User adds file to iCloud Drive/Muze/Music/
   ↓
2. NSMetadataQuery detects new file
   ↓
3. iCloudDriveManager triggers callback
   ↓
4. PlaylistManager.syncWithiCloudDrive() called
   ↓
5. Metadata extracted from file
   ↓
6. Track created and added to library
   ↓
7. UI updates automatically
```

### Playlist Management Flow

```
1. User creates playlist in PlaylistsView
   ↓
2. View presents CreatePlaylistView
   ↓
3. On save, calls playlistManager.createPlaylist(...)
   ↓
4. PlaylistManager:
   - Creates Playlist model
   - Updates @Published playlists array
   - Persists to storage
   ↓
5. SwiftUI views automatically refresh
```

---

## Key Design Decisions

### 1. UUID-Based Track References
Playlists store track UUIDs, not Track objects.

**Benefits**:
- Memory efficiency
- Easier persistence
- Same track in multiple playlists
- Deduplication

### 2. Coordinator Pattern
`PlaybackCoordinator` abstracts complexity from views.

**Benefits**:
- Single source of truth
- Easier testing
- Cleaner views
- Centralized business logic

### 3. Source-Agnostic Track Model
Single `Track` model for all sources.

**Benefits**:
- Unified interface
- Simplified code
- Mixed-source playlists work seamlessly
- Easy to add new sources

### 4. Service Separation
Clear separation between local, Spotify, and iCloud services.

**Benefits**:
- Modular design
- Testable components
- Easier to maintain
- Can mock services for testing

### 5. SwiftUI + Combine
Modern reactive approach.

**Benefits**:
- Automatic UI updates
- Less boilerplate code
- Better performance
- Native to Apple platforms

### 6. On-Demand Downloads
iCloud files download only when needed.

**Benefits**:
- Saves device storage
- Faster app launch
- Better user experience
- Efficient bandwidth usage

### 7. SwiftData for Persistence
Using SwiftData instead of Core Data for modern persistence.

**Benefits**:
- iOS 17+ native framework
- Type-safe queries with FetchDescriptor
- Automatic change tracking
- Less boilerplate than Core Data
- Swift-first API design
- @Model macro simplicity

**Implementation**:
- Track and Playlist as @Model classes
- ModelContainer in app initialization
- ModelContext injected to managers
- Automatic save/load functionality

---

## Implementation Roadmap

### Phase 1: Xcode Project Setup ✅ COMPLETE

- [x] Create Xcode project structure
- [x] Import source files
- [x] Configure capabilities
- [x] Set up build system

### Phase 2: Local Audio & iCloud Implementation ✅ COMPLETE

- [x] LocalAudioService with AVFoundation
- [x] iCloud Drive integration
- [x] On-demand file downloading
- [x] Metadata extraction
- [x] File monitoring (NSMetadataQuery)
- [x] Basic playback controls (play, pause, seek, stop)
- [x] PlaybackCoordinator with service callbacks
- [x] Queue management integration
- [x] Download status tracking
- [x] Audio session configuration

**What Works Now**:
- ✅ Full local audio playback with AVAudioPlayer
- ✅ Automatic iCloud Drive file discovery
- ✅ On-demand file downloads before playback
- ✅ Metadata extraction (title, artist, album, duration, genre)
- ✅ Track navigation with queue
- ✅ Playback state management

**Optional Enhancements** (can be added later):
- [ ] UI for manual file import via document picker
- [ ] Artwork extraction and caching
- [ ] Download progress UI indicators
- [ ] iCloud sync status badges on tracks

### Phase 3: Data Persistence ✅ COMPLETE

**Implemented with SwiftData**:

```swift
// Track Model - @Model class
@Model
class Track {
    @Attribute(.unique) var id: UUID
    var title: String
    var artist: String
    var album: String?
    var duration: TimeInterval
    var sourceRawValue: String  // Enum stored as String
    
    // URLs stored as Strings for SwiftData compatibility
    var localFileURLString: String?
    var artworkURLString: String?
    
    // Computed properties for convenience
    var source: TrackSource { ... }
    var localFileURL: URL? { ... }
    var artworkURL: URL? { ... }
}

// Playlist Model - @Model class
@Model
class Playlist {
    @Attribute(.unique) var id: UUID
    var name: String
    var playlistDescription: String?  // Renamed from 'description'
    var trackIDs: [UUID]  // Track relationships
    var artworkURLString: String?
    var dateCreated: Date
    var dateModified: Date
}

// MuzeApp - SwiftData Container Setup
@main
struct MuzeApp: App {
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema([Track.self, Playlist.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        modelContainer = try! ModelContainer(for: schema, configurations: [config])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}

// PlaylistManager - Uses ModelContext
class PlaylistManager: ObservableObject {
    private let modelContext: ModelContext
    
    func loadData() {
        let trackDescriptor = FetchDescriptor<Track>()
        tracks = try! modelContext.fetch(trackDescriptor)
        
        let playlistDescriptor = FetchDescriptor<Playlist>()
        playlists = try! modelContext.fetch(playlistDescriptor)
    }
    
    func saveData() {
        try! modelContext.save()
    }
}
```

**What Was Implemented**:

✅ **SwiftData Models**
- Track converted to `@Model` class
- Playlist converted to `@Model` class
- UUID marked as `@Attribute(.unique)`
- URLs stored as Strings (SwiftData compatible)
- Enums stored as raw String values

✅ **Persistence Layer**
- ModelContainer initialized in `MuzeApp`
- ModelContext injected into `PlaylistManager`
- FetchDescriptor for type-safe queries
- Automatic save/load functionality

✅ **Data Operations**
- Create: `modelContext.insert()` + `modelContext.save()`
- Read: `FetchDescriptor` + `modelContext.fetch()`
- Update: Modify properties + `modelContext.save()`
- Delete: `modelContext.delete()` + `modelContext.save()`

✅ **Integration**
- All views updated with SwiftData imports
- Preview code with in-memory containers
- Environment injection throughout app
- iCloud Drive sync preserved

**Benefits**:
- 💾 Automatic persistence to disk
- 🔄 Zero manual save/load code needed
- 📱 iOS 17+ native framework
- 🛡️ Type-safe queries
- ⚡ Optimized performance

**Files Modified**:
- `Track.swift` - @Model class implementation
- `Playlist.swift` - @Model class implementation
- `MuzeApp.swift` - Container initialization
- `PlaylistManager.swift` - ModelContext integration
- 7 view files - SwiftData imports and previews

**Tasks**:
- [x] Choose persistence layer (SwiftData selected)
- [x] Implement save/load for playlists
- [x] Cache track metadata
- [x] Store user preferences (via SwiftData)
- [ ] Implement data migration (not needed for initial release)

### Phase 4: Spotify Integration ✅ COMPLETE

Spotify integration is now fully functional with liked songs import and playback control!

#### 4.1 Spotify SDK Setup ✅

- [x] Added Spotify iOS SDK dependency (v2.1.6)
- [x] Configured Package.swift with SpotifyiOS framework
- [x] Set up Constants for Client ID and scopes

#### 4.2 Authentication Flow ✅

**Implemented:**
- `SpotifyAuthManager`: Full OAuth 2.0 flow with PKCE
- Token storage and automatic refresh
- Session management with UserDefaults
- Auto-refresh timer before expiration

#### 4.3 Spotify App Remote ✅

**Implemented:**
- `SpotifyService`: Complete integration with Spotify iOS SDK
- App Remote connection management
- Playback control (play, pause, resume, seek, skip)
- Shuffle and repeat mode control
- Player state subscription
- Real-time time updates

#### 4.4 Web API Integration ✅

**Implemented:**
- `SpotifyWebAPI`: Full REST API client
- Search functionality (tracks, albums)
- User's saved/liked tracks retrieval with pagination
- Playlist fetching
- Track metadata conversion

#### 4.5 Import Functionality ✅

**Implemented:**
- Import all Spotify liked songs with progress tracking
- Automatic pagination for large libraries (handles 1000+ tracks)
- Duplicate detection (skips already imported tracks)
- Progress callback for UI updates
- Conversion to unified Track model

#### 4.6 UI Integration ✅

**Implemented:**
- `SpotifyAuthView`: Complete authentication UI with Safari login
- Import progress UI with real-time updates
- Settings integration with connection status
- Success/error messaging

**What Works Now**:
- ✅ OAuth authentication with Spotify
- ✅ Import all liked songs from Spotify
- ✅ Play Spotify tracks through Spotify app
- ✅ Full playback control (play, pause, seek, skip)
- ✅ Unified library with Spotify and local tracks
- ✅ Mixed-source playlists
- ✅ Automatic token refresh
- ✅ Progress tracking during import

**Tasks**:
- [x] Set up Spotify Developer account documentation
- [x] Integrate Spotify iOS SDK
- [x] Implement OAuth authentication
- [x] Implement playback control
- [x] Import user's liked songs
- [x] Create comprehensive setup guide

### Phase 5: Background Playback & Lock Screen ⏳ PLANNED

#### 5.1 Audio Session Configuration

```swift
// In LocalAudioService and SpotifyService
let audioSession = AVAudioSession.sharedInstance()
try audioSession.setCategory(.playback, mode: .default)
try audioSession.setActive(true)
```

#### 5.2 Now Playing Info

```swift
// Add to PlaybackCoordinator
import MediaPlayer

private func updateNowPlayingInfo() {
    var nowPlayingInfo = [String: Any]()
    nowPlayingInfo[MPMediaItemPropertyTitle] = currentTrack?.title
    nowPlayingInfo[MPMediaItemPropertyArtist] = currentTrack?.artist
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
    
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
}
```

#### 5.3 Remote Command Center

```swift
// Add to PlaybackCoordinator
private func setupRemoteCommands() {
    let commandCenter = MPRemoteCommandCenter.shared()
    
    commandCenter.playCommand.addTarget { [weak self] _ in
        self?.play()
        return .success
    }
    
    commandCenter.pauseCommand.addTarget { [weak self] _ in
        self?.pause()
        return .success
    }
    
    commandCenter.nextTrackCommand.addTarget { [weak self] _ in
        self?.next()
        return .success
    }
    
    commandCenter.previousTrackCommand.addTarget { [weak self] _ in
        self?.previous()
        return .success
    }
}
```

**Tasks**:
- [ ] Configure audio session for background playback
- [ ] Implement MPNowPlayingInfoCenter
- [ ] Add remote command center support
- [ ] Add lock screen controls
- [ ] Test background audio

### Phase 6: Advanced Features ⏳ PLANNED

#### 6.1 Crossfade

```swift
// Implement in PlaybackCoordinator
- Detect upcoming track end
- Start preloading next track
- Fade out current, fade in next
- Configurable fade duration
```

#### 6.2 Equalizer

```swift
// Add AVAudioEngine support
- Create EQ presets (Rock, Pop, Jazz, etc.)
- Real-time audio manipulation
- Persistent EQ settings
- Custom EQ configuration
```

#### 6.3 Social Features

```swift
- Share playlists
- Export/import playlist files
- Collaborative playlists
- Listen history
```

**Tasks**:
- [ ] Implement crossfade between tracks
- [ ] Add equalizer with presets
- [ ] Add sleep timer
- [ ] Implement playlist sharing
- [ ] Add lyrics support (future)

### Phase 7: Polish & Testing ⏳ PLANNED

#### 7.1 Error Handling
- Network connectivity issues
- Spotify unavailable fallback
- File not found errors
- Permission denials
- iCloud sync failures

#### 7.2 Performance Optimization
- Lazy loading for large libraries
- Image caching
- Background queue operations
- Memory management
- Reduce app launch time

#### 7.3 UI/UX Improvements
- Animations and transitions
- Loading states
- Error states with retry
- Empty states
- Accessibility improvements

#### 7.4 Testing
```swift
// Unit Tests
- PlaybackQueue logic
- PlaylistManager operations
- Track model validation
- iCloudDriveManager operations

// Integration Tests
- PlaybackCoordinator + Services
- PlaylistManager persistence
- iCloud sync flow

// UI Tests
- Navigation flows
- Playback controls
- Playlist creation/editing
```

**Tasks**:
- [ ] Add comprehensive error handling
- [ ] Optimize performance for large libraries
- [ ] Add animations and transitions
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Write UI tests
- [ ] Test on physical devices
- [ ] Accessibility testing

### Development Timeline

**Week 1**: Foundation ✅ DONE
**Week 2**: Local Audio + iCloud ✅ DONE ✨  
**Week 3**: Persistence ✅ DONE
**Week 4**: Spotify Integration ✅ DONE 🎵
**Week 5**: Background Playback 🚧 NEXT PRIORITY
**Week 6+**: Advanced Features & Testing ⏳ PLANNED

### 🎉 Recent Milestones

**October 13, 2025** - Spotify Integration Complete!
- ✅ Full Spotify OAuth authentication
- ✅ Import all liked songs from Spotify
- ✅ Spotify playback with App Remote
- ✅ Unified library with local + Spotify tracks
- ✅ Mixed-source playlists
- 🎵 **You can now enjoy Spotify and local music together!**

**October 8, 2025** - Local Playback & iCloud Complete!
- ✅ Full local audio playback working
- ✅ iCloud Drive auto-discovery implemented
- ✅ On-demand file downloading functional
- ✅ Metadata extraction complete
- ✅ PlaybackCoordinator orchestrating services

---

## Extension Points

The architecture is designed to be easily extended:

### Adding New Track Sources

1. Add new case to `TrackSource` enum
2. Create new service (e.g., `AppleMusicService`)
3. Add routing logic in `PlaybackCoordinator`
4. Update `Track` model with source-specific identifier

Example:
```swift
// 1. Add to TrackSource.swift
enum TrackSource {
    case local
    case spotify
    case appleMusic  // New!
}

// 2. Create AppleMusicService.swift
class AppleMusicService {
    func play(musicID: String) { ... }
}

// 3. Update PlaybackCoordinator.swift
func playTrack(_ track: Track) {
    switch track.source {
    case .local: localAudioService.play(...)
    case .spotify: spotifyService.play(...)
    case .appleMusic: appleMusicService.play(...)  // New!
    }
}
```

### Adding New Features

- **Lyrics**: Add `lyrics` property to `Track`, create `LyricsView`
- **Radio Mode**: Create `RadioService`, add to `PlaybackCoordinator`
- **Social Features**: Create `SocialManager`, add sharing methods
- **Cloud Sync**: Extend `iCloudDriveManager` or create `SyncService`

---

## Testing Strategy

### Unit Tests

**Models**:
```swift
- Track creation and validation
- Playlist operations (add, remove, reorder)
- PlaybackQueue navigation logic
- Shuffle algorithm correctness
```

**Services**:
```swift
- LocalAudioService playback control
- iCloudDriveManager file operations
- PlaylistManager CRUD operations
```

**Coordinators**:
```swift
- PlaybackCoordinator state management
- Source switching logic
- Queue management
```

### Integration Tests

```swift
- PlaybackCoordinator + LocalAudioService
- PlaybackCoordinator + SpotifyService
- PlaylistManager + iCloudDriveManager
- Persistence layer integration
```

### UI Tests

```swift
- Navigation between tabs
- Playback controls functionality
- Playlist creation flow
- Adding tracks to playlists
- Search functionality
```

### Testing Checklist

- [ ] Unit tests for all models
- [ ] Service layer tests with mocks
- [ ] Coordinator logic tests
- [ ] Integration tests for playback flow
- [ ] UI tests for major features
- [ ] Test with large libraries (1000+ tracks)
- [ ] Test iCloud sync scenarios
- [ ] Test offline mode
- [ ] Test background playback
- [ ] Test on various iOS versions

---

## Code Style Guidelines

### File Organization
- Group by feature/layer, not file type
- Use MARK comments to organize code sections
- Keep files focused on single responsibility

### Naming Conventions
- Clear, descriptive names (e.g., `PlaybackCoordinator`, not `PC`)
- Use verb phrases for methods (`playTrack`, `addToPlaylist`)
- Use noun phrases for properties (`currentTrack`, `isPlaying`)

### Comments
- Use comments for "why", not "what"
- Add documentation comments for public APIs
- Explain complex algorithms or business logic

### Code Organization
```swift
// MARK: - Properties
// MARK: - Initialization
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Callbacks
```

### Access Control
- Default to `private`, expose only what's needed
- Use `internal` for same-module access
- Use `public` sparingly

### Error Handling
- Use `Result` types for async operations
- Provide user-friendly error messages
- Log errors with context

### Swift Best Practices
- Prefer `let` over `var`
- Use guard for early returns
- Leverage Swift's type system
- Use extensions to organize code
- Prefer composition over inheritance

---

## Resources

- [AVFoundation Programming Guide](https://developer.apple.com/av-foundation/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata/)
- [Spotify iOS SDK](https://developer.spotify.com/documentation/ios/)
- [iCloud Design Guide](https://developer.apple.com/icloud/)
- [Media Player Framework](https://developer.apple.com/documentation/mediaplayer/)
- [FetchDescriptor](https://developer.apple.com/documentation/swiftdata/fetchdescriptor)
- [ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer)

---

---

## 🎊 What You Can Do Right Now

Your Muze app is now a **fully functional music player with Spotify integration**! Here's what works:

### ✅ Implemented Features

#### Local Music
1. **Add Music**: Drop MP3/M4A/FLAC/etc. files into `iCloud Drive/Muze/Music/`
2. **Auto-Discovery**: Files are automatically discovered and imported with metadata
3. **Full Playback**: Play, pause, seek, next, previous controls all working
4. **Download on Demand**: iCloud files download automatically when played
5. **Metadata Extraction**: Title, artist, album, duration, genre from files

#### Spotify Integration
6. **Connect to Spotify**: OAuth authentication with Spotify accounts
7. **Import Liked Songs**: Import all your Spotify liked songs (with progress tracking)
8. **Spotify Playback**: Play Spotify tracks through the Spotify app
9. **Unified Library**: Browse both local and Spotify tracks together

#### Playlists & Organization
10. **Create Playlists**: Organize your music into playlists
11. **Mixed-Source Playlists**: Combine Spotify and local tracks in the same playlist
12. **Queue Management**: Shuffle, repeat modes, track navigation
13. **Data Persistence**: Everything saved with SwiftData

### 🎵 Try It Now

```bash
# Build and run
make run

# Or with Xcode
open Muze.xcodeproj
```

### 📊 Current Progress

| Feature | Status |
|---------|--------|
| **Architecture** | ✅ Complete |
| **Local Audio Playback** | ✅ Complete |
| **iCloud Drive Sync** | ✅ Complete |
| **Metadata Extraction** | ✅ Complete |
| **Queue Management** | ✅ Complete |
| **Data Persistence (SwiftData)** | ✅ Complete |
| **Spotify Integration** | ✅ Complete |
| **UI/UX** | ✅ Complete |
| **Background Playback** | ⏳ Next Priority |
| **Lock Screen Controls** | ⏳ Planned |

**Overall**: ~85% complete for full-featured MVP

---

**Last Updated**: October 13, 2025  
**Version**: 1.0.0  
**Status**: Spotify Integration Complete! 🎵 Next: Background Playback & Lock Screen Controls

