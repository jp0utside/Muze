//
//  Extensions.swift
//  Muze
//
//  Created on October 7, 2025.
//

import Foundation
import SwiftUI

// MARK: - TimeInterval Extensions

extension TimeInterval {
    /// Formats a time interval as MM:SS
    var formattedTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Formats a time interval as HH:MM:SS for longer durations
    var formattedLongTime: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Date Extensions

extension Date {
    /// Returns a human-readable relative time string (e.g., "2 hours ago")
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Returns a formatted date string (e.g., "Oct 7, 2025")
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

// MARK: - Array Extensions

extension Array where Element == Track {
    /// Total duration of all tracks in the array
    var totalDuration: TimeInterval {
        reduce(0) { $0 + $1.duration }
    }
    
    /// Groups tracks by artist
    func groupedByArtist() -> [String: [Track]] {
        Dictionary(grouping: self) { $0.artist }
    }
    
    /// Groups tracks by album
    func groupedByAlbum() -> [String: [Track]] {
        Dictionary(grouping: self) { $0.album ?? "Unknown Album" }
    }
    
    /// Groups tracks by source
    func groupedBySource() -> [TrackSource: [Track]] {
        Dictionary(grouping: self) { $0.source }
    }
}

// MARK: - Color Extensions

extension Color {
    /// Creates a color from a hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Spotify brand green
    static let spotifyGreen = Color(hex: "1DB954")
    
    /// Custom app accent color
    static let appAccent = Color.blue
}

// MARK: - View Extensions

extension View {
    /// Applies a card-like styling to a view
    func cardStyle() -> some View {
        self
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// Conditionally applies a modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - String Extensions

extension String {
    /// Truncates a string to a specified length and adds ellipsis
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        }
        return self
    }
    
    /// Returns true if string is not empty after trimming whitespace
    var isNotEmpty: Bool {
        !self.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

// MARK: - URL Extensions

extension URL {
    /// Returns true if the URL points to a local file
    var isLocalFile: Bool {
        scheme == "file"
    }
    
    /// Returns the file extension in lowercase
    var lowercasedExtension: String {
        pathExtension.lowercased()
    }
    
    /// Returns true if the URL is a supported audio file
    var isSupportedAudioFile: Bool {
        Constants.Audio.supportedLocalFormats.contains(lowercasedExtension)
    }
}

