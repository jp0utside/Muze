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
        let configuration = SPTConfiguration(
            clientID: authManager.clientID,
            redirectURL: URL(string: authManager.redirectURI)!
        )
        
        appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
    }
    
    // MARK: - Connection
    
    /// Connect to Spotify App Remote
    func connect() {
        guard authManager.isAuthenticated else {
            print("SpotifyService: Not authenticated")
            return
        }
        
        guard let accessToken = authManager.accessToken else {
            print("SpotifyService: No access token")
            return
        }
        
        appRemote.connectionParameters.accessToken = accessToken
        appRemote.connect()
    }
    
    /// Disconnect from Spotify App Remote
    func disconnect() {
        if appRemote.isConnected {
            appRemote.disconnect()
        }
        isConnected = false
        stopTimeUpdateTimer()
    }
    
    // MARK: - Playback Control
    
    /// Play a track by Spotify URI
    func play(spotifyURI: String) async throws {
        guard isConnected else {
            throw SpotifyServiceError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            appRemote.playerAPI?.play(spotifyURI, callback: { [weak self] _, error in
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
        guard isConnected else {
            throw SpotifyServiceError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            appRemote.playerAPI?.pause({ [weak self] _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    self?.isPlaying = false
                    self?.stopTimeUpdateTimer()
                    continuation.resume()
                }
            })
        }
    }
    
    /// Skip to next track
    func skipToNext() async throws {
        guard isConnected else {
            throw SpotifyServiceError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            appRemote.playerAPI?.skip(toNext: { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
    
    /// Skip to previous track
    func skipToPrevious() async throws {
        guard isConnected else {
            throw SpotifyServiceError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            appRemote.playerAPI?.skip(toPrevious: { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
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
        
        return try await withCheckedThrowingContinuation { continuation in
            appRemote.playerAPI?.getPlayerState({ result, error in
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
        guard isConnected else { return }
        
        appRemote.playerAPI?.subscribe(toPlayerState: { [weak self] _, error in
            if let error = error {
                print("SpotifyService: Failed to subscribe to player state: \(error)")
                self?.onError?(error)
            }
        })
    }
    
    // MARK: - Time Updates
    
    private func startTimeUpdateTimer() {
        stopTimeUpdateTimer()
        
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
        print("SpotifyService: Connected to Spotify")
        isConnected = true
        subscribeToPlayerState()
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("SpotifyService: Disconnected from Spotify")
        isConnected = false
        isPlaying = false
        stopTimeUpdateTimer()
        
        if let error = error {
            print("SpotifyService: Disconnect error: \(error)")
            onError?(error)
        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("SpotifyService: Failed to connect to Spotify")
        isConnected = false
        
        if let error = error {
            print("SpotifyService: Connection error: \(error)")
            onError?(error)
        }
    }
}

// MARK: - SPTAppRemotePlayerStateDelegate

extension SpotifyService: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        currentTime = TimeInterval(playerState.playbackPosition) / 1000.0
        duration = TimeInterval(playerState.track.duration) / 1000.0
        isPlaying = !playerState.isPaused
        
        onTimeUpdate?(currentTime)
        
        // Check if track finished
        if playerState.playbackPosition >= playerState.track.duration - 500 {
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
