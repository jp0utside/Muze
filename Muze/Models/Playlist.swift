//
//  Playlist.swift
//  Muze
//
//  Created on October 7, 2025.
//

import Foundation
import SwiftData

/// Represents a playlist that can contain tracks from multiple sources
@Model
class Playlist {
    @Attribute(.unique) var id: UUID
    var name: String
    var playlistDescription: String?  // Renamed from 'description' to avoid keyword conflict
    var trackIDs: [UUID]  // References to Track IDs
    var artworkURLString: String?  // Store URL as String
    var dateCreated: Date
    var dateModified: Date
    
    // Computed property for URL
    var artworkURL: URL? {
        get { artworkURLString.flatMap { URL(string: $0) } }
        set { artworkURLString = newValue?.absoluteString }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        trackIDs: [UUID] = [],
        artworkURL: URL? = nil,
        dateCreated: Date = Date(),
        dateModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.playlistDescription = description
        self.trackIDs = trackIDs
        self.artworkURLString = artworkURL?.absoluteString
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }
    
    var trackCount: Int {
        trackIDs.count
    }
    
    func addTrack(_ trackID: UUID) {
        trackIDs.append(trackID)
        dateModified = Date()
    }
    
    func removeTrack(_ trackID: UUID) {
        trackIDs.removeAll { $0 == trackID }
        dateModified = Date()
    }
    
    func moveTrack(from source: IndexSet, to destination: Int) {
        trackIDs.move(fromOffsets: source, toOffset: destination)
        dateModified = Date()
    }
}

// MARK: - Identifiable
extension Playlist: Identifiable {
    // id is already defined in the class
}

// MARK: - Sample Data
extension Playlist {
    static var sample: Playlist {
        Playlist(
            name: "My Mixed Playlist",
            description: "A mix of Spotify and local tracks",
            trackIDs: []
        )
    }
    
    static var samples: [Playlist] {
        [
            Playlist(
                name: "Workout Mix",
                description: "High energy tracks for the gym",
                trackIDs: []
            ),
            Playlist(
                name: "Chill Vibes",
                description: "Relaxing music for coding",
                trackIDs: []
            ),
            Playlist(
                name: "Road Trip",
                description: "Perfect playlist for long drives",
                trackIDs: []
            )
        ]
    }
}
