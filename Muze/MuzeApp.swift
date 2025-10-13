//
//  MuzeApp.swift
//  Muze
//
//  Created on October 7, 2025.
//

import SwiftUI
import SwiftData

@main
struct MuzeApp: App {
    // SwiftData ModelContainer
    let modelContainer: ModelContainer
    
    @StateObject private var playbackCoordinator = PlaybackCoordinator()
    @StateObject private var playlistManager: PlaylistManager
    
    init() {
        // Initialize SwiftData container
        do {
            let schema = Schema([
                Track.self,
                Playlist.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,  // Persist to disk
                cloudKitDatabase: .none  // Disable CloudKit sync - we only use iCloud Drive for files
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Initialize PlaylistManager with ModelContext
            let context = modelContainer.mainContext
            _playlistManager = StateObject(wrappedValue: PlaylistManager(modelContext: context))
            
            AppLogger.logPlaylist("SwiftData initialized successfully")
        } catch {
            fatalError("Could not initialize SwiftData: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playbackCoordinator)
                .environmentObject(playlistManager)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
        .modelContainer(modelContainer)  // Inject container into environment
    }
    
    // MARK: - URL Handling
    
    private func handleIncomingURL(_ url: URL) {
        // Handle Spotify callbacks
        guard url.scheme == "muze",
              url.host == "callback" else {
            return
        }
        
        print("📥 Received Spotify callback: \(url.absoluteString)")
        
        // Parse URL components
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("📥 ❌ Failed to parse URL components")
            return
        }
        
        // Check if this is an App Remote callback (has access_token in fragment)
        if let fragment = components.fragment, fragment.contains("access_token=") {
            print("📥 This is a Spotify App Remote callback (has access_token)")
            handleSpotifyAppRemoteCallback(fragment: fragment)
            return
        }
        
        // Check if this is an OAuth callback (has code in query)
        if let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
            print("📥 This is an OAuth callback (has authorization code)")
            handleSpotifyOAuthCallback(code: code)
            return
        }
        
        print("📥 ❌ Unknown callback format - no code or access_token found")
    }
    
    private func handleSpotifyAppRemoteCallback(fragment: String) {
        print("📥 ========================================")
        print("📥 Handling App Remote callback from authorizeAndPlayURI")
        print("📥 Fragment: \(fragment)")
        
        // Parse the fragment for access_token
        let params = fragment.components(separatedBy: "&")
        var accessToken: String?
        var expiresIn: Int = 3600
        
        for param in params {
            let keyValue = param.components(separatedBy: "=")
            guard keyValue.count == 2 else { continue }
            
            if keyValue[0] == "access_token" {
                accessToken = keyValue[1]
                print("📥 ✅ Found access token: \(String(keyValue[1].prefix(20)))...")
            } else if keyValue[0] == "expires_in" {
                expiresIn = Int(keyValue[1]) ?? 3600
                print("📥 Token expires in: \(expiresIn) seconds")
            }
        }
        
        guard let token = accessToken else {
            print("📥 ❌ No access token found in fragment")
            return
        }
        
        print("📥 ✅ Successfully extracted access token from App Remote callback")
        print("📥 This means Spotify app opened and user authorized the connection")
        print("📥 Playback should have started in Spotify app")
        
        // Update the access token in the connection parameters
        Task { @MainActor in
            print("📥 Updating appRemote.connectionParameters.accessToken...")
            playbackCoordinator.spotify.updateAccessToken(token)
            
            // Give the connection a moment to establish
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Manually mark as connected since delegate might not fire
            print("📥 Manually triggering connection established state...")
            playbackCoordinator.spotify.forceConnectionEstablished()
            
            print("📥 ✅ App Remote connection should now be active")
            print("📥 ========================================")
        }
    }
    
    private func handleSpotifyOAuthCallback(code: String) {
        print("📥 ========================================")
        print("📥 Handling OAuth callback from web authentication")
        AppLogger.logPlaylist("Authorization code received, processing...")
        
        // Handle the callback through the auth manager
        Task {
            do {
                try await playbackCoordinator.spotifyAuth.handleAuthorizationCallback(code: code)
                AppLogger.logPlaylist("Spotify authentication successful!")
                print("📥 ✅ OAuth authentication complete")
                print("📥 ========================================")
                
                // Connect to Spotify
                await MainActor.run {
                    playbackCoordinator.spotify.connect()
                }
            } catch {
                AppLogger.logPlaylist("Spotify authentication failed: \(error)", level: .error)
                print("📥 ❌ OAuth authentication failed: \(error)")
                print("📥 ========================================")
            }
        }
    }
}

