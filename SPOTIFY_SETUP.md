# Spotify Integration Setup Guide

Complete guide to setting up Spotify integration for Muze.

## 📋 Overview

Muze integrates with Spotify to allow you to:
- Import your Spotify liked songs into your library
- Play Spotify tracks alongside local files
- Create unified playlists mixing Spotify and local music

## 🔧 Prerequisites

Before you begin, you'll need:
1. A Spotify account (free or premium)
2. The Spotify mobile app installed on your iOS device
3. A Spotify Developer account (free to create)

## 📝 Step-by-Step Setup

### 1. Create a Spotify Developer App

1. Go to the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Log in with your Spotify account
3. Click **"Create app"**
4. Fill in the application details:
   - **App name**: `Muze` (or any name you prefer)
   - **App description**: `iOS music player integrating Spotify and local audio files`
   - **Website**: `https://yourwebsite.com` (can be any URL)
   - **Redirect URI**: `muze://callback` ⚠️ **IMPORTANT: Must be exactly this**
5. Check the boxes to agree to the Terms of Service
6. Click **"Save"**

### 2. Get Your Client ID

After creating the app:
1. You'll be taken to your app's dashboard
2. Copy the **Client ID** (it looks like: `abc123def456ghi789jkl012mno345pq`)
3. Keep this handy - you'll need it in the next step

### 3. Configure Muze

Open `Muze/Utilities/Constants.swift` and update the Spotify configuration:

```swift
enum Spotify {
    // Replace with your Client ID from the Spotify Dashboard
    static let clientID = "YOUR_CLIENT_ID_HERE"
    
    // This MUST match the Redirect URI in your Spotify app settings
    static let redirectURI = "muze://callback"
    
    // Scopes define what permissions the app requests
    static let scopes = [
        "user-read-playback-state",      // Read current playback state
        "user-modify-playback-state",    // Control playback
        "user-read-currently-playing",   // Read currently playing track
        "app-remote-control",            // Control Spotify app remotely
        "streaming",                     // Stream audio
        "user-library-read"              // Read saved/liked tracks
    ]
}
```

**Example:**
```swift
enum Spotify {
    static let clientID = "1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p"
    static let redirectURI = "muze://callback"
    // ... rest stays the same
}
```

> **Note**: If this is your first build after cloning the repo, the Xcode project will automatically fetch the Spotify SDK dependency when you build.

### 4. Configure URL Scheme (If Not Already Configured)

The app needs to handle the OAuth callback URL. This should already be configured in `Info.plist`, but verify:

1. Open `Muze/Info.plist`
2. Ensure it contains the URL scheme configuration:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>muze</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.muze.auth</string>
    </dict>
</array>
```

### 4. Build and Run

```bash
# Clean and build (first build will download Spotify SDK)
make clean
make build

# Run on simulator or device
make run
```

Or use Xcode:
```
⌘ + Shift + K (Clean)
⌘ + R (Run)
```

> **First Build Note**: The first build after configuration may take a bit longer as Xcode downloads the Spotify iOS SDK (~5-10 seconds).

### 5. Using Spotify Integration

### Connecting to Spotify

1. Launch Muze
2. Go to the **Settings** tab (gear icon)
3. Tap **"Spotify"**
4. Tap **"Sign in with Spotify"**
5. You'll be taken to Spotify's login page
6. Log in and authorize Muze
7. You'll be redirected back to the app

### Importing Your Liked Songs

After connecting:
1. You'll see an **"Import Liked Songs"** button
2. Tap it to start importing
3. Progress will be shown as tracks are imported
4. All your Spotify liked songs will be added to your library
5. You can now play them, add them to playlists, and mix them with local tracks!

### Playing Spotify Tracks

**Requirements:**
- The Spotify app must be installed on your device
- You must be logged into Spotify in the Spotify app
- For playback, a Spotify Premium account is required (Spotify SDK limitation)

**Playing tracks:**
1. Open your library in Muze
2. Tap any Spotify track (shows a green Spotify icon)
3. The track will play through the Spotify app
4. Control playback from Muze (play, pause, skip, seek)

## 🔍 Troubleshooting

### "Failed to connect to Spotify"

**Possible causes:**
1. Spotify app is not installed → Install from App Store
2. Not logged into Spotify app → Open Spotify app and log in
3. Network connectivity issues → Check your internet connection

**Solution:** Ensure the Spotify app is installed and you're logged in.

### "Authentication failed"

**Possible causes:**
1. Incorrect Client ID in Constants.swift
2. Redirect URI mismatch between Constants.swift and Spotify Dashboard
3. App not approved in Spotify Dashboard

**Solutions:**
1. Double-check your Client ID
2. Verify redirect URI is exactly: `muze://callback` in both places
3. Ensure your Spotify app is in "Development Mode" (it is by default)

### "Cannot play Spotify tracks" or "Connection refused"

**Possible causes:**
1. Free Spotify account (Premium required for playback via SDK)
2. Spotify app not running or not logged in
3. Spotify app not in the right state to accept connections
4. Device offline

**Solutions (try in order):**

1. **Start playback in Spotify first**:
   - Open the Spotify app
   - **Play any song in Spotify** (this activates the remote control server)
   - Keep Spotify running in the background
   - Go back to Muze and try playing again

2. **Verify Spotify Premium**:
   - Spotify's App Remote API requires Premium
   - Free accounts cannot use remote playback
   - Check your account status at spotify.com/account

3. **Restart both apps**:
   - Force quit Muze (swipe up in app switcher)
   - Force quit Spotify
   - Open Spotify first, play a song
   - Open Muze and try again

4. **Check internet connection**:
   - Both apps need network access
   - Spotify requires active internet connection

### "Import failed" or "Import incomplete"

**Possible causes:**
1. Network timeout with large libraries
2. Token expired during import
3. Spotify API rate limiting

**Solutions:**
1. Try importing again - it will skip already imported tracks
2. The import will resume from where it left off
3. Wait a few minutes and try again

## 📊 API Rate Limits

Spotify's API has the following limits:
- **Web API**: Up to 50 tracks per request
- **Rate limit**: Approximately 180 requests per minute

For large libraries (1000+ tracks), import may take several minutes. The app handles pagination automatically.

## 🔐 Privacy & Security

### What Data Does Muze Access?

Muze requests these permissions:
- **user-library-read**: To import your liked songs
- **user-read-playback-state**: To show what's currently playing
- **user-modify-playback-state**: To control playback (play/pause/skip)
- **app-remote-control**: To communicate with the Spotify app

### What Data is Stored?

- **Access token**: Stored securely in UserDefaults (refreshed automatically)
- **Track metadata**: Title, artist, album, duration, Spotify URI
- **No audio files**: Spotify tracks stream directly from Spotify

### Revoking Access

To revoke Muze's access to your Spotify account:
1. Go to [Spotify Account Settings](https://www.spotify.com/account/apps/)
2. Find "Muze" in the list of connected apps
3. Click "Remove Access"

Or disconnect from within Muze:
1. Settings → Spotify → Disconnect

## 🆘 Common Questions

### Do I need Spotify Premium?

- **For importing liked songs**: No, free accounts work
- **For playback**: Yes, Premium is required (Spotify SDK limitation)

### Why isn't Spotify connecting?

**The Spotify app's remote control server only activates when needed.** Try this:

1. Open Spotify app
2. Play a song in Spotify
3. Keep it running in background
4. Try Muze again

This "primes" the Spotify app to accept remote connections.

### Can I search for new Spotify tracks?

Currently, Muze imports your liked songs only. Search functionality may be added in a future version.

### Will my Spotify playlists be imported?

Currently, only liked songs are imported. Playlist import may be added in a future version.

### Does this work offline?

- **Spotify tracks**: No, requires internet connection
- **Local tracks**: Yes, if downloaded from iCloud Drive

### Can I mix Spotify and local tracks in playlists?

Yes! That's the core feature of Muze. Create playlists with any combination of Spotify and local tracks.

## 🔄 Updating Your Liked Songs

To refresh your library with newly liked songs:
1. Go to Settings → Spotify
2. Tap "Import Liked Songs" again
3. Only new tracks will be imported (no duplicates)

## 📚 Additional Resources

- [Spotify for Developers](https://developer.spotify.com/)
- [Spotify iOS SDK Documentation](https://developer.spotify.com/documentation/ios/)
- [Spotify Web API Reference](https://developer.spotify.com/documentation/web-api/)

## 🐛 Reporting Issues

If you encounter issues not covered in this guide:
1. Check the Xcode console for error messages
2. Verify your Spotify Developer app settings
3. Ensure you're using the latest version of Muze

---

**Last Updated**: October 13, 2025  
**Muze Version**: 1.0.0  
**Spotify SDK Version**: 2.1.6+

