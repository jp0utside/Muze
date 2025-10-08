//
//  SearchView.swift
//  Muze
//
//  Created on October 7, 2025.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @EnvironmentObject var playlistManager: PlaylistManager
    @EnvironmentObject var playbackCoordinator: PlaybackCoordinator
    @State private var searchText = ""
    
    var searchResults: [Track] {
        playlistManager.searchTracks(query: searchText)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    emptyStateView
                } else if searchResults.isEmpty {
                    noResultsView
                } else {
                    List(searchResults) { track in
                        TrackRowView(track: track)
                            .onTapGesture {
                                playbackCoordinator.playTracks(
                                    searchResults,
                                    startingAt: searchResults.firstIndex(where: { $0.id == track.id }) ?? 0
                                )
                            }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Search tracks, artists, albums")
            .navigationTitle("Search")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Search Your Music")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Find tracks from your local library and Spotify")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Results")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Try a different search term")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Track.self, Playlist.self, configurations: config)
    let context = container.mainContext
    
    return SearchView()
        .environmentObject(PlaylistManager(modelContext: context))
        .environmentObject(PlaybackCoordinator())
        .modelContainer(container)
}

