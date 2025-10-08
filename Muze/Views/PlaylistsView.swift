//
//  PlaylistsView.swift
//  Muze
//
//  Created on October 7, 2025.
//

import SwiftUI
import SwiftData

struct PlaylistsView: View {
    @EnvironmentObject var playlistManager: PlaylistManager
    @State private var showingCreatePlaylist = false
    
    var body: some View {
        NavigationStack {
            Group {
                if playlistManager.playlists.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(playlistManager.playlists) { playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                                PlaylistRowView(playlist: playlist)
                            }
                        }
                        .onDelete(perform: deletePlaylists)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Playlists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreatePlaylist = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlaylist) {
                CreatePlaylistView()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Playlists")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create a playlist to organize your favorite tracks")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Playlist") {
                showingCreatePlaylist = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func deletePlaylists(at offsets: IndexSet) {
        for index in offsets {
            playlistManager.deletePlaylist(playlistManager.playlists[index])
        }
    }
}

struct PlaylistRowView: View {
    let playlist: Playlist
    @EnvironmentObject var playlistManager: PlaylistManager
    
    var trackCount: Int {
        playlistManager.getTracksForPlaylist(playlist).count
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Playlist Artwork Placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.gradient)
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "music.note")
                        .foregroundStyle(.white)
                        .font(.title2)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.headline)
                
                Text("\(trackCount) track\(trackCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Track.self, Playlist.self, configurations: config)
    let context = container.mainContext
    
    return PlaylistsView()
        .environmentObject(PlaylistManager(modelContext: context))
        .modelContainer(container)
}

