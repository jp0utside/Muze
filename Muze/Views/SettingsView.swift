//
//  SettingsView.swift
//  Muze
//
//  Created on October 13, 2025.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var playbackCoordinator: PlaybackCoordinator
    @EnvironmentObject var playlistManager: PlaylistManager
    @State private var showingSpotifyAuth = false
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Spotify Section
                Section {
                    Button {
                        showingSpotifyAuth = true
                    } label: {
                        HStack {
                            Image(systemName: "music.note")
                                .foregroundColor(.green)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("Spotify")
                                    .font(.body)
                                
                                if playbackCoordinator.spotifyAuth.isAuthenticated {
                                    Text("Connected")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else {
                                    Text("Not connected")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("Services")
                }
                
                // MARK: - Library Section
                Section {
                    HStack {
                        Text("Total Tracks")
                        Spacer()
                        Text("\(playlistManager.allTracks.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Local Tracks")
                        Spacer()
                        Text("\(playlistManager.localTracks.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Spotify Tracks")
                        Spacer()
                        Text("\(playlistManager.spotifyTracks.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Playlists")
                        Spacer()
                        Text("\(playlistManager.playlists.count)")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Library Stats")
                }
                
                // MARK: - iCloud Section
                Section {
                    Button {
                        Task {
                            do {
                                try await playlistManager.syncWithiCloudDrive()
                            } catch {
                                print("Sync failed: \(error)")
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "icloud.and.arrow.down")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("Sync with iCloud Drive")
                            Spacer()
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("iCloud")
                } footer: {
                    Text("Scans your iCloud Drive's Muze/Music folder for new audio files")
                }
                
                // MARK: - About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Constants.App.version)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("App Name")
                        Spacer()
                        Text(Constants.App.name)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingSpotifyAuth) {
                SpotifyAuthView(
                    authManager: playbackCoordinator.spotifyAuth,
                    spotifyService: playbackCoordinator.spotify,
                    playlistManager: playlistManager
                )
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Track.self, Playlist.self, configurations: config)
    let context = container.mainContext
    
    return SettingsView()
        .environmentObject(PlaybackCoordinator())
        .environmentObject(PlaylistManager(modelContext: context))
        .modelContainer(container)
}

