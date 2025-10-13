//
//  PlaybackCoordinator.swift
//  Muze
//
//  Created on October 7, 2025.
//

import Foundation
import Combine
import AVFoundation

/// Coordinates playback between multiple audio sources (Spotify and local files)
@MainActor
class PlaybackCoordinator: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var currentTrack: Track?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var playbackQueue: PlaybackQueue = PlaybackQueue()
    @Published var shuffleEnabled: Bool = false
    @Published var repeatMode: RepeatMode = .off
    
    // MARK: - Services
    
    private var localAudioService: LocalAudioService
    private var spotifyService: SpotifyService
    private var spotifyAuthManager: SpotifyAuthManager
    private var iCloudManager: iCloudDriveManager
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Initialize services
        let iCloudMgr = Muze.iCloudDriveManager()
        self.iCloudManager = iCloudMgr
        self.localAudioService = LocalAudioService(iCloudManager: iCloudMgr)
        
        // Initialize Spotify authentication
        self.spotifyAuthManager = SpotifyAuthManager(
            clientID: Constants.Spotify.clientID,
            redirectURI: Constants.Spotify.redirectURI,
            scopes: Constants.Spotify.scopes
        )
        self.spotifyService = SpotifyService(authManager: spotifyAuthManager)
        
        setupServices()
    }
    
    // MARK: - Public Access to Spotify Services
    
    var spotifyAuth: SpotifyAuthManager {
        spotifyAuthManager
    }
    
    var spotify: SpotifyService {
        spotifyService
    }
    
    private func setupServices() {
        // Set up local audio service callbacks
        localAudioService.onPlaybackFinished = { [weak self] in
            Task { @MainActor in
                self?.handleTrackCompletion()
            }
        }
        
        localAudioService.onTimeUpdate = { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time
            }
        }
        
        // Set up Spotify service callbacks
        spotifyService.onPlaybackFinished = { [weak self] in
            Task { @MainActor in
                self?.handleTrackCompletion()
            }
        }
        
        spotifyService.onTimeUpdate = { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time
            }
        }
        
        spotifyService.onError = { error in
            AppLogger.logPlayback("Spotify error: \(error.localizedDescription)", level: .error)
        }
        
        // Connect to Spotify if authenticated
        if spotifyAuthManager.isAuthenticated {
            spotifyService.connect()
        }
        
        // Start monitoring iCloud Drive for file changes
        iCloudManager.startMonitoring()
        
        AppLogger.logPlayback("PlaybackCoordinator initialized with iCloud Drive and Spotify support")
    }
    
    // MARK: - Playback Control
    
    func play() {
        guard let track = currentTrack ?? playbackQueue.currentTrack else {
            print("No track to play")
            return
        }
        
        if currentTrack != track {
            playTrack(track)
        } else {
            resumePlayback()
        }
    }
    
    func pause() {
        isPlaying = false
        
        switch currentTrack?.source {
        case .local:
            localAudioService.pause()
        case .spotify:
            Task {
                do {
                    try await spotifyService.pause()
                } catch {
                    AppLogger.logPlayback("Failed to pause Spotify: \(error)", level: .error)
                }
            }
        case .none:
            break
        }
    }
    
    func playPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func next() {
        guard let nextTrack = playbackQueue.next() else {
            print("No next track available")
            return
        }
        
        playTrack(nextTrack)
    }
    
    func previous() {
        // If more than 3 seconds have elapsed, restart current track
        if currentTime > 3.0 {
            seek(to: 0)
        } else if let previousTrack = playbackQueue.previous() {
            playTrack(previousTrack)
        }
    }
    
    func seek(to time: TimeInterval) {
        currentTime = time
        
        switch currentTrack?.source {
        case .local:
            localAudioService.seek(to: time)
        case .spotify:
            let positionMs = Int(time * 1000)
            Task {
                do {
                    try await spotifyService.seek(to: positionMs)
                } catch {
                    AppLogger.logPlayback("Failed to seek in Spotify: \(error)", level: .error)
                }
            }
        case .none:
            break
        }
    }
    
    // MARK: - Queue Management
    
    func playTrack(_ track: Track) {
        // Stop current playback
        stopCurrentPlayback()
        
        currentTrack = track
        isPlaying = true
        currentTime = 0
        duration = track.duration
        
        // Dispatch to appropriate service based on track source
        switch track.source {
        case .local:
            playLocalTrack(track)
        case .spotify:
            playSpotifyTrack(track)
        }
    }
    
    func playTracks(_ tracks: [Track], startingAt index: Int = 0) {
        guard !tracks.isEmpty else { return }
        
        playbackQueue.setQueue(tracks, startAt: index)
        
        if let track = playbackQueue.currentTrack {
            playTrack(track)
        }
    }
    
    func addToQueue(_ track: Track) {
        playbackQueue.addToQueue(track)
    }
    
    func addToQueue(_ tracks: [Track]) {
        playbackQueue.addToQueue(tracks)
    }
    
    func playNext(_ track: Track) {
        playbackQueue.addNext(track)
    }
    
    func toggleShuffle() {
        shuffleEnabled.toggle()
        
        if shuffleEnabled {
            playbackQueue.shuffle()
        }
    }
    
    func toggleRepeat() {
        switch repeatMode {
        case .off:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .off
        }
    }
    
    // MARK: - Private Methods
    
    private func playLocalTrack(_ track: Track) {
        guard let fileURL = track.localFileURL else {
            AppLogger.logPlayback("Cannot play local track: missing file URL", level: .error)
            return
        }
        
        AppLogger.logPlayback("Playing local track: \(track.title) from \(fileURL.path)")
        
        // Play the file (handles both local and iCloud files)
        Task { @MainActor in
            await localAudioService.play(url: fileURL)
            
            // Update duration after playback starts
            if localAudioService.isPlaying {
                duration = localAudioService.duration
                AppLogger.logPlayback("Playback started. Duration: \(duration)s")
            }
        }
    }
    
    private func playSpotifyTrack(_ track: Track) {
        guard let spotifyURI = track.spotifyURI else {
            AppLogger.logPlayback("Cannot play Spotify track: missing URI", level: .error)
            return
        }
        
        AppLogger.logPlayback("Playing Spotify track: \(track.title) (\(spotifyURI))")
        
        Task { @MainActor in
            do {
                try await spotifyService.play(spotifyURI: spotifyURI)
                AppLogger.logPlayback("Spotify playback started")
            } catch {
                AppLogger.logPlayback("Failed to play Spotify track: \(error)", level: .error)
                isPlaying = false
            }
        }
    }
    
    private func resumePlayback() {
        isPlaying = true
        
        switch currentTrack?.source {
        case .local:
            localAudioService.resume()
        case .spotify:
            Task {
                do {
                    try await spotifyService.resume()
                } catch {
                    AppLogger.logPlayback("Failed to resume Spotify: \(error)", level: .error)
                    await MainActor.run {
                        isPlaying = false
                    }
                }
            }
        case .none:
            break
        }
    }
    
    private func stopCurrentPlayback() {
        isPlaying = false
        localAudioService.stop()
        // Spotify doesn't need explicit stop, just disconnect when switching tracks
    }
    
    // MARK: - iCloud Drive Access
    
    /// Provides access to the iCloud Drive manager
    var iCloudDriveManager: iCloudDriveManager {
        iCloudManager
    }
    
    private func handleTrackCompletion() {
        switch repeatMode {
        case .one:
            // Replay current track
            if let track = currentTrack {
                playTrack(track)
            }
        case .all, .off:
            if playbackQueue.hasNext {
                next()
            } else if repeatMode == .all, let firstTrack = playbackQueue.tracks.first {
                playbackQueue.setQueue(playbackQueue.tracks, startAt: 0)
                playTrack(firstTrack)
            } else {
                // Playback complete
                isPlaying = false
            }
        }
    }
}

// MARK: - RepeatMode

enum RepeatMode: String, CaseIterable {
    case off = "off"
    case all = "all"
    case one = "one"
    
    var iconName: String {
        switch self {
        case .off:
            return "repeat"
        case .all:
            return "repeat"
        case .one:
            return "repeat.1"
        }
    }
    
    var displayName: String {
        switch self {
        case .off:
            return "Repeat Off"
        case .all:
            return "Repeat All"
        case .one:
            return "Repeat One"
        }
    }
}

