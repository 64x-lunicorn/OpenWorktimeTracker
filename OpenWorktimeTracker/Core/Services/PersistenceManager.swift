import Foundation

final class PersistenceManager {

    private let fileManager = FileManager.default

    var logDirectory: URL {
        if let bookmarkData = UserDefaults.standard.data(forKey: AppSettingsKey.logFolderBookmark) {
            var isStale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                bookmarkDataIsStale: &isStale
            ) {
                _ = url.startAccessingSecurityScopedResource()
                return url
            }
        }
        return defaultLogDirectory
    }

    var defaultLogDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        return
            appSupport
            .appendingPathComponent("OpenWorktimeTracker", isDirectory: true)
            .appendingPathComponent("logs", isDirectory: true)
    }

    private let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        return enc
    }()

    private let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()

    init() {
        ensureDirectoryExists()
    }

    // MARK: - Directory

    private func ensureDirectoryExists() {
        let dir = logDirectory
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    func setCustomLogFolder(_ url: URL) {
        if let bookmarkData = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) {
            UserDefaults.standard.set(bookmarkData, forKey: AppSettingsKey.logFolderBookmark)
        }
    }

    // MARK: - Save / Load

    func save(_ entry: TimeEntry) {
        ensureDirectoryExists()
        let fileURL = logDirectory.appendingPathComponent("\(entry.date).json")
        if let data = try? encoder.encode(entry) {
            try? data.write(to: fileURL, options: .atomic)
            CloudSyncManager.shared.uploadEntry(at: fileURL)
        }
    }

    func load(for dateString: String) -> TimeEntry? {
        let fileURL = logDirectory.appendingPathComponent("\(dateString).json")
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(TimeEntry.self, from: data)
    }

    func loadToday() -> TimeEntry? {
        load(for: TimeEntry.dateString(from: Date()))
    }

    func loadMostRecentEntry() -> TimeEntry? {
        ensureDirectoryExists()
        let dir = logDirectory
        guard
            let files = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            )
        else { return nil }

        let jsonFiles =
            files
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }

        for file in jsonFiles {
            if let data = try? Data(contentsOf: file),
                let entry = try? decoder.decode(TimeEntry.self, from: data)
            {
                return entry
            }
        }
        return nil
    }

    func loadAll() -> [TimeEntry] {
        ensureDirectoryExists()
        let dir = logDirectory
        guard
            let files = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
        else { return [] }

        return
            files
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .compactMap { file in
                guard let data = try? Data(contentsOf: file) else { return nil }
                return try? decoder.decode(TimeEntry.self, from: data)
            }
    }

    func loadLastDays(_ count: Int) -> [TimeEntry] {
        ensureDirectoryExists()
        let dir = logDirectory
        guard
            let files = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
        else { return [] }

        let sorted =
            files
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .prefix(count)

        return sorted.compactMap { file in
            guard let data = try? Data(contentsOf: file) else { return nil }
            return try? decoder.decode(TimeEntry.self, from: data)
        }
    }

    // MARK: - Export

    func syncWithCloud() {
        CloudSyncManager.shared.syncIfEnabled(localDirectory: logDirectory)
    }

    func exportCSV() -> URL? {
        let entries = loadAll()
        guard !entries.isEmpty else { return nil }

        var csv = "Date,Start,End,Gross (h),Manual Pause (h),Auto Break (h),Net (h),Note\n"

        let calc = BreakCalculator()
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        for entry in entries {
            let start = timeFormatter.string(from: entry.startTime)
            let end = entry.endTime.map { timeFormatter.string(from: $0) } ?? "-"
            let gross = String(format: "%.2f", entry.grossTime.inHours)
            let manual = String(format: "%.2f", entry.totalManualPause.inHours)
            let net = calc.netWorkTime(
                grossTime: entry.grossTime,
                manualPause: entry.totalManualPause,
                idlePause: entry.totalIdlePause
            )
            let autoBreak = String(
                format: "%.2f",
                calc.autoBreak(
                    forWorkTime: entry.workTimeBeforeAutoBreak,
                    alreadyPaused: entry.totalManualPause + entry.totalIdlePause
                ).inHours
            )
            let netStr = String(format: "%.2f", net.inHours)
            let note = entry.note.replacingOccurrences(of: ",", with: ";")

            csv +=
                "\(entry.date),\(start),\(end),\(gross),\(manual),\(autoBreak),\(netStr),\(note)\n"
        }

        let exportURL = fileManager.temporaryDirectory.appendingPathComponent(
            "OpenWorktimeTracker_Export.csv")
        try? csv.write(to: exportURL, atomically: true, encoding: .utf8)
        return exportURL
    }
}
