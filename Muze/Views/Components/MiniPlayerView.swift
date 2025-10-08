//
//  MiniPlayerView.swift
//  Muze
//
//  Created on October 7, 2025.
//

import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var playbackCoordinator: PlaybackCoordinator
    @State private var showingFullPlayer = false
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Track Artwork
                if let track = playbackCoordinator.currentTrack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.gray.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: track.source.iconName)
                                .foregroundStyle(.gray)
                        }
                    
                    // Track Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text(track.artist)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Playback Controls
                    HStack(spacing: 20) {
                        Button {
                            playbackCoordinator.playPause()
                        } label: {
                            Image(systemName: playbackCoordinator.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title3)
                                .foregroundStyle(.primary)
                        }
                        
                        Button {
                            playbackCoordinator.next()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.title3)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .onTapGesture {
                showingFullPlayer = true
            }
        }
        .sheet(isPresented: $showingFullPlayer) {
            FullPlayerView()
        }
    }
}

#Preview {
    MiniPlayerView()
        .environmentObject({
            let coordinator = PlaybackCoordinator()
            // Simulate having a current track
            return coordinator
        }())
}

