//
//  PlaylistManager.swift
//  Muze
//
//  Created on October 7, 2025.
//

import Foundation
import Combine
import SwiftData

/// Manages playlists and track library using SwiftData for persistence
@MainActor
class PlaylistManager: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var playlists: [Playlist] = []
    @Published private(set) var tracks: [Track] = []
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let iCloudManager: iCloudDriveManager
    
    // MARK: - Computed Properties
    
    var allTracks: [Track] {
        tracks.sorted { $0.dateAdded > $1.dateAdded }
    }
    
    var localTracks: [Track] {
        allTracks.filter { $0.source == .local }
    }
    
    var spotifyTracks: [Track] {
        allTracks.filter { $0.source == .spotify }
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, iCloudManager: iCloudDriveManager) {
        self.modelContext = modelContext
        self.iCloudManager = iCloudManager
        loadData()
        
        // Auto-sync with iCloud Drive on launch if enabled
        if Constants.iCloud.autoSyncOnLaunch {
            Task {
                do {
                    try await syncWithiCloudDrive()
                } catch {
                    AppLogger.logPlaylist("Auto-sync with iCloud Drive failed: \(error)", level: .warning)
                }
            }
        }
    }
    
    convenience init(modelContext: ModelContext) {
        self.init(modelContext: modelContext, iCloudManager: iCloudDriveManager())
    }
    
    // MARK: - Playlist Management
    
    func createPlaylist(name: String, description: String? = nil) -> Playlist {
        let playlist = Playlist(name: name, description: description)
        modelContext.insert(playlist)
        saveData()
        playlists.append(playlist)
        return playlist
    }
    
    func updatePlaylist(_ playlist: Playlist) {
        playlist.dateModified = Date()
        saveData()
        // Trigger update
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index] = playlist
        }
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        modelContext.delete(playlist)
        saveData()
        playlists.removeAll { $0.id == playlist.id }
    }
    
    func addTrackToPlaylist(trackID: UUID, playlistID: UUID) {
        if let playlist = playlists.first(where: { $0.id == playlistID }) {
            playlist.addTrack(trackID)
            saveData()
            // Trigger update
            objectWillChange.send()
        }
    }
    
    func removeTrackFromPlaylist(trackID: UUID, playlistID: UUID) {
        if let playlist = playlists.first(where: { $0.id == playlistID }) {
            playlist.removeTrack(trackID)
            saveData()
            // Trigger update
            objectWillChange.send()
        }
    }
    
    func getTracksForPlaylist(_ playlist: Playlist) -> [Track] {
        playlist.trackIDs.compactMap { trackID in
            tracks.first(where: { $0.id == trackID })
        }
    }
    
    // MARK: - Track Management
    
    func addTrack(_ track: Track) {
        modelContext.insert(track)
        saveData()
        tracks.append(track)
    }
    
    func addTracks(_ newTracks: [Track]) {
        for track in newTracks {
            modelContext.insert(track)
            tracks.append(track)
        }
        saveData()
    }
    
    func removeTrack(_ trackID: UUID) {
        if let track = tracks.first(where: { $0.id == trackID }) {
            modelContext.delete(track)
            tracks.removeAll { $0.id == trackID }
        }
        
        // Remove from all playlists
        for playlist in playlists {
            playlist.trackIDs.removeAll { $0 == trackID }
        }
        
        saveData()
    }
    
    func getTrack(id: UUID) -> Track? {
        tracks.first(where: { $0.id == id })
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        do {
            // Fetch all tracks
            let trackDescriptor = FetchDescriptor<Track>(
                sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
            )
            tracks = try modelContext.fetch(trackDescriptor)
            
            // Fetch all playlists
            let playlistDescriptor = FetchDescriptor<Playlist>(
                sortBy: [SortDescriptor(\.dateModified, order: .reverse)]
            )
            playlists = try modelContext.fetch(playlistDescriptor)
            
            AppLogger.logPlaylist("Loaded \(tracks.count) tracks and \(playlists.count) playlists from SwiftData")
            
            // If no data exists, load sample data
            if tracks.isEmpty && playlists.isEmpty {
                loadSampleData()
            }
        } catch {
            AppLogger.logPlaylist("Failed to load data: \(error)", level: .error)
            loadSampleData()
        }
    }
    
    private func saveData() {
        do {
            try modelContext.save()
            AppLogger.logPlaylist("Data saved successfully")
        } catch {
            AppLogger.logPlaylist("Failed to save data: \(error)", level: .error)
        }
    }
    
    private func loadSampleData() {
        // Load sample tracks
        let sampleTracks = Track.samples
        for track in sampleTracks {
            modelContext.insert(track)
            tracks.append(track)
        }
        
        // Load sample playlists
        let samplePlaylists = Playlist.samples
        for playlist in samplePlaylists {
            modelContext.insert(playlist)
            playlists.append(playlist)
        }
        
        saveData()
        AppLogger.logPlaylist("Loaded sample data")
    }
    
    // MARK: - iCloud Drive Integration
    
    /// Scans iCloud Drive and imports discovered audio files
    func syncWithiCloudDrive() async throws {
        let audioFiles = try await iCloudManager.scanForAudioFiles()
        
        var importedCount = 0
        
        for fileURL in audioFiles {
            // Check if we already have this file
            let existingTrack = allTracks.first { track in
                track.localFileURL?.path == fileURL.path
            }
            
            if existingTrack == nil {
                // Extract metadata and create track
                do {
                    let metadata = try await iCloudManager.extractMetadata(from: fileURL)
                    
                    let track = Track(
                        title: metadata.title,
                        artist: metadata.artist,
                        album: metadata.album,
                        duration: metadata.duration,
                        source: .local,
                        localFileURL: fileURL,
                        artworkURL: metadata.artworkURL,
                        genre: metadata.genre,
                        year: metadata.year
                    )
                    
                    addTrack(track)
                    importedCount += 1
                } catch {
                    AppLogger.logPlaylist("Failed to import track from \(fileURL.lastPathComponent): \(error)", level: .error)
                }
            }
        }
        
        AppLogger.logPlaylist("Synced with iCloud Drive: \(importedCount) new tracks imported")
    }
    
    /// Imports a single file from iCloud Drive
    func importFromiCloudDrive(_ fileURL: URL) async throws -> Track {
        let metadata = try await iCloudManager.extractMetadata(from: fileURL)
        
        let track = Track(
            title: metadata.title,
            artist: metadata.artist,
            album: metadata.album,
            duration: metadata.duration,
            source: .local,
            localFileURL: fileURL,
            artworkURL: metadata.artworkURL,
            genre: metadata.genre,
            year: metadata.year
        )
        
        addTrack(track)
        return track
    }
    
    // MARK: - Search
    
    func searchTracks(query: String) -> [Track] {
        guard !query.isEmpty else { return allTracks }
        
        let lowercasedQuery = query.lowercased()
        return allTracks.filter {
            $0.title.lowercased().contains(lowercasedQuery) ||
            $0.artist.lowercased().contains(lowercasedQuery) ||
            $0.album?.lowercased().contains(lowercasedQuery) ?? false
        }
    }
}
