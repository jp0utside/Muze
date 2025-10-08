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
        }
        .modelContainer(modelContainer)  // Inject container into environment
    }
}

