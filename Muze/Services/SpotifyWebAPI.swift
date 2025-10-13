//
//  SpotifyWebAPI.swift
//  Muze
//
//  Created on October 13, 2025.
//

import Foundation

/// Client for Spotify Web API
/// Handles search, metadata fetching, and playlist operations
class SpotifyWebAPI {
    // MARK: - Properties
    
    private var accessToken: String?
    private let baseURL = "https://api.spotify.com/v1"
    
    // MARK: - Initialization
    
    init(accessToken: String? = nil) {
        self.accessToken = accessToken
    }
    
    // MARK: - Token Management
    
    func setAccessToken(_ token: String) {
        self.accessToken = token
    }
    
    // MARK: - Search
    
    /// Search for tracks on Spotify
    func searchTracks(query: String, limit: Int = 20) async throws -> [SpotifyTrack] {
        guard let token = accessToken else {
            throw SpotifyError.notAuthenticated
        }
        
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "track"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let url = components.url else {
            throw SpotifyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpotifyError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw SpotifyError.apiError(statusCode: httpResponse.statusCode)
        }
        
        let searchResponse = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
        return searchResponse.tracks.items
    }
    
    /// Search for albums on Spotify
    func searchAlbums(query: String, limit: Int = 20) async throws -> [SpotifyAlbum] {
        guard let token = accessToken else {
            throw SpotifyError.notAuthenticated
        }
        
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "album"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let url = components.url else {
            throw SpotifyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpotifyError.invalidResponse
        }
        
        let searchResponse = try JSONDecoder().decode(SpotifyAlbumSearchResponse.self, from: data)
        return searchResponse.albums.items
    }
    
    // MARK: - Track Information
    
    /// Get detailed track information
    func getTrack(id: String) async throws -> SpotifyTrack {
        guard let token = accessToken else {
            throw SpotifyError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/tracks/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpotifyError.invalidResponse
        }
        
        return try JSONDecoder().decode(SpotifyTrack.self, from: data)
    }
    
    // MARK: - Playlists
    
    /// Get user's playlists
    func getUserPlaylists(limit: Int = 50) async throws -> [SpotifyPlaylist] {
        guard let token = accessToken else {
            throw SpotifyError.notAuthenticated
        }
        
        var components = URLComponents(string: "\(baseURL)/me/playlists")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let url = components.url else {
            throw SpotifyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpotifyError.invalidResponse
        }
        
        let playlistsResponse = try JSONDecoder().decode(SpotifyPlaylistsResponse.self, from: data)
        return playlistsResponse.items
    }
    
    /// Get tracks from a playlist
    func getPlaylistTracks(playlistId: String) async throws -> [SpotifyTrack] {
        guard let token = accessToken else {
            throw SpotifyError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/playlists/\(playlistId)/tracks")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpotifyError.invalidResponse
        }
        
        let tracksResponse = try JSONDecoder().decode(SpotifyPlaylistTracksResponse.self, from: data)
        return tracksResponse.items.compactMap { $0.track }
    }
    
    // MARK: - User Library
    
    /// Get user's saved tracks
    func getSavedTracks(limit: Int = 50) async throws -> [SpotifyTrack] {
        guard let token = accessToken else {
            throw SpotifyError.notAuthenticated
        }
        
        var components = URLComponents(string: "\(baseURL)/me/tracks")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let url = components.url else {
            throw SpotifyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpotifyError.invalidResponse
        }
        
        let savedTracksResponse = try JSONDecoder().decode(SpotifySavedTracksResponse.self, from: data)
        return savedTracksResponse.items.map { $0.track }
    }
}

// MARK: - Response Models

struct SpotifySearchResponse: Codable {
    let tracks: SpotifyTracksResponse
}

struct SpotifyTracksResponse: Codable {
    let items: [SpotifyTrack]
}

struct SpotifyTrack: Codable {
    let id: String
    let uri: String
    let name: String
    let artists: [SpotifyArtist]
    let album: SpotifyAlbum
    let duration_ms: Int
    let explicit: Bool
    
    var artistName: String {
        artists.map { $0.name }.joined(separator: ", ")
    }
    
    var durationSeconds: TimeInterval {
        TimeInterval(duration_ms) / 1000.0
    }
}

struct SpotifyArtist: Codable {
    let id: String
    let name: String
    let uri: String
}

struct SpotifyAlbum: Codable {
    let id: String
    let name: String
    let uri: String
    let images: [SpotifyImage]?
    let release_date: String?
    
    var artworkURL: URL? {
        images?.first?.url
    }
}

struct SpotifyImage: Codable {
    let url: URL
    let height: Int?
    let width: Int?
}

struct SpotifyAlbumSearchResponse: Codable {
    let albums: SpotifyAlbumsResponse
}

struct SpotifyAlbumsResponse: Codable {
    let items: [SpotifyAlbum]
}

struct SpotifyPlaylistsResponse: Codable {
    let items: [SpotifyPlaylist]
}

struct SpotifyPlaylist: Codable {
    let id: String
    let name: String
    let description: String?
    let images: [SpotifyImage]?
    let tracks: SpotifyPlaylistTracksInfo
    
    var artworkURL: URL? {
        images?.first?.url
    }
}

struct SpotifyPlaylistTracksInfo: Codable {
    let total: Int
}

struct SpotifyPlaylistTracksResponse: Codable {
    let items: [SpotifyPlaylistTrackItem]
}

struct SpotifyPlaylistTrackItem: Codable {
    let track: SpotifyTrack?
}

struct SpotifySavedTracksResponse: Codable {
    let items: [SpotifySavedTrackItem]
}

struct SpotifySavedTrackItem: Codable {
    let track: SpotifyTrack
}

// MARK: - Track Conversion

extension SpotifyTrack {
    /// Convert SpotifyTrack to Muze Track model
    func toTrack() -> Track {
        // Extract year from release date
        var year: Int?
        if let releaseDate = album.release_date {
            let components = releaseDate.split(separator: "-")
            if let firstComponent = components.first {
                year = Int(firstComponent)
            }
        }
        
        return Track(
            title: name,
            artist: artistName,
            album: album.name,
            duration: durationSeconds,
            source: .spotify,
            spotifyURI: uri,
            artworkURL: album.artworkURL,
            year: year
        )
    }
}

// MARK: - Error Types

enum SpotifyError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with Spotify"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from Spotify"
        case .apiError(let statusCode):
            return "Spotify API error: \(statusCode)"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

