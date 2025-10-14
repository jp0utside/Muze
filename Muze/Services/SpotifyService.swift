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
    private var webAPIPollingTimer: Timer?
    
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
        
        // IMPORTANT: Set OAuth token for Web API (has full permissions)
        if let token = authManager.accessToken {
            print("🔧 Setting OAuth token on Web API for playback control")
            webAPI.setAccessToken(token)
        } else {
            print("🔧 ⚠️ No OAuth token available yet for Web API")
        }
    }
    
    deinit {
        disconnect()
        timeUpdateTimer?.invalidate()
        webAPIPollingTimer?.invalidate()
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
        stopWebAPIPolling()
    }
    
    /// Update access token (called when App Remote callback returns new token)
    func updateAccessToken(_ token: String) {
        print("🔌 Received App Remote access token from callback")
        print("🔌 Setting it on appRemote.connectionParameters...")
        appRemote.connectionParameters.accessToken = token
        
        // DO NOT set this token on webAPI - it doesn't have Web API permissions!
        // Web API should use the OAuth token from authManager
        print("🔌 NOT updating Web API token (App Remote token lacks Web API permissions)")
        print("🔌 Web API will use OAuth token from authManager instead")
        
        // Ensure webAPI has the OAuth token
        if let oauthToken = authManager.accessToken {
            print("🔌 Setting OAuth token on Web API: \(String(oauthToken.prefix(20)))...")
            webAPI.setAccessToken(oauthToken)
        }
    }
    
    /// Force connection established state (when authorizeAndPlayURI succeeds)
    func forceConnectionEstablished() {
        print("🔌 Force setting connection state to established...")
        isConnected = true
        print("🔌 isConnected = true")
        
        // Subscribe to player state (best effort - might not work)
        subscribeToPlayerState()
        
        // Start Web API polling for state updates (THIS WILL WORK!)
        isPlaying = true
        startWebAPIPolling()
        print("🔌 Connection state updated, Web API polling started")
    }
    
    // MARK: - Token Management
    
    /// Ensure OAuth token is valid, refresh if expired
    private func ensureValidToken() async throws {
        guard let expirationDate = authManager.expirationDate else {
            print("🔑 No expiration date found, attempting refresh...")
            try await authManager.refreshAccessToken()
            
            // Update webAPI with new token
            if let newToken = authManager.accessToken {
                webAPI.setAccessToken(newToken)
                print("🔑 ✅ Token refreshed and updated on Web API")
            }
            return
        }
        
        // Check if token will expire in the next minute
        let expiresIn = expirationDate.timeIntervalSinceNow
        
        if expiresIn < 60 {
            print("🔑 Token expired or expiring soon (in \(Int(expiresIn))s), refreshing...")
            try await authManager.refreshAccessToken()
            
            // Update webAPI with new token
            if let newToken = authManager.accessToken {
                webAPI.setAccessToken(newToken)
                print("🔑 ✅ Token refreshed: expires in \(authManager.expirationDate?.timeIntervalSinceNow ?? 0)s")
            }
        } else {
            print("🔑 Token still valid (expires in \(Int(expiresIn))s)")
        }
    }
    
    // MARK: - Playback Control
    
    /// Play a track by Spotify URI
    func play(spotifyURI: String) async throws {
        print("🎵 ========================================")
        print("🎵 play() called for URI: \(spotifyURI)")
        print("🎵 Current connection state: \(isConnected ? "✅ connected" : "❌ disconnected")")
        print("🎵 Auth state: \(authManager.isAuthenticated ? "✅ authenticated" : "❌ not authenticated")")
        print("🎵 Access token available: \(authManager.accessToken != nil ? "✅ yes" : "❌ no")")
        
        // If not authenticated, we can't do anything
        guard authManager.isAuthenticated else {
            print("🎵 ❌ Not authenticated - cannot play")
            throw SpotifyServiceError.notAuthenticated
        }
        
        // Try Web API first for seamless playback (no app switching!)
        print("🎵 Attempting Web API playback (seamless, no app switching)...")
        
        do {
            // Ensure token is valid
            try await ensureValidToken()
            
            // Try to play via Web API
            print("🎵 Calling webAPI.startPlayback...")
            try await webAPI.startPlayback(uri: spotifyURI)
            print("🎵 ✅ Web API playback started successfully!")
            
            // Mark as connected and playing
            isConnected = true
            isPlaying = true
            startWebAPIPolling()
            return
            
        } catch let error as SpotifyError {
            print("🎵 ⚠️ Web API playback failed: \(error)")
            
            // Check if it's a 404 (no active device)
            if case .apiError(let statusCode) = error, statusCode == 404 {
                print("🎵 No active Spotify device found")
                print("🎵 Falling back to authorizeAndPlayURI (will launch Spotify app)...")
            } else {
                print("🎵 Web API error, falling back to authorizeAndPlayURI...")
            }
        } catch {
            print("🎵 ⚠️ Unexpected error: \(error)")
            print("🎵 Falling back to authorizeAndPlayURI...")
        }
        
        // Fallback: Use authorizeAndPlayURI to launch Spotify app
        print("🎵 Using authorizeAndPlayURI as fallback...")
        print("🎵 This will open Spotify app and start playback")
        
        // Set the access token
        if let token = authManager.accessToken {
            appRemote.connectionParameters.accessToken = token
        }
        
        // Call authorizeAndPlayURI
        await MainActor.run {
            appRemote.authorizeAndPlayURI(spotifyURI)
        }
        
        print("🎵 authorizeAndPlayURI called - waiting for callback...")
        
        // Wait for connection callback
        for attempt in 1...30 {  // Wait up to 15 seconds
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            if isConnected {
                print("🎵 ✅ Connection established on attempt \(attempt)!")
                isPlaying = true
                startWebAPIPolling()
                return
            }
            
            if attempt % 4 == 0 {
                print("🎵 ⏳ Still waiting... (\(attempt/2) seconds elapsed)")
            }
        }
        
        print("🎵 ❌ Timeout waiting for Spotify callback")
        throw SpotifyServiceError.notConnected
    }
    
    /// Resume playback
    func resume() async throws {
        print("▶️ resume() called")
        print("▶️ Using Web API for resume...")
        
        // Refresh token if needed
        try await ensureValidToken()
        
        // Use Web API instead of App Remote
        try await webAPI.resumePlayback()
        print("▶️ ✅ Web API resume succeeded")
        
        isPlaying = true
        startWebAPIPolling()
    }
    
    /// Pause playback
    func pause() async throws {
        print("⏸️ pause() called")
        print("⏸️ Using Web API for pause...")
        
        // Refresh token if needed
        try await ensureValidToken()
        
        // Use Web API instead of App Remote
        try await webAPI.pausePlayback()
        print("⏸️ ✅ Web API pause succeeded")
        
        isPlaying = false
        stopWebAPIPolling()
    }
    
    /// Skip to next track
    func skipToNext() async throws {
        print("⏭️ skipToNext() called")
        print("⏭️ Using Web API for skip...")
        
        // Refresh token if needed
        try await ensureValidToken()
        
        // Use Web API instead of App Remote
        try await webAPI.skipToNext()
        print("⏭️ ✅ Web API skip succeeded")
    }
    
    /// Skip to previous track
    func skipToPrevious() async throws {
        print("⏮️ skipToPrevious() called")
        print("⏮️ Using Web API for skip previous...")
        
        // Refresh token if needed
        try await ensureValidToken()
        
        // Use Web API instead of App Remote
        try await webAPI.skipToPrevious()
        print("⏮️ ✅ Web API skip previous succeeded")
    }
    
    /// Seek to position in track
    func seek(to positionMs: Int) async throws {
        print("⏩ seek() called to position: \(positionMs)ms")
        print("⏩ Using Web API for seek...")
        
        // Refresh token if needed
        try await ensureValidToken()
        
        // Use Web API instead of App Remote
        try await webAPI.seek(toPositionMs: positionMs)
        print("⏩ ✅ Web API seek succeeded")
        
        currentTime = TimeInterval(positionMs) / 1000.0
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
    
    // MARK: - Web API Polling
    
    private func startWebAPIPolling() {
        stopWebAPIPolling()
        
        print("⏱️ Starting Web API polling for playback state...")
        
        webAPIPollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task {
                do {
                    // Ensure token is valid before polling
                    try await self.ensureValidToken()
                    
                    guard let state = try await self.webAPI.getCurrentPlayback() else {
                        print("⏱️ No active playback")
                        return
                    }
                    
                    await MainActor.run {
                        self.currentTime = state.progressSeconds
                        self.isPlaying = state.is_playing
                        
                        if let track = state.item {
                            self.duration = track.durationSeconds
                        }
                        
                        self.onTimeUpdate?(self.currentTime)
                        
                        // Check if track finished
                        if let progressMs = state.progress_ms,
                           let track = state.item,
                           progressMs >= track.duration_ms - 500 {
                            print("⏱️ Track finished!")
                            self.onPlaybackFinished?()
                        }
                    }
                } catch {
                    // Silently fail - polling is best-effort
                    print("⏱️ Polling error (non-fatal): \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func stopWebAPIPolling() {
        webAPIPollingTimer?.invalidate()
        webAPIPollingTimer = nil
        print("⏱️ Stopped Web API polling")
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
