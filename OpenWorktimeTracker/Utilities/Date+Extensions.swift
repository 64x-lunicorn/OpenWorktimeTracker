import Foundation

extension Date {
    private static let hoursMinutesFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var hoursMinutesString: String {
        Date.hoursMinutesFormatter.string(from: self)
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
