//
//  CreatePlaylistView.swift
//  Muze
//
//  Created on October 7, 2025.
//

import SwiftUI
import SwiftData

struct CreatePlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var playlistManager: PlaylistManager
    
    @State private var playlistName = ""
    @State private var playlistDescription = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Playlist Name", text: $playlistName)
                    
                    TextField("Description (Optional)", text: $playlistDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPlaylist()
                    }
                    .disabled(playlistName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func createPlaylist() {
        let name = playlistName.trimmingCharacters(in: .whitespaces)
        let description = playlistDescription.trimmingCharacters(in: .whitespaces)
        
        _ = playlistManager.createPlaylist(
            name: name,
            description: description.isEmpty ? nil : description
        )
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Track.self, Playlist.self, configurations: config)
    let context = container.mainContext
    
    return CreatePlaylistView()
        .environmentObject(PlaylistManager(modelContext: context))
        .modelContainer(container)
}

