# 🚀 Spotify Quick Start Guide

Get Spotify integration working in Muze in 5 minutes!

## ✅ Prerequisites

- [ ] Spotify account (free or premium)
- [ ] Spotify app installed on iOS device
- [ ] 5 minutes of your time

## 📝 Setup Steps

### 1. Create Spotify Developer App (2 min)

1. Go to: https://developer.spotify.com/dashboard
2. Click **"Create app"**
3. Fill in:
   - **App name**: Muze
   - **Redirect URI**: `muze://callback` ⚠️ **Must be exact!**
4. Click **Save**
5. Copy your **Client ID** (looks like: `1a2b3c4d5e6f7g8h9i0j...`)

### 2. Configure Muze (1 min)

Open `Muze/Utilities/Constants.swift`:

```swift
enum Spotify {
    static let clientID = "PASTE_YOUR_CLIENT_ID_HERE"  // <-- Paste here!
    static let redirectURI = "muze://callback"
    // ... rest stays the same
}
```

### 3. Build & Run (1 min)

```bash
make build
make run
```

Or use Xcode:
```
⌘ + R (Run)
```

> **Note**: First build will download the Spotify SDK automatically (~5-10 seconds)

### 4. Connect & Import (1 min)

In Muze:
1. Go to **Settings** tab (⚙️)
2. Tap **Spotify**
3. Tap **Sign in with Spotify**
4. Log in and authorize
5. Tap **Import Liked Songs**
6. Wait for import to complete ✅

## 🎵 You're Done!

Your Spotify liked songs are now in Muze! They appear in your library with a green Spotify icon.

## 💡 Tips

- **Mixed Playlists**: Create playlists mixing Spotify + local tracks!
- **Re-import**: Tap "Import Liked Songs" again to get newly liked songs
- **No Duplicates**: Re-importing won't create duplicates
- **Playback**: Requires Spotify Premium (Spotify SDK limitation)

## ❓ Problems?

**Authentication fails?**
- Double-check your Client ID
- Verify redirect URI is exactly: `muze://callback`

**Can't play tracks?**
- Install Spotify app
- Log into Spotify app
- Ensure Spotify Premium account

**See full troubleshooting**: [SPOTIFY_SETUP.md](SPOTIFY_SETUP.md)

---

**Need help?** See the complete guide: [SPOTIFY_SETUP.md](SPOTIFY_SETUP.md)

