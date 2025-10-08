//
//  TrackSource.swift
//  Muze
//
//  Created on October 7, 2025.
//

import Foundation

/// Represents the source of a music track
enum TrackSource: String, Codable, CaseIterable {
    case local = "local"
    case spotify = "spotify"
    
    var displayName: String {
        switch self {
        case .local:
            return "Local File"
        case .spotify:
            return "Spotify"
        }
    }
    
    var iconName: String {
        switch self {
        case .local:
            return "music.note"
        case .spotify:
            return "music.note.list"
        }
    }
}

