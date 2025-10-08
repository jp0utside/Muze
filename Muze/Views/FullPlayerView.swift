//
//  FullPlayerView.swift
//  Muze
//
//  Created on October 7, 2025.
//

import SwiftUI

struct FullPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var playbackCoordinator: PlaybackCoordinator
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    if let track = playbackCoordinator.currentTrack {
                        Image(systemName: track.source == .spotify ? "s.circle.fill" : "l.circle.fill")
                            .font(.title3)
                            .foregroundStyle(track.source == .spotify ? .green : .blue)
                    }
                }
                .padding()
                
                Spacer()
                
                // Artwork
                if let track = playbackCoordinator.currentTrack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.gray.opacity(0.2))
                        .frame(width: 300, height: 300)
                        .overlay {
                            Image(systemName: track.source.iconName)
                                .font(.system(size: 80))
                                .foregroundStyle(.gray)
                        }
                        .shadow(radius: 20)
                }
                
                Spacer()
                
                // Track Info
                if let track = playbackCoordinator.currentTrack {
                    VStack(spacing: 8) {
                        Text(track.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(track.artist)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Progress Bar
                VStack(spacing: 8) {
                    ProgressView(value: playbackCoordinator.currentTime, total: playbackCoordinator.duration)
                        .tint(.primary)
                    
                    HStack {
                        Text(formatTime(playbackCoordinator.currentTime))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(formatTime(playbackCoordinator.duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Playback Controls
                HStack(spacing: 40) {
                    Button {
                        playbackCoordinator.toggleShuffle()
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.title3)
                            .foregroundStyle(playbackCoordinator.shuffleEnabled ? .blue : .secondary)
                    }
                    
                    Button {
                        playbackCoordinator.previous()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title)
                    }
                    
                    Button {
                        playbackCoordinator.playPause()
                    } label: {
                        Image(systemName: playbackCoordinator.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 70))
                    }
                    
                    Button {
                        playbackCoordinator.next()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title)
                    }
                    
                    Button {
                        playbackCoordinator.toggleRepeat()
                    } label: {
                        Image(systemName: playbackCoordinator.repeatMode.iconName)
                            .font(.title3)
                            .foregroundStyle(playbackCoordinator.repeatMode == .off ? Color.secondary : Color.blue)
                    }
                }
                .foregroundStyle(.primary)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    FullPlayerView()
        .environmentObject(PlaybackCoordinator())
}

