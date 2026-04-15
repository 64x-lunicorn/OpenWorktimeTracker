import Foundation

final class CloudSyncManager {

    static let shared = CloudSyncManager()

    private let fileManager = FileManager.default

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: AppSettingsKey.iCloudSyncEnabled)
    }

    var iCloudAvailable: Bool {
        iCloudLogsURL != nil
    }

    var iCloudLogsURL: URL? {
        // Use the public iCloud Drive folder (no container entitlement required)
        let home = fileManager.homeDirectoryForCurrentUser
        let iCloudDrive =
            home
            .appendingPathComponent(
                "Library/Mobile Documents/com~apple~CloudDocs", isDirectory: true)

        guard fileManager.fileExists(atPath: iCloudDrive.path) else { return nil }

        let logsURL =
            iCloudDrive
            .appendingPathComponent("OpenWorktimeTracker/logs", isDirectory: true)
        if !fileManager.fileExists(atPath: logsURL.path) {
            try? fileManager.createDirectory(at: logsURL, withIntermediateDirectories: true)
        }
        return logsURL
    }

    // MARK: - Sync Operations

    func syncIfEnabled(localDirectory: URL) {
        guard isEnabled, let cloudURL = iCloudLogsURL else { return }
        syncLocalToCloud(local: localDirectory, cloud: cloudURL)
        syncCloudToLocal(local: localDirectory, cloud: cloudURL)
    }

    func uploadEntry(at fileURL: URL) {
        guard isEnabled, let cloudURL = iCloudLogsURL else { return }
        let fileName = fileURL.lastPathComponent
        let destination = cloudURL.appendingPathComponent(fileName)
        copyIfNewer(from: fileURL, to: destination)
    }

    // MARK: - Full Sync

    private func syncLocalToCloud(local: URL, cloud: URL) {
        guard
            let files = try? fileManager.contentsOfDirectory(
                at: local,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            )
        else { return }

        for file in files where file.pathExtension == "json" {
            let destination = cloud.appendingPathComponent(file.lastPathComponent)
            copyIfNewer(from: file, to: destination)
        }
    }

    private func syncCloudToLocal(local: URL, cloud: URL) {
        guard
            let files = try? fileManager.contentsOfDirectory(
                at: cloud,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            )
        else { return }

        for file in files where file.pathExtension == "json" {
            let destination = local.appendingPathComponent(file.lastPathComponent)
            copyIfNewer(from: file, to: destination)
        }
    }

    private func copyIfNewer(from source: URL, to destination: URL) {
        let srcMod = modificationDate(of: source)
        let dstMod = modificationDate(of: destination)

        if let dstMod, let srcMod, srcMod <= dstMod {
            return  // destination is same or newer
        }

        try? fileManager.removeItem(at: destination)
        try? fileManager.copyItem(at: source, to: destination)
    }

    private func modificationDate(of url: URL) -> Date? {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        return values?.contentModificationDate
    }
}
