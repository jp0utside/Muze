//
//  LibraryView.swift
//  Muze
//
//  Created on October 7, 2025.
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @EnvironmentObject var playlistManager: PlaylistManager
    @EnvironmentObject var playbackCoordinator: PlaybackCoordinator
    @State private var selectedFilter: TrackSource? = nil
    @State private var isSyncing = false
    
    var filteredTracks: [Track] {
        if let filter = selectedFilter {
            return playlistManager.allTracks.filter { $0.source == filter }
        }
        return playlistManager.allTracks
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Source", selection: $selectedFilter) {
                    Text("All").tag(nil as TrackSource?)
                    ForEach(TrackSource.allCases, id: \.self) { source in
                        Text(source.displayName).tag(source as TrackSource?)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Track List
                if filteredTracks.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredTracks) { track in
                            TrackRowView(track: track)
                                .onTapGesture {
                                    playbackCoordinator.playTracks(
                                        filteredTracks,
                                        startingAt: filteredTracks.firstIndex(where: { $0.id == track.id }) ?? 0
                                    )
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        syncWithiCloud()
                    } label: {
                        if isSyncing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise.icloud")
                        }
                    }
                    .disabled(isSyncing)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Add tracks action
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func syncWithiCloud() {
        isSyncing = true
        Task {
            do {
                try await playlistManager.syncWithiCloudDrive()
                AppLogger.logPlaylist("Manual iCloud sync completed")
            } catch {
                AppLogger.logPlaylist("Manual sync failed: \(error)", level: .error)
            }
            await MainActor.run {
                isSyncing = false
            }
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Tracks")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add music files to iCloud Drive or connect Spotify")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                syncWithiCloud()
            } label: {
                Label("Sync iCloud Drive", systemImage: "arrow.clockwise.icloud")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Track.self, Playlist.self, configurations: config)
    let context = container.mainContext
    
    return LibraryView()
        .environmentObject(PlaylistManager(modelContext: context))
        .environmentObject(PlaybackCoordinator())
        .modelContainer(container)
}

