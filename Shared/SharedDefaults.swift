import Foundation

enum SharedDefaults {
    static let appGroupIdentifier = "group.com.openworktimetracker"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // Fallback: file-based sharing (when app group is not configured yet)
    private static var sharedURL: URL {
        let appSupport =
            FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first ?? FileManager.default.temporaryDirectory
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
    static let targetHoursKey = "widget_targetHours"
    static let orangeThresholdKey = "widget_orangeThreshold"
    static let redThresholdKey = "widget_redThreshold"

    static func update(
        state: String, netTime: TimeInterval, grossTime: TimeInterval, startTime: Date, date: String
    ) {
        let targetHours =
            UserDefaults.standard.object(forKey: "normalNotificationHours") as? Double ?? 8.0
        let orangeThreshold =
            UserDefaults.standard.object(forKey: "orangeThresholdHours") as? Double ?? 8.0
        let redThreshold =
            UserDefaults.standard.object(forKey: "redThresholdHours") as? Double ?? 9.5

        if let defaults = sharedDefaults {
            defaults.set(state, forKey: stateKey)
            defaults.set(netTime, forKey: netTimeKey)
            defaults.set(grossTime, forKey: grossTimeKey)
            defaults.set(startTime.timeIntervalSince1970, forKey: startTimeKey)
            defaults.set(date, forKey: dateKey)
            defaults.set(targetHours, forKey: targetHoursKey)
            defaults.set(orangeThreshold, forKey: orangeThresholdKey)
            defaults.set(redThreshold, forKey: redThresholdKey)
        } else {
            // Fallback to file
            let data: [String: Any] = [
                stateKey: state,
                netTimeKey: netTime,
                grossTimeKey: grossTime,
                startTimeKey: startTime.timeIntervalSince1970,
                dateKey: date,
                targetHoursKey: targetHours,
                orangeThresholdKey: orangeThreshold,
                redThresholdKey: redThreshold,
            ]
            if let jsonData = try? JSONSerialization.data(withJSONObject: data) {
                try? jsonData.write(to: sharedURL, options: .atomic)
            }
        }
    }

    // MARK: - Read

    private static func readValue(forKey key: String) -> Any? {
        if let defaults = sharedDefaults {
            return defaults.object(forKey: key)
        }
        // Fallback to file
        guard let data = try? Data(contentsOf: sharedURL),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return dict[key]
    }

    static func readState() -> String {
        readValue(forKey: stateKey) as? String ?? "notStarted"
    }

    static func readNetTime() -> TimeInterval {
        readValue(forKey: netTimeKey) as? Double ?? 0
    }

    static func readGrossTime() -> TimeInterval {
        readValue(forKey: grossTimeKey) as? Double ?? 0
    }

    static func readStartTime() -> Date? {
        guard let ts = readValue(forKey: startTimeKey) as? Double, ts > 0 else { return nil }
        return Date(timeIntervalSince1970: ts)
    }

    static func readDate() -> String {
        readValue(forKey: dateKey) as? String ?? ""
    }

    static func readTargetHours() -> Double {
        readValue(forKey: targetHoursKey) as? Double ?? 8.0
    }

    static func readOrangeThreshold() -> Double {
        readValue(forKey: orangeThresholdKey) as? Double ?? 8.0
    }

    static func readRedThreshold() -> Double {
        readValue(forKey: redThresholdKey) as? Double ?? 9.5
    }
}
