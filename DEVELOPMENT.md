# Muze Development Guide

Complete guide to Muze architecture, design decisions, and development roadmap.

## 📋 Table of Contents

- [Project Structure](#project-structure)
- [Architecture Overview](#architecture-overview)
- [Core Components](#core-components)
- [Data Flow](#data-flow)
- [Key Design Decisions](#key-design-decisions)
- [Implementation Roadmap](#implementation-roadmap)
- [Extension Points](#extension-points)
- [Code Style Guidelines](#code-style-guidelines)
- [Development Workflow](#development-workflow)

---

## Project Structure

### Directory Layout

```
Muze/
├── MuzeApp.swift                      # App entry point with SwiftData setup
├── Info.plist                         # App configuration
│
├── Models/                            # Data models (SwiftData @Model classes)
│   ├── Track.swift                   # @Model class with multi-source support
│   ├── Playlist.swift                # @Model class for playlists
│   ├── TrackSource.swift             # Enum for track sources (local, spotify)
│   └── PlaybackQueue.swift           # Queue management logic
│
├── Coordinators/                      # Business logic coordinators
│   └── PlaybackCoordinator.swift     # Central playback controller
│
├── Services/                          # Service layer
│   ├── LocalAudioService.swift       # AVFoundation playback
│   ├── SpotifyService.swift          # Spotify App Remote integration
│   ├── SpotifyAuthManager.swift      # OAuth authentication
│   ├── SpotifyWebAPI.swift           # Spotify Web API client
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
│   ├── SettingsView.swift            # App settings
│   ├── SpotifyAuthView.swift         # Spotify authentication UI
│   ├── SpotifyConnectionStatusView.swift # Connection status
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

### File Statistics

- **23 Swift source files**
- **4 Models** (SwiftData @Model classes)
- **1 Coordinator** (Business logic)
- **6 Services** (External integrations)
- **11 Views** (UI layer)
- **3 Utilities** (Helpers)
- **~3,500+ lines of Swift code**

---

## Architecture Overview

### Design Pattern: MVVM + Coordinator

```
┌─────────────────────────────────────────────────────────┐
│                        Views                            │
│  (SwiftUI - LibraryView, PlaylistView, PlayerView)     │
│  • Declarative UI                                       │
│  • Observes state changes                               │
│  • User interaction handling                            │
└─────────────────────────┬───────────────────────────────┘
                          │ ObservableObject (@Published)
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    Coordinators                         │
│              (PlaybackCoordinator)                      │
│      • Manages playback state                           │
│      • Orchestrates services                            │
│      • Business logic                                   │
│      • Source routing                                   │
└─────────────────────────┬───────────────────────────────┘
                          │ Service calls
                          ↓
┌─────────────────────────────────────────────────────────┐
│                      Services                           │
│   ┌──────────────────┬──────────────────┬─────────────┐│
│   │ LocalAudioService│  SpotifyService  │iCloudMgr    ││
│   │  (AVFoundation)  │  (App Remote)    │(File Sync)  ││
│   │                  │  SpotifyWebAPI   │             ││
│   │                  │  SpotifyAuth     │             ││
│   └──────────────────┴──────────────────┴─────────────┘│
└─────────────────────────┬───────────────────────────────┘
                          │ Data operations
                          ↓
┌─────────────────────────────────────────────────────────┐
│                       Models                            │
│          (Track, Playlist, PlaybackQueue)               │
│          SwiftData @Model classes                       │
└─────────────────────────────────────────────────────────┘
```

### Why This Architecture?

1. **Coordinator Pattern**: Single source of truth for playback state
   - Centralizes business logic
   - Easier to test
   - Cleaner views
   - Handles source switching

2. **Service Layer**: Clear separation of concerns
   - Modular design
   - Testable components
   - Easy to mock
   - Independent development

3. **Source-Agnostic Design**: Single Track model for all sources
   - Unified interface
   - Simplified code
   - Mixed-source playlists work seamlessly
   - Easy to extend

4. **Observable Objects**: Reactive UI updates
   - Automatic view updates
   - Less boilerplate
   - SwiftUI native
   - Better performance

5. **SwiftData Persistence**: Modern data storage
   - iOS 17+ native framework
   - Type-safe queries
   - Automatic change tracking
   - Less boilerplate than Core Data

---

## Core Components

### 1. Models

#### Track.swift - Multi-Source Track Model

**Purpose**: Represents a music track from any source (local or Spotify)

**Implementation** (SwiftData @Model):
```swift
@Model
class Track {
    @Attribute(.unique) var id: UUID
    var title: String
    var artist: String
    var album: String?
    var duration: TimeInterval
    var sourceRawValue: String  // "local" or "spotify"
    
    // URLs stored as Strings for SwiftData compatibility
    var localFileURLString: String?
    var spotifyURI: String?
    var artworkURLString: String?
    
    // Additional metadata
    var genre: String?
    var year: Int?
    var dateAdded: Date
    
    // Computed properties for convenience
    var source: TrackSource { 
        TrackSource(rawValue: sourceRawValue) ?? .local 
    }
    var localFileURL: URL? { 
        localFileURLString.map { URL(string: $0) } ?? nil 
    }
}
```

**Key Design Choices**:
- **UUID identification**: Unique across all sources
- **Source enum**: Extensible to new sources (Apple Music, YouTube, etc.)
- **Optional properties**: Not all metadata available for all sources
- **SwiftData compatibility**: URLs stored as Strings
- **Computed properties**: Convenience without storage overhead

#### Playlist.swift - Mixed-Source Playlists

**Purpose**: Collection of tracks from any source

**Implementation**:
```swift
@Model
class Playlist {
    @Attribute(.unique) var id: UUID
    var name: String
    var playlistDescription: String?  // 'description' conflicts with Swift
    var trackIDs: [UUID]              // References, not embedded objects
    var artworkURLString: String?
    var dateCreated: Date
    var dateModified: Date
}
```

**Key Design Choices**:
- **Track IDs, not objects**: Memory efficient, easier to persist
- **Mixed sources**: No restriction on track sources
- **Modification tracking**: Automatic timestamps
- **Artwork support**: Custom or auto-generated

#### TrackSource.swift - Source Enumeration

**Purpose**: Defines available track sources

```swift
enum TrackSource: String, Codable {
    case local = "local"
    case spotify = "spotify"
    
    var displayName: String {
        switch self {
        case .local: return "Local"
        case .spotify: return "Spotify"
        }
    }
    
    var icon: String {
        switch self {
        case .local: return "music.note"
        case .spotify: return "logo.spotify"
        }
    }
}
```

**Extensibility**: Adding new sources requires:
1. Add case to enum
2. Create service class
3. Add routing in coordinator
4. Update Track model with source-specific identifier

#### PlaybackQueue.swift - Queue Management

**Purpose**: Manages playback queue with shuffle/repeat

**Features**:
- Current track index
- Original order preservation
- Shuffle mode with randomization
- Repeat modes (off, all, one)
- History tracking
- Next/previous navigation

### 2. Coordinators

#### PlaybackCoordinator.swift - Playback Orchestration

**Purpose**: Central controller for all playback operations

**Responsibilities**:
1. **Source Routing**: Determine which service to use
2. **State Management**: Track playback state
3. **Queue Management**: Control track order
4. **Service Coordination**: Orchestrate local and Spotify services
5. **UI Updates**: Publish state changes to views

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

**Source Routing Logic**:
```swift
private func playCurrentTrack() {
    guard let track = currentTrack else { return }
    
    switch track.source {
    case .local:
        Task {
            try await localAudioService.play(url: track.localFileURL!)
        }
    case .spotify:
        Task {
            try await spotifyService.play(spotifyURI: track.spotifyURI!)
        }
    }
}
```

### 3. Services

#### LocalAudioService.swift - Local Audio Playback

**Purpose**: Handle local file playback with AVFoundation

**Features**:
- AVAudioPlayer management
- iCloud file download integration
- Progress callbacks
- Audio session configuration
- Time updates
- Playback control

**Key Methods**:
```swift
func play(url: URL) async throws
func pause()
func resume()
func stop()
func seek(to time: TimeInterval)
```

**iCloud Integration**:
```swift
private func prepareForPlayback(url: URL) async throws -> URL {
    // Check if file needs downloading
    if !iCloudManager.isFileDownloaded(url) {
        try await iCloudManager.downloadFileIfNeeded(url)
    }
    return url
}
```

#### SpotifyService.swift - Spotify App Remote

**Purpose**: Control Spotify playback through iOS SDK

**Features**:
- App Remote connection management
- Playback control (play, pause, skip, seek)
- Player state subscription
- Shuffle and repeat control
- Real-time position updates

**Key Methods**:
```swift
func connect() async throws
func disconnect()
func play(spotifyURI: String) async throws
func pause()
func resume()
func skipNext()
func skipPrevious()
func seek(to position: TimeInterval)
```

**Connection Management**:
```swift
private func ensureConnected() async throws {
    guard !appRemote.isConnected else { return }
    try await connect()
}
```

#### SpotifyAuthManager.swift - OAuth Authentication

**Purpose**: Handle Spotify OAuth 2.0 flow with PKCE

**Features**:
- Authorization code flow with PKCE
- Token storage and retrieval
- Automatic token refresh
- Session management

**Key Methods**:
```swift
func startAuthentication() -> URL
func handleCallback(url: URL) async throws
func getValidAccessToken() async throws -> String
func refreshAccessToken() async throws
```

**Token Management**:
```swift
private func storeTokens(accessToken: String, refreshToken: String, expiresIn: Int) {
    UserDefaults.standard.set(accessToken, forKey: "spotify_access_token")
    UserDefaults.standard.set(refreshToken, forKey: "spotify_refresh_token")
    let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
    UserDefaults.standard.set(expirationDate, forKey: "spotify_token_expiration")
}
```

#### SpotifyWebAPI.swift - Web API Client

**Purpose**: Interact with Spotify Web API

**Features**:
- RESTful API client
- Search functionality
- User library access
- Playlist retrieval
- Track metadata
- Automatic pagination

**Key Methods**:
```swift
func searchTracks(query: String, limit: Int) async throws -> [Track]
func getUserSavedTracks(limit: Int, offset: Int) async throws -> [Track]
func getUserPlaylists() async throws -> [SpotifyPlaylist]
```

**Pagination Handling**:
```swift
func getAllSavedTracks(progressCallback: ((Int, Int) -> Void)?) async throws -> [Track] {
    var allTracks: [Track] = []
    var offset = 0
    let limit = 50
    
    while true {
        let batch = try await getUserSavedTracks(limit: limit, offset: offset)
        allTracks.append(contentsOf: batch)
        progressCallback?(allTracks.count, -1) // -1 = unknown total
        
        if batch.count < limit { break }
        offset += limit
    }
    
    return allTracks
}
```

#### iCloudDriveManager.swift - iCloud Integration

**Purpose**: Manage iCloud Drive file sync and monitoring

**Features**:
- iCloud availability detection
- Automatic folder creation
- Recursive file scanning
- On-demand downloading
- Download progress tracking
- File monitoring (NSMetadataQuery)
- Metadata extraction (AVAsset)
- Local storage fallback

**Key Methods**:
```swift
func scanForAudioFiles() async throws -> [URL]
func downloadFileIfNeeded(_ url: URL) async throws
func extractMetadata(from url: URL) async throws -> TrackMetadata
func isFileDownloaded(_ url: URL) -> Bool
func downloadProgress(for url: URL) -> Double?
func startMonitoring()
```

**Local Storage Fallback**:
```swift
init() {
    if let iCloudURL = FileManager.default.url(
        forUbiquityContainerIdentifier: nil
    )?.appendingPathComponent("Documents") {
        self.usingLocalStorage = false
        self.iCloudDocumentsURL = iCloudURL
    } else {
        // Fallback to local storage
        self.usingLocalStorage = true
        self.iCloudDocumentsURL = nil
        Logger.log("⚠️ iCloud Drive not available - using local storage fallback")
    }
}
```

#### PlaylistManager.swift - Library Management

**Purpose**: Manage playlists and track library with SwiftData

**Features**:
- CRUD operations for playlists
- Track library management
- Search functionality
- iCloud Drive sync
- SwiftData persistence
- Duplicate detection

**Key Methods**:
```swift
func createPlaylist(name: String, description: String?) -> Playlist
func deletePlaylist(_ playlist: Playlist)
func addTrackToPlaylist(track: Track, playlist: Playlist)
func removeTrackFromPlaylist(trackID: UUID, playlist: Playlist)
func syncWithiCloudDrive() async throws
func importSpotifyTrack(_ track: Track) -> Track
func searchTracks(query: String) -> [Track]
```

**SwiftData Integration**:
```swift
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
```

### 4. Views

#### SwiftUI View Architecture

All views follow this pattern:
```swift
struct ExampleView: View {
    @EnvironmentObject var playbackCoordinator: PlaybackCoordinator
    @EnvironmentObject var playlistManager: PlaylistManager
    @State private var localState: SomeType
    
    var body: some View {
        // View content
    }
    
    private func performAction() {
        // Call coordinator or manager methods
    }
}
```

**Key Views**:

1. **ContentView**: Main tab container
2. **LibraryView**: Track list with filtering and search
3. **PlaylistsView**: Playlist grid/list
4. **PlaylistDetailView**: Individual playlist with edit/delete
5. **CreatePlaylistView**: Playlist creation form
6. **AddTracksToPlaylistView**: Track selection for playlist
7. **SearchView**: Global search interface
8. **FullPlayerView**: Full-screen player with artwork
9. **SettingsView**: App settings and Spotify connection
10. **SpotifyAuthView**: Spotify OAuth UI
11. **SpotifyConnectionStatusView**: Connection status indicator

**Reusable Components**:
- **TrackRowView**: Standard track list item
- **MiniPlayerView**: Persistent mini player bar

### 5. Utilities

#### Constants.swift - Configuration

Centralized configuration:
```swift
enum Spotify {
    static let clientID = "..."
    static let redirectURI = "muze://callback"
    static let scopes = [...]
}

enum iCloud {
    static let containerIdentifier: String? = nil
    static let musicFolderName = "Muze/Music"
    static let autoSyncOnLaunch = true
}

enum Audio {
    static let supportedLocalFormats = ["mp3", "m4a", ...]
}
```

#### Extensions.swift - Swift Extensions

Useful extensions:
```swift
extension TimeInterval {
    var formattedTime: String  // "3:45"
}

extension Array where Element == Track {
    func filtered(by source: TrackSource?) -> [Track]
    func sorted(by option: SortOption) -> [Track]
}
```

#### Logger.swift - Centralized Logging

OSLog-based logging:
```swift
import OSLog

struct Logger {
    static func log(_ message: String, category: String = "General") {
        os_log("%{public}@", log: OSLog(subsystem: "com.muze.app", category: category), message)
    }
}
```

---

## Data Flow

### Playback Flow

```
1. User taps track in LibraryView
   ↓
2. View calls: playbackCoordinator.playTracks([track], startingAt: 0)
   ↓
3. PlaybackCoordinator:
   - Updates playback queue
   - Sets currentTrack
   - Calls playCurrentTrack()
   ↓
4. playCurrentTrack() checks track.source:
   
   4a. Local Track:                    4b. Spotify Track:
       - Get file URL                      - Get Spotify URI
       - Check if downloaded               - Ensure connected
       - Download if needed                - Send play command
       - localAudioService.play()          - spotifyService.play()
       ↓                                   ↓
   5a. LocalAudioService:              5b. SpotifyService:
       - Create AVAudioPlayer              - Connect App Remote
       - Configure audio session           - Queue track
       - Start playback                    - Start playback
       - Send time updates                 - Subscribe to updates
       ↓                                   ↓
6. Service sends callbacks to PlaybackCoordinator
   - Updates currentTime
   - Updates duration
   - Updates isPlaying
   ↓
7. PlaybackCoordinator publishes changes via @Published
   ↓
8. Views automatically update (SwiftUI observes)
   - MiniPlayerView updates
   - FullPlayerView updates
   - Progress bars animate
```

### iCloud Sync Flow

```
1. App launches or user taps sync button
   ↓
2. PlaylistManager.syncWithiCloudDrive() called
   ↓
3. iCloudDriveManager.scanForAudioFiles()
   - Uses NSMetadataQuery or FileManager
   - Finds all audio files recursively
   - Returns array of URLs
   ↓
4. For each URL:
   a. Check if already imported (URL-based deduplication)
   b. Extract metadata with AVAsset
   c. Create Track object
   d. Add to PlaylistManager
   ↓
5. PlaylistManager publishes update
   ↓
6. LibraryView automatically refreshes
```

### Spotify Import Flow

```
1. User taps "Import Liked Songs"
   ↓
2. SpotifyAuthView calls: spotifyWebAPI.getAllSavedTracks()
   ↓
3. SpotifyWebAPI:
   - Gets access token from SpotifyAuthManager
   - Makes paginated requests (50 tracks each)
   - Converts JSON to Track objects
   - Calls progress callback
   ↓
4. For each track:
   a. PlaylistManager.importSpotifyTrack(track)
   b. Check for duplicates (Spotify URI)
   c. Insert into ModelContext
   d. Save with SwiftData
   ↓
5. UI updates with progress
   - "Importing 45/200..."
   ↓
6. Import completes
   - All tracks in library
   - Ready to play
```

---

## Key Design Decisions

### 1. UUID-Based Track References

**Decision**: Playlists store track UUIDs, not Track objects.

**Rationale**:
- Memory efficiency: Don't duplicate track objects
- Easier persistence: Simple array of UUIDs
- Shared tracks: Same track in multiple playlists
- Deduplication: Same UUID = same track

**Implementation**:
```swift
class Playlist {
    var trackIDs: [UUID]  // Not [Track]
}

// Lookup tracks from IDs:
let tracks = trackIDs.compactMap { id in
    playlistManager.tracks.first { $0.id == id }
}
```

### 2. Coordinator Pattern

**Decision**: PlaybackCoordinator manages all playback state.

**Rationale**:
- Single source of truth
- Centralized business logic
- Easier testing (mock coordinator)
- Views stay simple

**Benefits**:
- No state duplication across views
- Complex logic isolated
- Service switching transparent to views

### 3. Source-Agnostic Track Model

**Decision**: Single Track model for all sources.

**Rationale**:
- Unified interface across app
- Mixed playlists work naturally
- Simplified view code
- Easy to add new sources

**Alternative Considered**: Separate LocalTrack and SpotifyTrack classes.
**Rejected**: Requires complex type handling, duplicate code.

### 4. Service Layer Separation

**Decision**: Clear separation between services.

**Rationale**:
- Modular design
- Independent testing
- Can mock services
- Easy to replace implementations

**Example**: Could swap Spotify SDK for different API without changing coordinator.

### 5. SwiftUI + Combine

**Decision**: Use SwiftUI with ObservableObject pattern.

**Rationale**:
- Native to iOS
- Automatic UI updates
- Less boilerplate than UIKit
- Better performance with reactive updates

### 6. On-Demand Downloads

**Decision**: iCloud files download only when needed.

**Rationale**:
- Saves device storage
- Faster app launch
- Better battery life
- Still feels instant (downloads fast)

**Implementation**:
```swift
// Before playing local track:
if !iCloudManager.isFileDownloaded(url) {
    try await iCloudManager.downloadFileIfNeeded(url)
    // Show progress...
}
// Then play
```

### 7. SwiftData for Persistence

**Decision**: Use SwiftData instead of Core Data.

**Rationale**:
- iOS 17+ native framework
- Less boilerplate code
- Type-safe queries with FetchDescriptor
- @Model macro simplicity
- Automatic change tracking
- Modern Swift-first API

**Implementation**:
```swift
// Model definition:
@Model class Track {
    var title: String
    // ...
}

// Querying:
let descriptor = FetchDescriptor<Track>()
let tracks = try modelContext.fetch(descriptor)

// Saving:
modelContext.insert(track)
try modelContext.save()
```

### 8. Local Storage Fallback

**Decision**: Automatically fallback to local storage when iCloud unavailable.

**Rationale**:
- Works with free developer accounts
- Testing without iCloud entitlement
- Better user experience (app always works)
- Graceful degradation

**Implementation**:
```swift
let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)
if let iCloudURL = iCloudURL {
    // Use iCloud
    self.usingLocalStorage = false
} else {
    // Use local Documents directory
    self.usingLocalStorage = true
    Logger.log("Using local storage fallback")
}
```

### 9. File Sharing Enabled

**Decision**: Enable UIFileSharingEnabled for Files app access.

**Rationale**:
- Easy music import without computer
- Better user experience
- Works on device without iCloud
- Standard iOS feature

---

## Implementation Roadmap

### Phase 1: Foundation ✅ COMPLETE

**Completed**:
- [x] Xcode project structure
- [x] All Swift source files created
- [x] Basic model definitions
- [x] Service interfaces
- [x] SwiftUI views structure
- [x] Build system (XcodeGen + Makefile)

**Deliverable**: Buildable app skeleton

### Phase 2: Local Audio & iCloud ✅ COMPLETE

**Completed**:
- [x] LocalAudioService with AVFoundation
- [x] AVAudioPlayer integration
- [x] Basic playback controls (play, pause, seek)
- [x] iCloudDriveManager implementation
- [x] File scanning and discovery
- [x] On-demand downloading
- [x] Download progress tracking
- [x] Metadata extraction with AVAsset
- [x] NSMetadataQuery for file monitoring
- [x] PlaybackCoordinator integration
- [x] Queue management
- [x] Local storage fallback

**What Works**:
- ✅ Full local audio playback
- ✅ Automatic iCloud file discovery
- ✅ On-demand file downloads
- ✅ Metadata extraction (title, artist, album, etc.)
- ✅ Track navigation with queue
- ✅ Works without iCloud (local storage)

**Technical Achievement**: 
- AVAudioPlayer with iCloud integration
- Seamless download before playback
- Rich metadata from audio files

### Phase 3: Data Persistence ✅ COMPLETE

**Completed**:
- [x] SwiftData @Model conversion
- [x] Track and Playlist as @Model classes
- [x] ModelContainer initialization
- [x] ModelContext integration
- [x] FetchDescriptor queries
- [x] CRUD operations with SwiftData
- [x] Automatic save/load functionality
- [x] All views updated for SwiftData

**Implementation Details**:

```swift
// Track Model
@Model
class Track {
    @Attribute(.unique) var id: UUID
    var title: String
    var artist: String
    var sourceRawValue: String
    // URLs as Strings for SwiftData
    var localFileURLString: String?
    var spotifyURI: String?
}

// Playlist Model
@Model
class Playlist {
    @Attribute(.unique) var id: UUID
    var name: String
    var trackIDs: [UUID]
    var dateCreated: Date
    var dateModified: Date
}

// App Setup
@main
struct MuzeApp: App {
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema([Track.self, Playlist.self])
        modelContainer = try! ModelContainer(for: schema)
    }
}

// Usage
let descriptor = FetchDescriptor<Track>()
let tracks = try! modelContext.fetch(descriptor)
```

**What Works**:
- 💾 Automatic data persistence
- 🔄 Tracks and playlists saved automatically
- 📱 Data survives app restarts
- 🛡️ Type-safe queries
- ⚡ Optimized performance

### Phase 4: Spotify Integration ✅ COMPLETE

**Completed**:

#### 4.1 SDK Setup ✅
- [x] Spotify iOS SDK dependency (SPM)
- [x] Package.swift configuration
- [x] Constants for credentials

#### 4.2 Authentication ✅
- [x] SpotifyAuthManager implementation
- [x] OAuth 2.0 with PKCE flow
- [x] Token storage (UserDefaults)
- [x] Automatic token refresh
- [x] Session management
- [x] SpotifyAuthView UI

#### 4.3 App Remote ✅
- [x] SpotifyService implementation
- [x] App Remote connection
- [x] Playback control (play, pause, seek, skip)
- [x] Player state subscription
- [x] Real-time position updates
- [x] Shuffle and repeat control

#### 4.4 Web API ✅
- [x] SpotifyWebAPI client
- [x] RESTful API integration
- [x] Search functionality
- [x] User library access
- [x] Pagination handling

#### 4.5 Import Functionality ✅
- [x] Import liked songs
- [x] Progress tracking
- [x] Duplicate detection
- [x] Large library support (1000+ tracks)
- [x] UI with progress indicator

#### 4.6 Integration ✅
- [x] PlaybackCoordinator routing
- [x] Mixed-source playback
- [x] Settings view integration
- [x] Connection status display

**What Works**:
- ✅ Full OAuth authentication
- ✅ Import all liked songs (with progress)
- ✅ Play Spotify tracks via App Remote
- ✅ Unified library (local + Spotify)
- ✅ Mixed-source playlists
- ✅ Automatic token refresh

**Technical Achievement**:
- Complete Spotify integration
- Seamless source switching
- Unified user experience

### Phase 5: Background Playback ⏳ NEXT PRIORITY

**Goals**: Enable background audio and lock screen controls

#### 5.1 Audio Session Configuration

```swift
// In LocalAudioService and SpotifyService
let audioSession = AVAudioSession.sharedInstance()
try audioSession.setCategory(.playback, mode: .default)
try audioSession.setActive(true)
```

#### 5.2 Now Playing Info

```swift
// In PlaybackCoordinator
import MediaPlayer

private func updateNowPlayingInfo() {
    var nowPlayingInfo = [String: Any]()
    nowPlayingInfo[MPMediaItemPropertyTitle] = currentTrack?.title
    nowPlayingInfo[MPMediaItemPropertyArtist] = currentTrack?.artist
    nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = currentTrack?.album
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
    
    if let artworkURL = currentTrack?.artworkURL {
        // Load artwork asynchronously
        Task {
            if let image = await loadArtwork(from: artworkURL) {
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        }
    }
    
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
}
```

#### 5.3 Remote Command Center

```swift
// In PlaybackCoordinator
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
    
    commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
        guard let event = event as? MPChangePlaybackPositionCommandEvent else {
            return .commandFailed
        }
        self?.seek(to: event.positionTime)
        return .success
    }
}
```

#### 5.4 Background Mode Capability

Add to `Muze.entitlements`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

**Tasks**:
- [ ] Configure audio session for background
- [ ] Implement Now Playing Info updates
- [ ] Add Remote Command Center support
- [ ] Test background playback
- [ ] Test lock screen controls
- [ ] Handle interruptions (calls, alarms)
- [ ] Test with both local and Spotify

**Estimated Time**: 1-2 weeks

### Phase 6: Advanced Features ⏳ PLANNED

**Goals**: Polish and advanced functionality

#### 6.1 Artwork Management

- [ ] Extract artwork from audio files
- [ ] Cache artwork images
- [ ] Download Spotify artwork
- [ ] Generate placeholder artwork
- [ ] Artwork for playlists

#### 6.2 Crossfade

```swift
// Implement in PlaybackCoordinator
private func handleTrackEnding() {
    // Detect track near end (last 5 seconds)
    if duration - currentTime < 5.0 {
        // Start preloading next track
        preloadNextTrack()
        
        // Fade out current, fade in next
        crossfadeToNext()
    }
}
```

#### 6.3 Equalizer

```swift
// Add AVAudioEngine support
class LocalAudioService {
    private let audioEngine = AVAudioEngine()
    private let eqNode = AVAudioUnitEQ()
    
    func applyEQPreset(_ preset: EQPreset) {
        // Configure EQ bands
        eqNode.bands[0].frequency = 60
        eqNode.bands[0].gain = preset.bass
        // ... configure all bands
    }
}
```

#### 6.4 Sleep Timer

```swift
class PlaybackCoordinator {
    private var sleepTimer: Timer?
    
    func setSleepTimer(minutes: Int) {
        sleepTimer?.invalidate()
        sleepTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(minutes * 60),
            repeats: false
        ) { [weak self] _ in
            self?.pause()
            // Fade out
        }
    }
}
```

#### 6.5 Social Features

- [ ] Playlist sharing (export/import)
- [ ] QR code for playlists
- [ ] Playlist collaboration
- [ ] Listen history tracking

**Estimated Time**: 2-3 weeks per feature

### Phase 7: Polish & Testing ⏳ PLANNED

#### 7.1 Error Handling

- [ ] Network connectivity issues
- [ ] Spotify unavailable fallback
- [ ] File not found errors
- [ ] Permission denied handling
- [ ] iCloud sync failures
- [ ] User-friendly error messages

#### 7.2 Performance Optimization

- [ ] Lazy loading for large libraries
- [ ] Image caching and optimization
- [ ] Background queue operations
- [ ] Memory management review
- [ ] Reduce app launch time
- [ ] Profile with Instruments

#### 7.3 UI/UX Improvements

- [ ] Smooth animations and transitions
- [ ] Loading states for all operations
- [ ] Error states with retry options
- [ ] Empty states with helpful guidance
- [ ] Accessibility improvements (VoiceOver)
- [ ] Dynamic Type support
- [ ] Haptic feedback

#### 7.4 Testing

```swift
// Unit Tests
- PlaybackQueue logic tests
- PlaylistManager operations tests
- Track model validation tests
- iCloudDriveManager operations tests

// Integration Tests
- PlaybackCoordinator + Services
- PlaylistManager persistence
- iCloud sync flow
- Spotify authentication flow

// UI Tests
- Navigation flows
- Playback controls
- Playlist creation/editing
- Search functionality
```

**Estimated Time**: 2-3 weeks

---

## Extension Points

The architecture is designed for easy extension:

### Adding New Track Sources

Example: Adding Apple Music support

1. **Add to TrackSource enum**:
```swift
enum TrackSource: String {
    case local
    case spotify
    case appleMusic  // New!
}
```

2. **Create service**:
```swift
class AppleMusicService {
    func play(musicID: String) async throws {
        // Implement Apple Music playback
    }
}
```

3. **Update Track model**:
```swift
@Model
class Track {
    var appleMusicID: String?  // New property
}
```

4. **Add routing in coordinator**:
```swift
func playCurrentTrack() {
    switch currentTrack?.source {
    case .local: // ...
    case .spotify: // ...
    case .appleMusic: // New!
        Task {
            try await appleMusicService.play(
                musicID: currentTrack!.appleMusicID!
            )
        }
    }
}
```

### Adding New Features

#### Lyrics Support

1. Add `lyrics` property to Track
2. Create `LyricsView` to display
3. Fetch from metadata or API
4. Show synchronized with playback

#### Radio Mode

1. Create `RadioService`
2. Generate similar tracks
3. Integrate with PlaybackCoordinator
4. Add UI controls

#### Collaborative Playlists

1. Add `collaborators` to Playlist
2. Create sync service (CloudKit)
3. Handle conflicts
4. Add sharing UI

---

## Code Style Guidelines

### File Organization

```swift
// MARK: - Properties
// MARK: - Initialization
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Callbacks/Delegates
```

### Naming Conventions

- **Classes/Structs**: `PascalCase` (e.g., `PlaybackCoordinator`)
- **Functions**: `camelCase` with verb (e.g., `playTrack()`)
- **Properties**: `camelCase` with noun (e.g., `currentTrack`)
- **Constants**: `camelCase` (e.g., `clientID`)
- **Enums**: `PascalCase` with singular (e.g., `TrackSource`)

### Comments

```swift
// Use comments for "why", not "what"

/// Documentation comment for public APIs
/// - Parameter track: The track to play
/// - Returns: True if playback started successfully
func play(track: Track) -> Bool {
    // Good: Explains reasoning
    // Spotify requires connection before playback
    guard spotifyService.isConnected else {
        return false
    }
}
```

### Access Control

- Default to `private`
- Use `internal` for same-module access
- Use `public` only for external APIs
- Use `fileprivate` sparingly

### Error Handling

```swift
// Use Result types for async operations
func loadTrack() async -> Result<Track, Error> {
    // ...
}

// Use throws for sync operations
func validateTrack() throws {
    // ...
}

// Provide user-friendly error messages
enum MuzeError: LocalizedError {
    case fileNotFound(URL)
    case spotifyNotConnected
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "Could not find audio file: \(url.lastPathComponent)"
        case .spotifyNotConnected:
            return "Please connect to Spotify first"
        }
    }
}
```

### Swift Best Practices

```swift
// Prefer let over var
let constantValue = 42

// Use guard for early returns
guard let track = currentTrack else {
    Logger.log("No track to play")
    return
}

// Leverage type inference
let tracks = [Track]()  // Not: [Track] = [Track]()

// Use extensions to organize code
extension PlaybackCoordinator {
    // MARK: - Queue Management
    func nextTrack() { }
    func previousTrack() { }
}

// Prefer composition over inheritance
struct Track {
    let metadata: TrackMetadata  // Composition
    let source: TrackSource
}
```

---

## Development Workflow

### Daily Development

```bash
# 1. Pull latest changes
git pull

# 2. Generate project (if structure changed)
make generate

# 3. Make code changes
# Edit Swift files in Muze/ directory

# 4. Build and test
make run

# 5. Check console for logs

# 6. Commit changes
git add .
git commit -m "Add feature X"
```

### Adding New Files

```bash
# 1. Create Swift file in appropriate directory
touch Muze/Services/NewService.swift

# 2. Regenerate Xcode project
make generate

# 3. Build to verify
make build
```

### Changing Project Configuration

```bash
# 1. Edit project.yml
vim project.yml

# 2. Regenerate project
make generate

# 3. Verify changes
make build
```

### Testing Changes

```bash
# Unit tests (when implemented)
make test

# Manual testing on simulator
make run

# Testing on device
# Build via Xcode to device
```

### Version Control Best Practices

**Commit**:
- All `.swift` source files
- `project.yml` (XcodeGen config)
- `Muze.entitlements`
- `Info.plist`
- `Package.swift`
- `Makefile`
- Documentation (`.md` files)
- `.gitignore`

**Don't Commit**:
- `Muze.xcodeproj/` (generated)
- `build/` (build artifacts)
- `DerivedData/` (Xcode cache)
- `.DS_Store` (macOS files)
- `*.swp` (editor temp files)

### Debugging Tips

1. **Use Logger extensively**:
```swift
   Logger.log("Starting playback for: \(track.title)")
   ```

2. **Check Console.app** for system logs

3. **Set breakpoints** in Xcode

4. **Use lldb** commands:
   ```
   po currentTrack
   expr isPlaying = true
   ```

5. **Profile with Instruments**:
   - Time Profiler for performance
   - Allocations for memory leaks
   - Network for API calls

### Code Review Checklist

- [ ] Follows naming conventions
- [ ] Proper error handling
- [ ] Logging added for debugging
- [ ] Comments explain "why"
- [ ] No hardcoded values (use Constants)
- [ ] Testable code structure
- [ ] No force unwraps (`!`)
- [ ] Memory management considered
- [ ] Accessibility considered

---

## Resources

- [AVFoundation Programming Guide](https://developer.apple.com/av-foundation/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata/)
- [Spotify iOS SDK](https://developer.spotify.com/documentation/ios/)
- [iCloud Design Guide](https://developer.apple.com/icloud/)
- [Media Player Framework](https://developer.apple.com/documentation/mediaplayer/)
- [XcodeGen Documentation](https://github.com/yonaskolb/XcodeGen)

---

## Current Status

### What's Working Now

You have a **fully functional music player**! 🎉

✅ **Local Music**:
- Play audio files from iCloud or local storage
- Automatic file discovery and import
- On-demand downloads
- Rich metadata extraction

✅ **Spotify Integration**:
- OAuth authentication
- Import liked songs (with progress)
- Play Spotify tracks
- Full playback control

✅ **Organization**:
- Create and manage playlists
- Mix local and Spotify tracks
- Search across library
- Queue management with shuffle/repeat

✅ **Persistence**:
- All data saved with SwiftData
- Survives app restarts
- Efficient storage

### Next Priority

**Background Playback** - Enable audio in background and lock screen controls

**Estimated Completion**: 1-2 weeks

---

**Last Updated**: October 20, 2025  
**Version**: 1.0.0  
**Status**: Core functionality complete! Background playback next! 🎵
