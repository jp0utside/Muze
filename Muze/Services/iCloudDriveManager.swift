//
//  iCloudDriveManager.swift
//  Muze
//
//  Created on October 7, 2025.
//

import Foundation
import AVFoundation
import Combine

/// Manages access to audio files stored in iCloud Drive or local Documents directory
/// Falls back to local storage when iCloud is unavailable
@MainActor
class iCloudDriveManager: ObservableObject {
    // MARK: - Properties
    
    @Published private(set) var isAvailable: Bool = false
    @Published private(set) var isScanning: Bool = false
    @Published private(set) var discoveredFiles: [URL] = []
    @Published private(set) var syncStatus: iCloudSyncStatus = .unknown
    @Published private(set) var usingLocalStorage: Bool = false
    
    private let fileManager = FileManager.default
    private var metadataQuery: NSMetadataQuery?
    private var cancellables = Set<AnyCancellable>()
    
    // iCloud container identifier - update in Constants.swift
    private let containerIdentifier: String?
    
    // MARK: - Initialization
    
    init(containerIdentifier: String? = nil) {
        self.containerIdentifier = containerIdentifier
        checkiCloudAvailability()
        setupMetadataQuery()
    }
    
    deinit {
        metadataQuery?.stop()
    }
    
    // MARK: - iCloud Availability
    
    private func checkiCloudAvailability() {
        if let _ = fileManager.ubiquityIdentityToken {
            isAvailable = true
            syncStatus = .available
            usingLocalStorage = false
            AppLogger.logLocalAudio("✅ iCloud Drive is available")
        } else {
            isAvailable = false
            syncStatus = .unavailable
            usingLocalStorage = true
            AppLogger.logLocalAudio("⚠️ iCloud Drive not available - using local storage fallback", level: .warning)
        }
    }
    
    /// Returns the URL to the iCloud Drive Documents directory
    var iCloudDocumentsURL: URL? {
        guard isAvailable else { return nil }
        
        if let containerURL = fileManager.url(forUbiquityContainerIdentifier: containerIdentifier) {
            return containerURL.appendingPathComponent("Documents")
        }
        return nil
    }
    
    /// Returns the URL to the local app Documents directory
    var localDocumentsURL: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    /// Returns the URL to the Muze music folder (iCloud or local)
    var muzeMusicFolderURL: URL? {
        if isAvailable, let iCloudDocs = iCloudDocumentsURL {
            // Use iCloud when available
            return iCloudDocs.appendingPathComponent("Muze/Music")
        } else if let localDocs = localDocumentsURL {
            // Fall back to local Documents
            return localDocs.appendingPathComponent("Muze/Music")
        }
        return nil
    }
    
    // MARK: - Folder Setup
    
    /// Creates the Muze music folder if it doesn't exist (iCloud or local)
    func createMuzeMusicFolderIfNeeded() async throws {
        guard let folderURL = muzeMusicFolderURL else {
            throw iCloudError.notAvailable
        }
        
        if !fileManager.fileExists(atPath: folderURL.path) {
            try fileManager.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            let storageType = usingLocalStorage ? "local storage" : "iCloud Drive"
            AppLogger.logLocalAudio("📁 Created Muze music folder in \(storageType): \(folderURL.path)")
        }
    }
    
    // MARK: - File Discovery
    
    /// Scans for audio files (iCloud Drive or local storage)
    func scanForAudioFiles() async throws -> [URL] {
        guard let musicFolderURL = muzeMusicFolderURL else {
            throw iCloudError.notAvailable
        }
        
        isScanning = true
        defer { isScanning = false }
        
        // Ensure the folder exists
        try await createMuzeMusicFolderIfNeeded()
        
        var audioFiles: [URL] = []
        
        // Get all files in the music folder
        if let enumerator = fileManager.enumerator(
            at: musicFolderURL,
            includingPropertiesForKeys: [.isRegularFileKey, .nameKey],
            options: [.skipsHiddenFiles]
        ) {
            // Convert to array first to avoid iterator issues in async context
            let allItems = enumerator.allObjects
            for case let fileURL as URL in allItems {
                // Check if it's a regular file
                if let isRegularFile = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile,
                   isRegularFile {
                    // Check if it's a supported audio format
                    if fileURL.isSupportedAudioFile {
                        audioFiles.append(fileURL)
                    }
                }
            }
        }
        
        discoveredFiles = audioFiles
        let storageType = usingLocalStorage ? "local storage" : "iCloud Drive"
        AppLogger.logLocalAudio("🔍 Found \(audioFiles.count) audio files in \(storageType)")
        
        return audioFiles
    }
    
    /// Checks if a file is downloaded from iCloud (local files are always available)
    func isFileDownloaded(_ url: URL) -> Bool {
        // If using local storage, file is always "downloaded" (it's local)
        if usingLocalStorage {
            return fileManager.fileExists(atPath: url.path)
        }
        
        // Check iCloud download status
        guard let values = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]) else {
            return false
        }
        
        if let status = values.ubiquitousItemDownloadingStatus {
            return status == .current
        }
        
        return false
    }
    
    /// Downloads a file from iCloud if not already downloaded (no-op for local files)
    func downloadFileIfNeeded(_ url: URL) async throws {
        // If using local storage, files are already local - no download needed
        if usingLocalStorage {
            if !fileManager.fileExists(atPath: url.path) {
                throw iCloudError.downloadFailed
            }
            return
        }
        
        // For iCloud files, check if download is needed
        guard isAvailable else {
            throw iCloudError.notAvailable
        }
        
        // Check if file is already downloaded
        if isFileDownloaded(url) {
            return
        }
        
        // Start download
        try fileManager.startDownloadingUbiquitousItem(at: url)
        
        // Wait for download to complete
        // In a real implementation, you'd want to monitor download progress
        AppLogger.logLocalAudio("⬇️ Started downloading file: \(url.lastPathComponent)")
    }
    
    /// Gets download progress for a file (0.0 to 1.0) - local files are always 1.0
    func downloadProgress(for url: URL) -> Double? {
        // Local files are always fully available
        if usingLocalStorage {
            return fileManager.fileExists(atPath: url.path) ? 1.0 : 0.0
        }
        
        // Check iCloud download progress
        guard let values = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey, .ubiquitousItemDownloadingErrorKey]) else {
            return nil
        }
        
        if let status = values.ubiquitousItemDownloadingStatus {
            switch status {
            case .current:
                return 1.0
            case .notDownloaded:
                return 0.0
            case .downloaded:
                return 1.0
            default:
                return nil
            }
        }
        
        return nil
    }
    
    // MARK: - File Monitoring
    
    private func setupMetadataQuery() {
        guard isAvailable else { return }
        
        metadataQuery = NSMetadataQuery()
        
        guard let query = metadataQuery else { return }
        
        // Search for audio files
        let predicates = Constants.Audio.supportedLocalFormats.map { format in
            NSPredicate(format: "%K LIKE %@", NSMetadataItemFSNameKey, "*.\(format)")
        }
        query.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        
        // Search in the Documents scope
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        
        // Set up notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataQueryDidFinishGathering),
            name: .NSMetadataQueryDidFinishGathering,
            object: query
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataQueryDidUpdate),
            name: .NSMetadataQueryDidUpdate,
            object: query
        )
    }
    
    func startMonitoring() {
        guard isAvailable else { return }
        metadataQuery?.start()
        AppLogger.logLocalAudio("Started monitoring iCloud Drive for changes")
    }
    
    func stopMonitoring() {
        metadataQuery?.stop()
    }
    
    @objc private func metadataQueryDidFinishGathering(_ notification: Notification) {
        processMetadataResults()
    }
    
    @objc private func metadataQueryDidUpdate(_ notification: Notification) {
        processMetadataResults()
    }
    
    private func processMetadataResults() {
        guard let query = metadataQuery else { return }
        
        query.disableUpdates()
        defer { query.enableUpdates() }
        
        var files: [URL] = []
        for item in query.results {
            if let metadataItem = item as? NSMetadataItem,
               let url = metadataItem.value(forAttribute: NSMetadataItemURLKey) as? URL {
                files.append(url)
            }
        }
        
        Task { @MainActor in
            discoveredFiles = files
            AppLogger.logLocalAudio("Updated file list: \(files.count) files")
        }
    }
    
    // MARK: - File Operations
    
    /// Copies a file to the Muze music folder (iCloud or local storage)
    func importFile(from sourceURL: URL) async throws -> URL {
        guard let musicFolderURL = muzeMusicFolderURL else {
            throw iCloudError.notAvailable
        }
        
        try await createMuzeMusicFolderIfNeeded()
        
        let fileName = sourceURL.lastPathComponent
        let destinationURL = musicFolderURL.appendingPathComponent(fileName)
        
        // Copy the file
        let storageType = usingLocalStorage ? "local storage" : "iCloud Drive"
        if fileManager.fileExists(atPath: destinationURL.path) {
            // File already exists, create a unique name
            let uniqueURL = try generateUniqueURL(for: destinationURL)
            try fileManager.copyItem(at: sourceURL, to: uniqueURL)
            AppLogger.logLocalAudio("📥 Imported file to \(storageType): \(uniqueURL.lastPathComponent)")
            return uniqueURL
        } else {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            AppLogger.logLocalAudio("📥 Imported file to \(storageType): \(fileName)")
            return destinationURL
        }
    }
    
    /// Deletes a file (from iCloud or local storage)
    func deleteFile(at url: URL) async throws {
        try fileManager.removeItem(at: url)
        let storageType = usingLocalStorage ? "local storage" : "iCloud Drive"
        AppLogger.logLocalAudio("🗑️ Deleted file from \(storageType): \(url.lastPathComponent)")
    }
    
    private func generateUniqueURL(for url: URL) throws -> URL {
        let directory = url.deletingLastPathComponent()
        let filename = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        
        var counter = 1
        var newURL = url
        
        while fileManager.fileExists(atPath: newURL.path) {
            let newFilename = "\(filename) \(counter).\(ext)"
            newURL = directory.appendingPathComponent(newFilename)
            counter += 1
            
            if counter > 1000 {
                throw iCloudError.unableToCreateUniqueFilename
            }
        }
        
        return newURL
    }
    
    // MARK: - Metadata Extraction
    
    /// Extracts metadata from an audio file for creating a Track object
    func extractMetadata(from url: URL) async throws -> TrackMetadata {
        // Ensure file is downloaded
        try await downloadFileIfNeeded(url)
        
        // Use AVAsset to extract metadata
        let asset = AVURLAsset(url: url)
        
        let metadata = TrackMetadata(
            title: await extractTitle(from: asset) ?? url.deletingPathExtension().lastPathComponent,
            artist: await extractArtist(from: asset) ?? "Unknown Artist",
            album: await extractAlbum(from: asset),
            duration: try await asset.load(.duration).seconds,
            artworkURL: nil, // Will be extracted separately if needed
            genre: await extractGenre(from: asset),
            year: await extractYear(from: asset)
        )
        
        return metadata
    }
    
    private func extractTitle(from asset: AVAsset) async -> String? {
        await extractCommonMetadata(from: asset, key: .commonKeyTitle)
    }
    
    private func extractArtist(from asset: AVAsset) async -> String? {
        await extractCommonMetadata(from: asset, key: .commonKeyArtist)
    }
    
    private func extractAlbum(from asset: AVAsset) async -> String? {
        await extractCommonMetadata(from: asset, key: .commonKeyAlbumName)
    }
    
    private func extractGenre(from asset: AVAsset) async -> String? {
        await extractCommonMetadata(from: asset, key: .commonKeyType)
    }
    
    private func extractYear(from asset: AVAsset) async -> Int? {
        if let dateString = await extractCommonMetadata(from: asset, key: .commonKeyCreationDate),
           let year = Int(dateString.prefix(4)) {
            return year
        }
        return nil
    }
    
    private func extractCommonMetadata(from asset: AVAsset, key: AVMetadataKey) async -> String? {
        guard let metadata = try? await asset.load(.metadata) else { return nil }
        
        let items = AVMetadataItem.metadataItems(
            from: metadata,
            filteredByIdentifier: AVMetadataIdentifier.commonIdentifierTitle
        )
        
        if let item = items.first,
           let value = try? await item.load(.stringValue) {
            return value
        }
        
        return nil
    }
}

// MARK: - Supporting Types

enum iCloudSyncStatus {
    case unknown
    case available
    case unavailable
    case syncing
}

enum iCloudError: LocalizedError {
    case notAvailable
    case unableToCreateUniqueFilename
    case downloadFailed
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "iCloud Drive is not available. Please enable iCloud Drive in Settings."
        case .unableToCreateUniqueFilename:
            return "Unable to create a unique filename for the imported file."
        case .downloadFailed:
            return "Failed to download file from iCloud Drive."
        case .uploadFailed:
            return "Failed to upload file to iCloud Drive."
        }
    }
}

struct TrackMetadata {
    let title: String
    let artist: String
    let album: String?
    let duration: TimeInterval
    let artworkURL: URL?
    let genre: String?
    let year: Int?
}

