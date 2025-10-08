//
//  LocalAudioService.swift
//  Muze
//
//  Created on October 7, 2025.
//

import Foundation
import AVFoundation
import Combine

/// Handles playback of local and iCloud Drive audio files using AVFoundation
@MainActor
class LocalAudioService: NSObject, AVAudioPlayerDelegate {
    // MARK: - Properties
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private let iCloudManager: iCloudDriveManager
    private var currentFileURL: URL?
    
    var isPlaying: Bool {
        audioPlayer?.isPlaying ?? false
    }
    
    var currentTime: TimeInterval {
        audioPlayer?.currentTime ?? 0
    }
    
    var duration: TimeInterval {
        audioPlayer?.duration ?? 0
    }
    
    // MARK: - Callbacks
    
    var onPlaybackFinished: (() -> Void)?
    var onTimeUpdate: ((TimeInterval) -> Void)?
    var onDownloadProgress: ((Double) -> Void)?
    
    // MARK: - Initialization
    
    init(iCloudManager: iCloudDriveManager) {
        self.iCloudManager = iCloudManager
        super.init()
        configureAudioSession()
    }
    
    deinit {
        // Clean up without calling stop() due to actor isolation
        playbackTimer?.invalidate()
        audioPlayer?.stop()
    }
    
    // MARK: - Audio Session Configuration
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            AppLogger.logLocalAudio("Audio session configured successfully")
        } catch {
            AppLogger.logLocalAudio("Failed to configure audio session: \(error)", level: .error)
        }
    }
    
    // MARK: - Playback Control
    
    /// Plays an audio file from a URL (local or iCloud Drive)
    func play(url: URL) async {
        stop()
        currentFileURL = url
        
        AppLogger.logLocalAudio("Starting playback for: \(url.lastPathComponent)")
        
        // Check if this is an iCloud file
        if url.path.contains("Mobile Documents") || url.path.contains("iCloud") {
            // iCloud file - ensure it's downloaded first
            do {
                AppLogger.logLocalAudio("iCloud file detected, checking download status...")
                try await iCloudManager.downloadFileIfNeeded(url)
                AppLogger.logLocalAudio("File ready for playback")
            } catch {
                AppLogger.logLocalAudio("Failed to download iCloud file: \(error)", level: .error)
                return
            }
        }
        
        // Play the file
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self  // Set delegate to receive callbacks
            
            let success = audioPlayer?.prepareToPlay() ?? false
            AppLogger.logLocalAudio("Prepare to play: \(success)")
            
            if let player = audioPlayer {
                AppLogger.logLocalAudio("Player duration: \(player.duration) seconds")
                AppLogger.logLocalAudio("Player volume: \(player.volume)")
                
                let didPlay = player.play()
                AppLogger.logLocalAudio("Did start playing: \(didPlay)")
                AppLogger.logLocalAudio("Is playing: \(player.isPlaying)")
                
                if didPlay {
                    startPlaybackTimer()
                    AppLogger.logLocalAudio("✅ Started playback: \(url.lastPathComponent)")
                } else {
                    AppLogger.logLocalAudio("❌ Failed to start playback", level: .error)
                }
            }
        } catch {
            AppLogger.logLocalAudio("❌ Failed to create audio player: \(error)", level: .error)
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        stopPlaybackTimer()
    }
    
    func resume() {
        audioPlayer?.play()
        startPlaybackTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentFileURL = nil
        stopPlaybackTimer()
    }
    
    // MARK: - iCloud Status
    
    /// Checks if the current file is fully downloaded
    @MainActor
    func isCurrentFileDownloaded() -> Bool {
        guard let url = currentFileURL else { return false }
        return iCloudManager.isFileDownloaded(url)
    }
    
    /// Gets download progress for the current file
    @MainActor
    func currentFileDownloadProgress() -> Double? {
        guard let url = currentFileURL else { return nil }
        return iCloudManager.downloadProgress(for: url)
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        onTimeUpdate?(time)
    }
    
    // MARK: - Private Methods
    
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let player = self.audioPlayer {
                    if player.isPlaying {
                        self.onTimeUpdate?(player.currentTime)
                    } else if player.currentTime >= player.duration - 0.1 {
                        self.onPlaybackFinished?()
                        self.stop()
                    }
                }
            }
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            AppLogger.logLocalAudio("Audio player finished playing. Success: \(flag)")
            onPlaybackFinished?()
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            if let error = error {
                AppLogger.logLocalAudio("Audio player decode error: \(error)", level: .error)
            }
        }
    }
}

