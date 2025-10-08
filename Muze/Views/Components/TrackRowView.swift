//
//  TrackRowView.swift
//  Muze
//
//  Created on October 7, 2025.
//

import SwiftUI

struct TrackRowView: View {
    let track: Track
    
    var body: some View {
        HStack(spacing: 12) {
            // Track Artwork
            RoundedRectangle(cornerRadius: 6)
                .fill(.gray.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: track.source.iconName)
                        .foregroundStyle(.gray)
                }
            
            // Track Info
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(track.artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    if let album = track.album {
                        Text("•")
                            .foregroundStyle(.secondary)
                        
                        Text(album)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Duration and Source Indicator
            VStack(alignment: .trailing, spacing: 4) {
                Text(track.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Image(systemName: track.source == .spotify ? "s.circle.fill" : "l.circle.fill")
                    .font(.caption)
                    .foregroundStyle(track.source == .spotify ? .green : .blue)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        TrackRowView(track: .sample)
        TrackRowView(track: Track.samples[0])
        TrackRowView(track: Track.samples[1])
    }
}

