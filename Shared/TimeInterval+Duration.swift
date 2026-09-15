import Foundation

extension TimeInterval {
    /// Hours always take two digits: `08:05`.
    var hoursMinutesFormatted: String {
        let totalMinutes = Int(self) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}
