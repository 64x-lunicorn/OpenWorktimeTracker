import Foundation

enum SharedDefaults {
    static let appGroupIdentifier = "com.openworktimetracker.app"

    private static var sharedURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("OpenWorktimeTracker", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("widget-state.json")
    }

    // Keys
    static let stateKey = "widget_state"
    static let netTimeKey = "widget_netTime"
    static let grossTimeKey = "widget_grossTime"
    static let startTimeKey = "widget_startTime"
    static let dateKey = "widget_date"

    static func update(
        state: String, netTime: TimeInterval, grossTime: TimeInterval, startTime: Date, date: String
    ) {
        let data: [String: Any] = [
            stateKey: state,
            netTimeKey: netTime,
            grossTimeKey: grossTime,
            startTimeKey: startTime.timeIntervalSince1970,
            dateKey: date,
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: data) {
            try? jsonData.write(to: sharedURL, options: .atomic)
        }
    }

    private static func readDict() -> [String: Any] {
        guard let data = try? Data(contentsOf: sharedURL),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        return dict
    }

    static func readState() -> String {
        readDict()[stateKey] as? String ?? "notStarted"
    }

    static func readNetTime() -> TimeInterval {
        readDict()[netTimeKey] as? Double ?? 0
    }

    static func readGrossTime() -> TimeInterval {
        readDict()[grossTimeKey] as? Double ?? 0
    }

    static func readStartTime() -> Date? {
        guard let ts = readDict()[startTimeKey] as? Double, ts > 0 else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    static func readDate() -> String {
        readDict()[dateKey] as? String ?? ""
    }
}
