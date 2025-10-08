//
//  PlaybackQueue.swift
//  Muze
//
//  Created on October 7, 2025.
//

import Foundation

/// Manages the playback queue with support for multiple track sources
struct PlaybackQueue {
    private(set) var tracks: [Track]
    private(set) var currentIndex: Int?
    private(set) var history: [Track] = []
    
    var currentTrack: Track? {
        guard let index = currentIndex, tracks.indices.contains(index) else {
            return nil
        }
        return tracks[index]
    }
    
    var hasNext: Bool {
        guard let index = currentIndex else { return !tracks.isEmpty }
        return index < tracks.count - 1
    }
    
    var hasPrevious: Bool {
        guard let index = currentIndex else { return false }
        return index > 0
    }
    
    var upcomingTracks: [Track] {
        guard let index = currentIndex, index < tracks.count - 1 else {
            return []
        }
        return Array(tracks[(index + 1)...])
    }
    
    init(tracks: [Track] = [], currentIndex: Int? = nil) {
        self.tracks = tracks
        self.currentIndex = currentIndex
    }
    
    mutating func setQueue(_ newTracks: [Track], startAt index: Int = 0) {
        tracks = newTracks
        currentIndex = tracks.isEmpty ? nil : index
    }
    
    mutating func addToQueue(_ track: Track) {
        tracks.append(track)
    }
    
    mutating func addToQueue(_ newTracks: [Track]) {
        tracks.append(contentsOf: newTracks)
    }
    
    mutating func addNext(_ track: Track) {
        if let index = currentIndex {
            tracks.insert(track, at: index + 1)
        } else {
            tracks.insert(track, at: 0)
            currentIndex = 0
        }
    }
    
    mutating func next() -> Track? {
        guard hasNext else { return nil }
        
        if let current = currentTrack {
            history.append(current)
        }
        
        currentIndex = (currentIndex ?? -1) + 1
        return currentTrack
    }
    
    mutating func previous() -> Track? {
        guard hasPrevious else { return nil }
        
        currentIndex = (currentIndex ?? 0) - 1
        return currentTrack
    }
    
    mutating func skipTo(index: Int) -> Track? {
        guard tracks.indices.contains(index) else { return nil }
        
        if let current = currentTrack {
            history.append(current)
        }
        
        currentIndex = index
        return currentTrack
    }
    
    mutating func removeTrack(at index: Int) {
        guard tracks.indices.contains(index) else { return }
        
        tracks.remove(at: index)
        
        if let currentIdx = currentIndex {
            if index < currentIdx {
                currentIndex = currentIdx - 1
            } else if index == currentIdx {
                currentIndex = tracks.isEmpty ? nil : min(currentIdx, tracks.count - 1)
            }
        }
    }
    
    mutating func clear() {
        tracks.removeAll()
        currentIndex = nil
        history.removeAll()
    }
    
    mutating func shuffle() {
        guard !tracks.isEmpty else { return }
        
        let currentTrackToPreserve = currentTrack
        tracks.shuffle()
        
        // Keep current track at the front if there was one playing
        if let track = currentTrackToPreserve,
           let index = tracks.firstIndex(where: { $0.id == track.id }) {
            tracks.swapAt(index, 0)
            currentIndex = 0
        }
    }
}

