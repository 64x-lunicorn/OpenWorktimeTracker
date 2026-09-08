import Foundation

struct WidgetSnapshot: Codable, Equatable {
    let measuredAt: Date
    let state: String
    let netTime: TimeInterval
    let grossTime: TimeInterval
    let startTime: Date?
    let workDate: String
    let targetHours: Double
    let orangeThreshold: Double
    let redThreshold: Double

    var isRunning: Bool { state == "running" }

    /// Anchored to the measurement, never to the widget's later read time.
    var liveNetStart: Date { measuredAt.addingTimeInterval(-netTime) }

    func netTime(at date: Date) -> TimeInterval {
        netTime + (isRunning ? max(0, date.timeIntervalSince(measuredAt)) : 0)
    }

    func thresholdLevel(at date: Date) -> ThresholdLevel {
        ThresholdLadder(elevatedHours: orangeThreshold, criticalHours: redThreshold)
            .level(for: netTime(at: date))
    }

    fileprivate func validate() throws {
        guard ["notStarted", "running", "paused", "ended"].contains(state),
            measuredAt.timeIntervalSince1970.isFinite,
            startTime?.timeIntervalSince1970.isFinite ?? true,
            netTime.isFinite, netTime >= 0, grossTime.isFinite, grossTime >= 0,
            targetHours.isFinite, targetHours > 0,
            orangeThreshold.isFinite, orangeThreshold >= 0,
            redThreshold.isFinite, redThreshold >= 0 else {
            throw CocoaError(.coderInvalidValue)
        }
    }
}

struct SharedDefaults {
    static let appGroupIdentifier = "group.com.openworktimetracker"
    static let shared = SharedDefaults()
    static let snapshotKey = "widget_snapshot_v1"

    // AppSettingsKey/AppDefaults reference these shared setting definitions.
    static let normalHoursSettingKey = "normalNotificationHours"
    static let orangeThresholdSettingKey = "orangeThresholdHours"
    static let redThresholdSettingKey = "redThresholdHours"
    static let normalHoursDefault: Double = 8.0
    static let orangeThresholdDefault: Double = 8.0
    static let redThresholdDefault: Double = 9.5

    private let defaults: UserDefaults?
    private let fallbackURL: URL

    init(
        defaults: UserDefaults? = UserDefaults(suiteName: appGroupIdentifier),
        fallbackURL: URL = defaultURL
    ) {
        self.defaults = defaults
        self.fallbackURL = fallbackURL
    }

    static var defaultURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return appSupport.appendingPathComponent("OpenWorktimeTracker", isDirectory: true)
            .appendingPathComponent("widget-state.json")
    }

    func publish(_ snapshot: WidgetSnapshot) throws {
        try snapshot.validate()
        let data = try JSONEncoder().encode(snapshot)
        if let defaults {
            // One value replaces the entire measurement, including its settings.
            defaults.set(data, forKey: Self.snapshotKey)
        } else {
            try FileManager.default.createDirectory(
                at: fallbackURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: fallbackURL, options: .atomic)
        }
    }

    func readSnapshot() throws -> WidgetSnapshot? {
        let data: Data
        if let defaults {
            guard let value = defaults.object(forKey: Self.snapshotKey) else { return nil }
            guard let encoded = value as? Data else { throw CocoaError(.coderReadCorrupt) }
            data = encoded
        } else {
            do {
                data = try Data(contentsOf: fallbackURL)
            } catch CocoaError.fileReadNoSuchFile {
                return nil
            }
        }
        let snapshot = try JSONDecoder().decode(WidgetSnapshot.self, from: data)
        try snapshot.validate()
        return snapshot
    }
}
