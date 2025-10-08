//
//  Track.swift
//  Muze
//
//  Created on October 7, 2025.
//

import Foundation
import SwiftData

/// Represents a music track from any source
@Model
class Track {
    @Attribute(.unique) var id: UUID
    var title: String
    var artist: String
    var album: String?
    var duration: TimeInterval
    var sourceRawValue: String  // Store enum as String for SwiftData
    
    // Source-specific identifiers
    var spotifyURI: String?
    var localFileURLString: String?  // Store URL as String
    
    // Optional metadata
    var artworkURLString: String?  // Store URL as String
    var genre: String?
    var year: Int?
    
    var dateAdded: Date
    
    // Computed properties for convenience
    var source: TrackSource {
        get { TrackSource(rawValue: sourceRawValue) ?? .local }
        set { sourceRawValue = newValue.rawValue }
    }
    
    var localFileURL: URL? {
        get { localFileURLString.flatMap { URL(string: $0) } }
        set { localFileURLString = newValue?.absoluteString }
    }
    
    var artworkURL: URL? {
        get { artworkURLString.flatMap { URL(string: $0) } }
        set { artworkURLString = newValue?.absoluteString }
    }
    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        album: String? = nil,
        duration: TimeInterval,
        source: TrackSource,
        spotifyURI: String? = nil,
        localFileURL: URL? = nil,
        artworkURL: URL? = nil,
        genre: String? = nil,
        year: Int? = nil,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.sourceRawValue = source.rawValue
        self.spotifyURI = spotifyURI
        self.localFileURLString = localFileURL?.absoluteString
        self.artworkURLString = artworkURL?.absoluteString
        self.genre = genre
        self.year = year
        self.dateAdded = dateAdded
    }
    
    /// Formatted duration string (MM:SS)
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Returns the appropriate identifier for playback based on source
    var playbackIdentifier: String {
        switch source {
        case .spotify:
            return spotifyURI ?? ""
        case .local:
            return localFileURL?.absoluteString ?? ""
        }
    }
}

// MARK: - Equatable
extension Track: Equatable {
    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Identifiable
extension Track: Identifiable {
    // id is already defined in the class
}

// MARK: - Sample Data
extension Track {
    static var sample: Track {
        Track(
            title: "Sample Song",
            artist: "Sample Artist",
            album: "Sample Album",
            duration: 180,
            source: .local
        )
    }
    
    static var samples: [Track] {
        [
            Track(
                title: "Local Track 1",
                artist: "Local Artist",
                album: "Local Album",
                duration: 210,
                source: .local,
                localFileURL: URL(string: "file:///music/track1.mp3")
            ),
            Track(
                title: "Spotify Track 1",
                artist: "Spotify Artist",
                album: "Spotify Album",
                duration: 195,
                source: .spotify,
                spotifyURI: "spotify:track:abc123"
            ),
            Track(
                title: "Another Local Track",
                artist: "Indie Artist",
                album: "Indie Album",
                duration: 240,
                source: .local,
                localFileURL: URL(string: "file:///music/track2.mp3")
            )
        ]
    }
}

