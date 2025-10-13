//
//  Constants.swift
//  Muze
//
//  Created on October 7, 2025.
//

import Foundation
import SwiftUI

enum Constants {
    // MARK: - App
    enum App {
        static let name = "Muze"
        static let version = "1.0.0"
    }
    
    // MARK: - Spotify
    enum Spotify {
        // TODO: Add your Spotify Client ID from https://developer.spotify.com/dashboard
        static let clientID = "d47f65a225ae4bae8401a9c4ef07dab3"
        static let redirectURI = "muze://callback/"  // iOS adds trailing slash automatically
        
        // Spotify API scopes needed
        static let scopes = [
            "user-read-playback-state",
            "user-modify-playback-state",
            "user-read-currently-playing",
            "app-remote-control",
            "streaming",
            "playlist-read-private",
            "playlist-read-collaborative",
            "user-library-read"
        ]
    }
    
    // MARK: - Audio
    enum Audio {
        static let supportedLocalFormats = ["mp3", "m4a", "wav", "aac", "flac", "aiff", "caf"]
        static let defaultVolume: Float = 0.8
        static let seekInterval: TimeInterval = 15.0
    }
    
    // MARK: - iCloud
    enum iCloud {
        // Set to nil to use the default container
        // Or specify your container ID like: "iCloud.com.yourname.muze"
        static let containerIdentifier: String? = nil
        
        // Folder structure in iCloud Drive
        static let musicFolderName = "Muze/Music"
        
        // Auto-sync settings
        static let autoSyncOnLaunch = true
        static let syncIntervalMinutes: TimeInterval = 30
    }
    
    // MARK: - UI
    enum UI {
        static let miniPlayerHeight: CGFloat = 70
        static let artworkCornerRadius: CGFloat = 8
        static let defaultArtworkSize: CGFloat = 50
        static let largeArtworkSize: CGFloat = 300
        
        enum Animation {
            static let defaultDuration: TimeInterval = 0.3
            static let springResponse: Double = 0.4
            static let springDamping: Double = 0.8
        }
    }
    
    // MARK: - Storage
    enum Storage {
        static let playlistsKey = "com.muze.playlists"
        static let tracksKey = "com.muze.tracks"
        static let settingsKey = "com.muze.settings"
    }
    
    // MARK: - Limits
    enum Limits {
        static let maxPlaylistNameLength = 100
        static let maxPlaylistDescriptionLength = 500
        static let maxTracksPerPlaylist = 10000
        static let searchResultsLimit = 50
    }
}

