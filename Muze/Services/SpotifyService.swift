//
//  SpotifyService.swift
//  Muze
//
//  Created on October 7, 2025.
//  Updated on October 13, 2025.
//

import Foundation
import Combine
import SpotifyiOS

/// Handles Spotify playback using Spotify App Remote SDK
/// Requires Spotify app to be installed on the device
class SpotifyService: NSObject, ObservableObject {
    // MARK: - Properties
    
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var isConnected: Bool = false
    
    private var appRemote: SPTAppRemote!
    private let authManager: SpotifyAuthManager
    private let webAPI: SpotifyWebAPI
    
    private var timeUpdateTimer: Timer?
    
    // MARK: - Callbacks
    
    var onPlaybackFinished: (() -> Void)?
    var onTimeUpdate: ((TimeInterval) -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - Initialization
    
    init(authManager: SpotifyAuthManager) {
        self.authManager = authManager
        self.webAPI = SpotifyWebAPI()
        
        super.init()
        
        // Set up App Remote
        setupAppRemote()
        
        // Update Web API token when authenticated
        if let token = authManager.accessToken {
            webAPI.setAccessToken(token)
        }
    }
    
    deinit {
        disconnect()
        timeUpdateTimer?.invalidate()
    }
    
    // MARK: - App Remote Setup
    
    private func setupAppRemote() {
        print("🔧 Setting up Spotify App Remote...")
        print("🔧 Client ID: \(authManager.clientID)")
        print("🔧 Redirect URI: \(authManager.redirectURI)")
        
        let configuration = SPTConfiguration(
            clientID: authManager.clientID,
            redirectURL: URL(string: authManager.redirectURI)!
        )
        
        print("🔧 Creating SPTAppRemote with debug logging...")
        appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
        
        print("🔧 App Remote setup complete")
    }
    
    // MARK: - Connection
    
    /// Connect to Spotify App Remote
    func connect() {
        print("🔌 SpotifyService.connect() called")
        
        guard authManager.isAuthenticated else {
            print("🔌 ❌ Not authenticated - cannot connect")
            return
        }
        
        guard let accessToken = authManager.accessToken else {
            print("🔌 ❌ No access token available")
            return
        }
        
        print("🔌 Setting access token: \(String(accessToken.prefix(20)))...")
        appRemote.connectionParameters.accessToken = accessToken
        
        print("🔌 Calling appRemote.connect()...")
        print("🔌 Current connection state: \(appRemote.isConnected ? "connected" : "disconnected")")
        
        appRemote.connect()
        print("🔌 appRemote.connect() called - waiting for delegate callbacks...")
    }
    
    /// Disconnect from Spotify App Remote
    func disconnect() {
        print("🔌 Disconnecting from Spotify...")
        if appRemote.isConnected {
            appRemote.disconnect()
            print("🔌 Called appRemote.disconnect()")
        } else {
            print("🔌 Already disconnected")
        }
        isConnected = false
        stopTimeUpdateTimer()
    }
    
    /// Update access token (called when App Remote callback returns new token)
    func updateAccessToken(_ token: String) {
        print("🔌 Updating access token from App Remote callback...")
        appRemote.connectionParameters.accessToken = token
        webAPI.setAccessToken(token)
        print("🔌 Access token updated")
    }
    
    /// Force connection established state (when authorizeAndPlayURI succeeds)
    func forceConnectionEstablished() {
        print("🔌 Force setting connection state to established...")
        isConnected = true
        print("🔌 isConnected = true")
        
        // Subscribe to player state
        subscribeToPlayerState()
        
        // Start time updates
        isPlaying = true
        startTimeUpdateTimer()
        print("🔌 Connection state updated, playback should be active")
    }
    
    // MARK: - Playback Control
    
    /// Play a track by Spotify URI
    func play(spotifyURI: String) async throws {
        print("🎵 ========================================")
        print("🎵 play() called for URI: \(spotifyURI)")
        print("🎵 Current connection state: \(isConnected ? "✅ connected" : "❌ disconnected")")
        print("🎵 Auth state: \(authManager.isAuthenticated ? "✅ authenticated" : "❌ not authenticated")")
        print("🎵 Access token available: \(authManager.accessToken != nil ? "✅ yes" : "❌ no")")
        
        // If not connected, use authorizeAndPlayURI (recommended by Spotify SDK)
        if !isConnected {
            print("🎵 Not connected - using authorizeAndPlayURI...")
            print("🎵 This will trigger Spotify app to open and authorize connection")
            
            // Set the access token first
            if let token = authManager.accessToken {
                print("🎵 Setting access token on connectionParameters...")
                appRemote.connectionParameters.accessToken = token
            }
            
            // Use authorizeAndPlayURI - this handles auth + connection + playback in one call
            print("🎵 Calling appRemote.authorizeAndPlayURI(\(spotifyURI))...")
            
            // Call on a background thread since it might trigger UI
            await MainActor.run {
                appRemote.authorizeAndPlayURI(spotifyURI)
            }
            
            print("🎵 authorizeAndPlayURI called - waiting for delegate callbacks...")
            
            // Wait for connection to establish and playback to start
            print("🎵 Waiting up to 15 seconds for Spotify to respond...")
            for attempt in 1...30 {  // Wait up to 15 seconds (0.5s each)
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                if isConnected {
                    print("🎵 ✅ Connection established on attempt \(attempt)!")
                    print("🎵 Spotify should now be playing the track")
        isPlaying = true
                    startTimeUpdateTimer()
                    return
                }
                
                if attempt % 4 == 0 {  // Log every 2 seconds
                    print("🎵 ⏳ Still waiting... (\(attempt/2) seconds elapsed)")
                }
            }
            
            // Timeout - connection didn't establish
            print("🎵 ========================================")
            print("🎵 ❌ TIMEOUT: Connection didn't establish in 15 seconds")
            print("🎵 This usually means:")
            print("🎵   1. Spotify app isn't installed")
            print("🎵   2. You don't have Spotify Premium")
            print("🎵   3. Spotify app is refusing the connection")
            print("🎵   4. You're not logged into Spotify app")
            print("🎵 ========================================")
            throw SpotifyServiceError.notConnected
        }
        
        // Already connected, just play the track
        print("🎵 ✅ Already connected to Spotify")
        print("🎵 Sending play command to playerAPI...")
        print("🎵 playerAPI available: \(appRemote.playerAPI != nil ? "✅ yes" : "❌ no")")
        
        // If playerAPI is nil (can happen after authorizeAndPlayURI), use authorizeAndPlayURI again
        guard let playerAPI = appRemote.playerAPI else {
            print("🎵 ⚠️ playerAPI is nil - using authorizeAndPlayURI as fallback...")
            
            // Use authorizeAndPlayURI since regular play won't work
            await MainActor.run {
                appRemote.authorizeAndPlayURI(spotifyURI)
            }
            
            print("🎵 authorizeAndPlayURI called for already-connected session")
            // Wait a moment for it to complete
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            isPlaying = true
            startTimeUpdateTimer()
            return
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            playerAPI.play(spotifyURI, callback: { [weak self] _, error in
                if let error = error {
                    print("🎵 ❌ Play command failed with error:")
                    print("🎵    \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    print("🎵 ✅ Play command succeeded!")
                    print("🎵 Starting playback and time updates...")
                    self?.isPlaying = true
                    self?.startTimeUpdateTimer()
                    continuation.resume()
                }
            })
        }
    }
    
    /// Resume playback
    func resume() async throws {
        guard isConnected else {
            throw SpotifyServiceError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            appRemote.playerAPI?.resume({ [weak self] _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    self?.isPlaying = true
                    self?.startTimeUpdateTimer()
                    continuation.resume()
                }
            })
        }
    }
    
    /// Pause playback
    func pause() async throws {
        print("⏸️ pause() called")
        print("⏸️ isConnected: \(isConnected)")
        print("⏸️ playerAPI available: \(appRemote.playerAPI != nil)")
        
        guard isConnected else {
            print("⏸️ ❌ Not connected")
            throw SpotifyServiceError.notConnected
        }
        
        guard let playerAPI = appRemote.playerAPI else {
            print("⏸️ ❌ playerAPI is nil - cannot pause")
            print("⏸️ This is a limitation when using authorizeAndPlayURI")
            print("⏸️ Pause the song directly in Spotify app")
            throw SpotifyServiceError.invalidState
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            playerAPI.pause({ [weak self] _, error in
                if let error = error {
                    print("⏸️ ❌ Pause failed: \(error)")
                    continuation.resume(throwing: error)
                } else {
                    print("⏸️ ✅ Paused")
                    self?.isPlaying = false
                    self?.stopTimeUpdateTimer()
                    continuation.resume()
                }
            })
        }
    }
    
    /// Skip to next track
    func skipToNext() async throws {
        print("⏭️ skipToNext() called")
        print("⏭️ playerAPI available: \(appRemote.playerAPI != nil)")
        
        guard isConnected else {
            print("⏭️ ❌ Not connected")
            throw SpotifyServiceError.notConnected
        }
        
        guard let playerAPI = appRemote.playerAPI else {
            print("⏭️ ❌ playerAPI is nil - cannot skip")
            print("⏭️ Use Spotify app directly or wait for proper SDK connection")
            throw SpotifyServiceError.invalidState
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            playerAPI.skip(toNext: { _, error in
                if let error = error {
                    print("⏭️ ❌ Skip failed: \(error)")
                    continuation.resume(throwing: error)
                } else {
                    print("⏭️ ✅ Skipped to next")
                    continuation.resume()
                }
            })
        }
    }
    
    /// Skip to previous track
    func skipToPrevious() async throws {
        print("⏮️ skipToPrevious() called")
        print("⏮️ playerAPI available: \(appRemote.playerAPI != nil)")
        
        guard isConnected else {
            print("⏮️ ❌ Not connected")
            throw SpotifyServiceError.notConnected
        }
        
        guard let playerAPI = appRemote.playerAPI else {
            print("⏮️ ❌ playerAPI is nil - cannot skip")
            throw SpotifyServiceError.invalidState
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            playerAPI.skip(toPrevious: { _, error in
                if let error = error {
                    print("⏮️ ❌ Skip previous failed: \(error)")
                    continuation.resume(throwing: error)
                } else {
                    print("⏮️ ✅ Skipped to previous")
                    continuation.resume()
                }
            })
        }
    }
    
    /// Seek to position in track
    func seek(to positionMs: Int) async throws {
        guard isConnected else {
            throw SpotifyServiceError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            appRemote.playerAPI?.seek(toPosition: positionMs, callback: { [weak self] _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    self?.currentTime = TimeInterval(positionMs) / 1000.0
                    continuation.resume()
                }
            })
        }
    }
    
    /// Set shuffle mode
    func setShuffle(_ enabled: Bool) async throws {
        guard isConnected else {
            throw SpotifyServiceError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            appRemote.playerAPI?.setShuffle(enabled, callback: { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
    
    /// Set repeat mode
    func setRepeatMode(_ mode: SPTAppRemotePlaybackOptionsRepeatMode) async throws {
        guard isConnected else {
            throw SpotifyServiceError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            appRemote.playerAPI?.setRepeatMode(mode, callback: { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
    
    // MARK: - Player State
    
    /// Get current player state
    func getPlayerState() async throws -> SPTAppRemotePlayerState {
        guard isConnected else {
            throw SpotifyServiceError.notConnected
        }
        
        // Check if playerAPI is available
        guard let playerAPI = appRemote.playerAPI else {
            throw SpotifyServiceError.invalidState
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            playerAPI.getPlayerState({ result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let state = result as? SPTAppRemotePlayerState {
                    continuation.resume(returning: state)
                } else {
                    continuation.resume(throwing: SpotifyServiceError.invalidState)
                }
            })
        }
    }
    
    /// Subscribe to player state updates
    func subscribeToPlayerState() {
        print("🔔 Subscribing to player state updates...")
        
        guard isConnected else {
            print("🔔 ❌ Cannot subscribe - not connected")
            return
        }
        
        appRemote.playerAPI?.subscribe(toPlayerState: { [weak self] _, error in
            if let error = error {
                print("🔔 ❌ Failed to subscribe to player state: \(error)")
                self?.onError?(error)
            } else {
                print("🔔 ✅ Successfully subscribed to player state updates")
            }
        })
    }
    
    // MARK: - Time Updates
    
    private func startTimeUpdateTimer() {
        stopTimeUpdateTimer()
        
        // Don't start timer if playerAPI isn't available (authorizeAndPlayURI flow)
        guard appRemote.playerAPI != nil else {
            print("⏱️ Not starting time update timer - playerAPI is nil")
            print("⏱️ This is normal when using authorizeAndPlayURI")
            return
        }
        
        print("⏱️ Starting time update timer...")
        timeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task {
                do {
                    let state = try await self.getPlayerState()
                    await MainActor.run {
                        self.currentTime = TimeInterval(state.playbackPosition) / 1000.0
                        self.duration = TimeInterval(state.track.duration) / 1000.0
                        self.isPlaying = !state.isPaused
                        self.onTimeUpdate?(self.currentTime)
                        
                        // Check if track finished
                        if state.playbackPosition >= state.track.duration - 500 {
                            self.onPlaybackFinished?()
                        }
                    }
                } catch {
                    // Silently fail - player state updates are best-effort
                    // This can happen if playerAPI becomes nil
                }
            }
        }
    }
    
    private func stopTimeUpdateTimer() {
        timeUpdateTimer?.invalidate()
        timeUpdateTimer = nil
    }
    
    // MARK: - Web API Methods
    
    /// Search for tracks using Web API
    func searchTracks(query: String, limit: Int = 20) async throws -> [SpotifyTrack] {
        return try await webAPI.searchTracks(query: query, limit: limit)
    }
    
    /// Get user's playlists
    func getUserPlaylists(limit: Int = 50) async throws -> [SpotifyPlaylist] {
        return try await webAPI.getUserPlaylists(limit: limit)
    }
    
    /// Get tracks from a playlist
    func getPlaylistTracks(playlistId: String) async throws -> [SpotifyTrack] {
        return try await webAPI.getPlaylistTracks(playlistId: playlistId)
    }
    
    /// Get user's saved tracks
    func getSavedTracks(limit: Int = 50) async throws -> [SpotifyTrack] {
        return try await webAPI.getSavedTracks(limit: limit)
    }
    
    /// Get ALL user's saved tracks (handles pagination automatically)
    func getAllSavedTracks(progressCallback: ((Int) -> Void)? = nil) async throws -> [SpotifyTrack] {
        var allTracks: [SpotifyTrack] = []
        var offset = 0
        let limit = 50  // Spotify's max per request
        
        while true {
            let tracks = try await getSavedTracksWithOffset(limit: limit, offset: offset)
            
            if tracks.isEmpty {
                break
            }
            
            allTracks.append(contentsOf: tracks)
            progressCallback?(allTracks.count)
            
            offset += limit
            
            // If we got less than the limit, we've reached the end
            if tracks.count < limit {
                break
            }
        }
        
        return allTracks
    }
    
    /// Get saved tracks with pagination offset
    private func getSavedTracksWithOffset(limit: Int, offset: Int) async throws -> [SpotifyTrack] {
        guard let token = authManager.accessToken else {
            throw SpotifyServiceError.notAuthenticated
        }
        
        webAPI.setAccessToken(token)
        
        var components = URLComponents(string: "https://api.spotify.com/v1/me/tracks")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        
        guard let url = components.url else {
            throw SpotifyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpotifyError.invalidResponse
        }
        
        let savedTracksResponse = try JSONDecoder().decode(SpotifySavedTracksResponse.self, from: data)
        return savedTracksResponse.items.map { $0.track }
    }
}

// MARK: - SPTAppRemoteDelegate

extension SpotifyService: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("🔌 ========================================")
        print("🔌 ✅ DELEGATE: appRemoteDidEstablishConnection called!")
        print("🔌 ✅ Successfully connected to Spotify")
        print("🔌 playerAPI available: \(appRemote.playerAPI != nil)")
        print("🔌 imageAPI available: \(appRemote.imageAPI != nil)")
        print("🔌 userAPI available: \(appRemote.userAPI != nil)")
        print("🔌 ========================================")
        
        isConnected = true
        subscribeToPlayerState()
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("🔌 ========================================")
        print("🔌 ⚠️ DELEGATE: didDisconnectWithError called")
        print("🔌 Disconnected from Spotify")
        print("🔌 Error: \(error?.localizedDescription ?? "nil")")
        print("🔌 ========================================")
        
        isConnected = false
        isPlaying = false
        stopTimeUpdateTimer()
        
        if let error = error {
            print("🔌 Disconnect error details: \(error)")
            onError?(error)
        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("🔌 ========================================")
        print("🔌 ❌ DELEGATE: didFailConnectionAttemptWithError called")
        print("🔌 Failed to connect to Spotify")
        
        if let error = error {
            print("🔌 Error domain: \(error._domain)")
            print("🔌 Error code: \(error._code)")
            print("🔌 Error description: \(error.localizedDescription)")
            print("🔌 Full error: \(error)")
        } else {
            print("🔌 No error object provided")
        }
        
        print("🔌 ========================================")
        
        isConnected = false
        
        if let error = error {
            onError?(error)
        }
    }
}

// MARK: - SPTAppRemotePlayerStateDelegate

extension SpotifyService: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("🔔 Player state changed:")
        print("🔔   Track: \(playerState.track.name)")
        print("🔔   Artist: \(playerState.track.artist.name)")
        print("🔔   Position: \(playerState.playbackPosition)ms / \(playerState.track.duration)ms")
        print("🔔   Is paused: \(playerState.isPaused)")
        print("🔔   Playback restrictions: \(playerState.playbackRestrictions)")
        
        currentTime = TimeInterval(playerState.playbackPosition) / 1000.0
        duration = TimeInterval(playerState.track.duration) / 1000.0
        isPlaying = !playerState.isPaused
        
        onTimeUpdate?(currentTime)
        
        // Check if track finished
        if playerState.playbackPosition >= playerState.track.duration - 500 {
            print("🔔 Track finished!")
            onPlaybackFinished?()
        }
    }
}

// MARK: - Error Types

enum SpotifyServiceError: LocalizedError {
    case notConnected
    case notAuthenticated
    case invalidState
    case spotifyAppNotInstalled
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to Spotify"
        case .notAuthenticated:
            return "Not authenticated with Spotify"
        case .invalidState:
            return "Invalid player state"
        case .spotifyAppNotInstalled:
            return "Spotify app is not installed"
        }
    }
}
