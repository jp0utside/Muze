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
        // Handle Spotify OAuth callback
        guard url.scheme == "muze",
              url.host == "callback" else {
            return
        }
        
        AppLogger.logPlaylist("Received OAuth callback: \(url.absoluteString)")
        
        // Extract the authorization code
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            AppLogger.logPlaylist("Failed to extract authorization code from callback", level: .error)
            return
        }
        
        AppLogger.logPlaylist("Authorization code received, processing...")
        
        // Handle the callback through the auth manager
        Task {
            do {
                try await playbackCoordinator.spotifyAuth.handleAuthorizationCallback(code: code)
                AppLogger.logPlaylist("Spotify authentication successful!")
                
                // Connect to Spotify
                await MainActor.run {
                    playbackCoordinator.spotify.connect()
                }
            } catch {
                AppLogger.logPlaylist("Spotify authentication failed: \(error)", level: .error)
            }
        }
    }
}

