import Foundation

extension Date {
    var hoursMinutesString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    var dateString: String {
        TimeEntry.dateString(from: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

extension TimeInterval {
    var hoursMinutesFormatted: String {
        let totalMinutes = Int(self) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%02d:%02d", hours, minutes)
    }

    var hoursComponent: Int {
        Int(self) / 3600
    }

    var minutesComponent: Int {
        (Int(self) % 3600) / 60
    }

    var secondsComponent: Int {
        Int(self) % 60
    }

    var inHours: Double {
        self / 3600.0
    }
}
