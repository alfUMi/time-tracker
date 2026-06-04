import Foundation

enum SessionState: String, CaseIterable, Identifiable, Codable {
    case idle
    case running
    case extended
    case paused
    case onBreak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .idle:
            "Idle"
        case .running:
            "Working"
        case .extended:
            "Extended"
        case .paused:
            "Paused"
        case .onBreak:
            "On Break"
        }
    }

    var symbolName: String {
        switch self {
        case .idle:
            "circle.dashed"
        case .running:
            "play.circle.fill"
        case .extended:
            "forward.circle.fill"
        case .paused:
            "pause.circle.fill"
        case .onBreak:
            "cup.and.saucer.fill"
        }
    }
}

struct ActiveSession: Identifiable, Equatable, Codable {
    let id: UUID
    var startedAt: Date
    var taskLabel: String
    var state: SessionState
}

struct SessionRecord: Identifiable, Equatable, Codable {
    let id: UUID
    var startedAt: Date
    var endedAt: Date
    var taskLabel: String
    var state: SessionState
    var createdAt: Date
    var updatedAt: Date
    var notes: String?

    var duration: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }
}

struct SessionSummary: Equatable, Codable {
    var totalTracked: TimeInterval
    var totalBreak: TimeInterval
    var sessionsCount: Int

    static let empty = SessionSummary(totalTracked: 0, totalBreak: 0, sessionsCount: 0)
}

struct AppSettings: Equatable, Codable {
    var launchAtLoginEnabled = false
    var breakRemindersEnabled = true
    var breakReminderMinutes = 60
    var notchRevealDelayMilliseconds = 120
    var notchCloseDelayMilliseconds = 220
}

struct SessionStoreSnapshot: Equatable, Codable {
    var schemaVersion: Int
    var activeSession: ActiveSession?
    var sessionHistory: [SessionRecord]

    static let empty = SessionStoreSnapshot(
        schemaVersion: 1,
        activeSession: nil,
        sessionHistory: []
    )
}

enum SummaryRange: String, CaseIterable, Identifiable, Codable {
    case day
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day:
            "Today"
        case .week:
            "This Week"
        case .month:
            "This Month"
        }
    }
}

struct SessionHistoryFilter: Equatable, Codable {
    var range: SummaryRange
    var state: SessionState?
    var searchText: String

    static let `default` = SessionHistoryFilter(range: .week, state: nil, searchText: "")
}

struct SessionChartPoint: Identifiable, Equatable, Codable {
    var id: String { label }

    var label: String
    var trackedDuration: TimeInterval
    var breakDuration: TimeInterval
    var sessionCount: Int
}
