//
//  ContentView.swift
//  Muze
//
//  Created on October 7, 2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var playbackCoordinator: PlaybackCoordinator
    @EnvironmentObject var playlistManager: PlaylistManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "music.note.list")
                }
                .tag(0)
            
            PlaylistsView()
                .tabItem {
                    Label("Playlists", systemImage: "music.note")
                }
                .tag(1)
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .safeAreaInset(edge: .bottom) {
            if playbackCoordinator.currentTrack != nil {
                MiniPlayerView()
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Track.self, Playlist.self, configurations: config)
    let context = container.mainContext
    
    return ContentView()
        .environmentObject(PlaybackCoordinator())
        .environmentObject(PlaylistManager(modelContext: context))
        .modelContainer(container)
}

