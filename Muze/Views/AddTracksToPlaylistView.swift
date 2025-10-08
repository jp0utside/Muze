//
//  AddTracksToPlaylistView.swift
//  Muze
//
//  Created on October 7, 2025.
//

import SwiftUI
import SwiftData

struct AddTracksToPlaylistView: View {
    let playlist: Playlist
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var playlistManager: PlaylistManager
    
    @State private var searchText = ""
    @State private var selectedTrackIDs: Set<UUID> = []
    
    var availableTracks: [Track] {
        let existingTrackIDs = Set(playlist.trackIDs)
        return playlistManager.searchTracks(query: searchText)
            .filter { !existingTrackIDs.contains($0.id) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(availableTracks) { track in
                    HStack {
                        TrackRowView(track: track)
                        
                        Spacer()
                        
                        if selectedTrackIDs.contains(track.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleTrackSelection(track)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search tracks")
            .navigationTitle("Add Tracks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedTrackIDs.count))") {
                        addSelectedTracks()
                    }
                    .disabled(selectedTrackIDs.isEmpty)
                }
            }
        }
    }
    
    private func toggleTrackSelection(_ track: Track) {
        if selectedTrackIDs.contains(track.id) {
            selectedTrackIDs.remove(track.id)
        } else {
            selectedTrackIDs.insert(track.id)
        }
    }
    
    private func addSelectedTracks() {
        for trackID in selectedTrackIDs {
            playlistManager.addTrackToPlaylist(trackID: trackID, playlistID: playlist.id)
        }
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Track.self, Playlist.self, configurations: config)
    let context = container.mainContext
    
    return AddTracksToPlaylistView(playlist: .sample)
        .environmentObject(PlaylistManager(modelContext: context))
        .modelContainer(container)
}

