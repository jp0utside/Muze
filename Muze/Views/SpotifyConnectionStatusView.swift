//
//  SpotifyConnectionStatusView.swift
//  Muze
//
//  Created on October 13, 2025.
//

import SwiftUI

/// Shows Spotify connection status and troubleshooting
struct SpotifyConnectionStatusView: View {
    @ObservedObject var spotifyService: SpotifyService
    @ObservedObject var authManager: SpotifyAuthManager
    
    var body: some View {
        VStack(spacing: 16) {
            if !authManager.isAuthenticated {
                statusCard(
                    icon: "xmark.circle.fill",
                    color: .red,
                    title: "Not Signed In",
                    message: "Go to Settings → Spotify to sign in"
                )
            } else if !spotifyService.isConnected {
                statusCard(
                    icon: "exclamationmark.triangle.fill",
                    color: .orange,
                    title: "Spotify Not Connected",
                    message: "To play Spotify tracks:"
                )
                
                VStack(alignment: .leading, spacing: 12) {
                    instructionRow(number: "1", text: "Make sure Spotify app is installed")
                    instructionRow(number: "2", text: "Open Spotify and start playing any song")
                    instructionRow(number: "3", text: "Keep Spotify running in background")
                    instructionRow(number: "4", text: "Come back to Muze and try again")
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                Text("Note: Spotify Premium required for remote playback")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                statusCard(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    title: "Connected to Spotify",
                    message: "Ready to play!"
                )
            }
        }
        .padding()
    }
    
    private func statusCard(icon: String, color: Color, title: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.green)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

#Preview {
    let authManager = SpotifyAuthManager(
        clientID: "test",
        redirectURI: "muze://callback/",
        scopes: []
    )
    let spotifyService = SpotifyService(authManager: authManager)
    
    return SpotifyConnectionStatusView(
        spotifyService: spotifyService,
        authManager: authManager
    )
}

