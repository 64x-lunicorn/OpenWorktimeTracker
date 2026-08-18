import Foundation

/// A stretch with no keyboard or mouse activity, or with the screen locked,
/// that has ended and now needs an Idle Decision.
struct IdlePeriod: Identifiable, Equatable {
    let id: UUID
    let idleStart: Date
    let idleEnd: Date
    let spansMidnight: Bool

    init(id: UUID = UUID(), idleStart: Date, idleEnd: Date, spansMidnight: Bool) {
        self.id = id
        self.idleStart = idleStart
        self.idleEnd = idleEnd
        self.spansMidnight = spansMidnight
    }

    var duration: TimeInterval { idleEnd.timeIntervalSince(idleStart) }
}
