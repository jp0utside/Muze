//
//  PlaylistDetailView.swift
//  Muze
//
//  Created on October 7, 2025.
//

import SwiftUI
import SwiftData

struct PlaylistDetailView: View {
    let playlist: Playlist
    @EnvironmentObject var playlistManager: PlaylistManager
    @EnvironmentObject var playbackCoordinator: PlaybackCoordinator
    @State private var showingAddTracks = false
    
    var tracks: [Track] {
        playlistManager.getTracksForPlaylist(playlist)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            playlistHeader
            
            Divider()
            
            // Tracks List
            if tracks.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(tracks) { track in
                        TrackRowView(track: track)
                            .onTapGesture {
                                playbackCoordinator.playTracks(
                                    tracks,
                                    startingAt: tracks.firstIndex(where: { $0.id == track.id }) ?? 0
                                )
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    playlistManager.removeTrackFromPlaylist(
                                        trackID: track.id,
                                        playlistID: playlist.id
                                    )
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddTracks = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTracks) {
            AddTracksToPlaylistView(playlist: playlist)
        }
    }
    
    private var playlistHeader: some View {
        VStack(spacing: 12) {
            // Playlist Artwork
            RoundedRectangle(cornerRadius: 12)
                .fill(.blue.gradient)
                .frame(width: 180, height: 180)
                .overlay {
                    Image(systemName: "music.note")
                        .foregroundStyle(.white)
                        .font(.system(size: 60))
                }
            
            Text(playlist.name)
                .font(.title2)
                .fontWeight(.bold)
            
            if let description = playlist.playlistDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Text("\(tracks.count) track\(tracks.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Play Button
            if !tracks.isEmpty {
                Button {
                    playbackCoordinator.playTracks(tracks)
                } label: {
                    Label("Play", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text("No Tracks")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Add tracks to this playlist to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Tracks") {
                showingAddTracks = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Track.self, Playlist.self, configurations: config)
    let context = container.mainContext
    
    return NavigationStack {
        PlaylistDetailView(playlist: .sample)
            .environmentObject(PlaylistManager(modelContext: context))
            .environmentObject(PlaybackCoordinator())
    }
    .modelContainer(container)
}

