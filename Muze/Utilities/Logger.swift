//
//  Logger.swift
//  Muze
//
//  Created on October 7, 2025.
//

import Foundation
import OSLog

/// Centralized logging utility for the app
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.muze"
    
    // MARK: - Logger Categories
    
    static let playback = Logger(subsystem: subsystem, category: "Playback")
    static let spotify = Logger(subsystem: subsystem, category: "Spotify")
    static let localAudio = Logger(subsystem: subsystem, category: "LocalAudio")
    static let playlist = Logger(subsystem: subsystem, category: "Playlist")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    
    // MARK: - Convenience Methods
    
    static func logPlayback(_ message: String, level: LogLevel = .info) {
        log(message, to: playback, level: level)
    }
    
    static func logSpotify(_ message: String, level: LogLevel = .info) {
        log(message, to: spotify, level: level)
    }
    
    static func logLocalAudio(_ message: String, level: LogLevel = .info) {
        log(message, to: localAudio, level: level)
    }
    
    static func logPlaylist(_ message: String, level: LogLevel = .info) {
        log(message, to: playlist, level: level)
    }
    
    static func logUI(_ message: String, level: LogLevel = .info) {
        log(message, to: ui, level: level)
    }
    
    static func logError(_ error: Error, category: Logger = playback) {
        category.error("\(error.localizedDescription)")
    }
    
    // MARK: - Private Helpers
    
    private static func log(_ message: String, to logger: Logger, level: LogLevel) {
        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        case .fault:
            logger.fault("\(message)")
        }
    }
}

// MARK: - Log Level

enum LogLevel {
    case debug
    case info
    case warning
    case error
    case fault
}

// MARK: - Usage Example
/*
 
 // In your code:
 AppLogger.logPlayback("Starting playback for track: \(track.title)")
 AppLogger.logSpotify("Spotify authentication successful", level: .info)
 AppLogger.logError(error, category: AppLogger.localAudio)
 
 */

