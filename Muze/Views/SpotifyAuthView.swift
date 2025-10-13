//
//  SpotifyAuthView.swift
//  Muze
//
//  Created on October 13, 2025.
//

import SwiftUI
import SwiftData
import SafariServices
import Combine

/// View for Spotify authentication
struct SpotifyAuthView: View {
    @ObservedObject var authManager: SpotifyAuthManager
    let spotifyService: SpotifyService
    let playlistManager: PlaylistManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showingSafari = false
    @State private var authorizationURL: URL?
    @State private var isLoading = false
    @State private var isImporting = false
    @State private var importProgress: (imported: Int, total: Int) = (0, 0)
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Spotify logo placeholder
                Image(systemName: "music.note.list")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                VStack(spacing: 12) {
                    Text("Connect to Spotify")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Sign in to access your Spotify library, playlists, and playback")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if authManager.isAuthenticated {
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Connected to Spotify")
                                .font(.headline)
                        }
                        
                        if isImporting {
                            VStack(spacing: 12) {
                                ProgressView(value: Double(importProgress.imported), total: Double(importProgress.total))
                                    .padding(.horizontal, 32)
                                
                                Text("Importing \(importProgress.imported) of \(importProgress.total) tracks...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        } else {
                            Button {
                                importLikedSongs()
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Import Liked Songs")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 32)
                            
                            if let successMessage = successMessage {
                                Text(successMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                    .padding(.horizontal)
                            }
                        }
                        
                        Button("Disconnect") {
                            authManager.logout()
                            successMessage = nil
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(isImporting)
                    }
                } else {
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .padding()
                        } else {
                            Button {
                                startAuthentication()
                            } label: {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                    Text("Sign in with Spotify")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 32)
                        }
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                    }
                }
                
                VStack(spacing: 8) {
                    Text("Why connect?")
                        .font(.headline)
                        .padding(.top)
                    
                    FeatureRow(icon: "music.note", text: "Access your Spotify library")
                    FeatureRow(icon: "rectangle.stack.fill", text: "Import your playlists")
                    FeatureRow(icon: "magnifyingglass", text: "Search millions of tracks")
                    FeatureRow(icon: "square.stack.fill", text: "Mix Spotify and local music")
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Spotify")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSafari) {
                if let url = authorizationURL {
                    SafariView(url: url)
                }
            }
            .onAppear {
                // Listen for authentication changes
                authManager.$isAuthenticated
                    .sink { authenticated in
                        if authenticated {
                            showingSafari = false
                            isLoading = false
                        }
                    }
                    .store(in: &cancellables)
            }
        }
    }
    
    private func startAuthentication() {
        guard let url = authManager.getAuthorizationURL() else {
            errorMessage = "Failed to generate authorization URL"
            return
        }
        
        // Debug: Print the URL we're using
        print("🔐 Spotify Auth URL: \(url.absoluteString)")
        print("🔐 Redirect URI we're requesting: muze://callback")
        print("🔐 Client ID: \(authManager.clientID)")
        
        authorizationURL = url
        showingSafari = true
        isLoading = true
        errorMessage = nil
    }
    
    private func importLikedSongs() {
        isImporting = true
        errorMessage = nil
        successMessage = nil
        importProgress = (0, 0)
        
        Task {
            do {
                let count = try await playlistManager.importSpotifyLikedSongs(
                    spotifyService: spotifyService
                ) { imported, total in
                    importProgress = (imported, total)
                }
                
                await MainActor.run {
                    isImporting = false
                    successMessage = "✓ Imported \(count) new tracks!"
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    errorMessage = "Import failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safari = SFSafariViewController(url: url)
        safari.preferredControlTintColor = .systemGreen
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Track.self, Playlist.self, configurations: config)
    let context = container.mainContext
    let authManager = SpotifyAuthManager(
        clientID: "test",
        redirectURI: "muze://callback",
        scopes: []
    )
    
    return SpotifyAuthView(
        authManager: authManager,
        spotifyService: SpotifyService(authManager: authManager),
        playlistManager: PlaylistManager(modelContext: context)
    )
    .modelContainer(container)
}

