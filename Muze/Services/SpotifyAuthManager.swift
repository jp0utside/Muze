//
//  SpotifyAuthManager.swift
//  Muze
//
//  Created on October 13, 2025.
//

import Foundation
import Combine
import CommonCrypto

/// Manages Spotify OAuth authentication flow
class SpotifyAuthManager: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isAuthenticated: Bool = false
    @Published var accessToken: String?
    @Published var refreshToken: String?
    @Published var expirationDate: Date?
    
    // MARK: - Properties
    
    let clientID: String
    let redirectURI: String
    private let scopes: [String]
    private let tokenKey = "com.muze.spotify.accessToken"
    private let refreshTokenKey = "com.muze.spotify.refreshToken"
    private let expirationKey = "com.muze.spotify.expirationDate"
    
    private var refreshTimer: Timer?
    private var codeVerifier: String?
    private var codeChallenge: String?
    
    // MARK: - Initialization
    
    init(clientID: String, redirectURI: String, scopes: [String]) {
        self.clientID = clientID
        self.redirectURI = redirectURI
        self.scopes = scopes
        
        // Load saved tokens
        loadTokens()
        
        // Check if token is still valid
        checkTokenValidity()
        
        // Set up auto-refresh timer
        if isAuthenticated {
            scheduleTokenRefresh()
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Authentication
    
    /// Generate authorization URL for OAuth flow with PKCE
    func getAuthorizationURL() -> URL? {
        // Generate PKCE code verifier and challenge
        generatePKCECodes()
        
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "show_dialog", value: "true")
        ]
        return components.url
    }
    
    /// Generate PKCE code verifier and challenge
    private func generatePKCECodes() {
        // Generate a random code verifier (43-128 characters)
        let verifier = generateRandomString(length: 128)
        codeVerifier = verifier
        
        // Generate code challenge (SHA256 hash of verifier, base64url encoded)
        if let data = verifier.data(using: .utf8),
           let hash = sha256(data: data) {
            codeChallenge = base64URLEncode(data: hash)
        }
    }
    
    private func generateRandomString(length: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }
    
    private func sha256(data: Data) -> Data? {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
    
    private func base64URLEncode(data: Data) -> String {
        var base64 = data.base64EncodedString()
        base64 = base64.replacingOccurrences(of: "+", with: "-")
        base64 = base64.replacingOccurrences(of: "/", with: "_")
        base64 = base64.replacingOccurrences(of: "=", with: "")
        return base64
    }
    
    /// Handle authorization callback with code
    func handleAuthorizationCallback(code: String) async throws {
        let token = try await exchangeCodeForToken(code: code)
        saveTokens(accessToken: token.accessToken, 
                   refreshToken: token.refreshToken, 
                   expiresIn: token.expiresIn)
        
        await MainActor.run {
            self.accessToken = token.accessToken
            self.refreshToken = token.refreshToken
            self.expirationDate = Date().addingTimeInterval(TimeInterval(token.expiresIn))
            self.isAuthenticated = true
            scheduleTokenRefresh()
        }
    }
    
    /// Exchange authorization code for access token
    private func exchangeCodeForToken(code: String) async throws -> TokenResponse {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "code_verifier", value: codeVerifier)
        ]
        
        request.httpBody = components.query?.data(using: .utf8)
        
        // Debug logging
        print("🔐 Token Exchange Request:")
        print("🔐   URL: \(url.absoluteString)")
        print("🔐   Method: \(request.httpMethod ?? "nil")")
        print("🔐   Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "nil")")
        print("🔐   redirect_uri we're sending: \(redirectURI)")
        print("🔐   client_id: \(clientID)")
        print("🔐   code (first 20 chars): \(String(code.prefix(20)))...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🔐 ❌ No HTTP response received")
            throw SpotifyAuthError.tokenExchangeFailed
        }
        
        print("🔐 Token Exchange Response:")
        print("🔐   Status Code: \(httpResponse.statusCode)")
        print("🔐   Response Body: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        guard httpResponse.statusCode == 200 else {
            print("🔐 ❌ Token exchange failed with status \(httpResponse.statusCode)")
            throw SpotifyAuthError.tokenExchangeFailed
        }
        
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }
    
    // MARK: - Token Refresh
    
    /// Refresh the access token using refresh token
    func refreshAccessToken() async throws {
        guard let refreshToken = refreshToken else {
            throw SpotifyAuthError.noRefreshToken
        }
        
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "client_id", value: clientID)
        ]
        
        request.httpBody = components.query?.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpotifyAuthError.tokenRefreshFailed
        }
        
        let token = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
        saveTokens(accessToken: token.accessToken, 
                   refreshToken: refreshToken, 
                   expiresIn: token.expiresIn)
        
        await MainActor.run {
            self.accessToken = token.accessToken
            self.expirationDate = Date().addingTimeInterval(TimeInterval(token.expiresIn))
            self.isAuthenticated = true
        }
    }
    
    /// Schedule automatic token refresh
    private func scheduleTokenRefresh() {
        refreshTimer?.invalidate()
        
        guard let expirationDate = expirationDate else { return }
        
        // Refresh 5 minutes before expiration
        let refreshDate = expirationDate.addingTimeInterval(-300)
        let timeInterval = refreshDate.timeIntervalSinceNow
        
        if timeInterval > 0 {
            refreshTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                Task {
                    try? await self?.refreshAccessToken()
                }
            }
        }
    }
    
    // MARK: - Token Storage
    
    private func saveTokens(accessToken: String, refreshToken: String, expiresIn: Int) {
        UserDefaults.standard.set(accessToken, forKey: tokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
        let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        UserDefaults.standard.set(expirationDate, forKey: expirationKey)
    }
    
    private func loadTokens() {
        accessToken = UserDefaults.standard.string(forKey: tokenKey)
        refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey)
        expirationDate = UserDefaults.standard.object(forKey: expirationKey) as? Date
    }
    
    private func checkTokenValidity() {
        guard let expirationDate = expirationDate,
              expirationDate > Date() else {
            isAuthenticated = false
            return
        }
        
        isAuthenticated = accessToken != nil
    }
    
    // MARK: - Logout
    
    func logout() {
        accessToken = nil
        refreshToken = nil
        expirationDate = nil
        isAuthenticated = false
        
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: expirationKey)
        
        refreshTimer?.invalidate()
    }
}

// MARK: - Response Models

struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let expiresIn: Int
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case expiresIn = "expires_in"
    }
}

// MARK: - Error Types

enum SpotifyAuthError: LocalizedError {
    case tokenExchangeFailed
    case tokenRefreshFailed
    case noRefreshToken
    case invalidAuthorizationCode
    
    var errorDescription: String? {
        switch self {
        case .tokenExchangeFailed:
            return "Failed to exchange authorization code for token"
        case .tokenRefreshFailed:
            return "Failed to refresh access token"
        case .noRefreshToken:
            return "No refresh token available"
        case .invalidAuthorizationCode:
            return "Invalid authorization code"
        }
    }
}

