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
    var state: SessionState
}

struct SessionRecord: Identifiable, Equatable, Codable {
    let id: UUID
    var startedAt: Date
    var endedAt: Date
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
    var launchAtLoginEnabled: Bool
    var breakRemindersEnabled: Bool
    var breakReminderMinutes: Int
    var notchRevealDelayMilliseconds: Int
    var notchCloseDelayMilliseconds: Int
    var automaticWorkTimerEnabled: Bool
    var workdayStartMinutes: Int
    var workdayEndMinutes: Int
    var holidayDates: [Date]

    init(
        launchAtLoginEnabled: Bool = false,
        breakRemindersEnabled: Bool = true,
        breakReminderMinutes: Int = 60,
        notchRevealDelayMilliseconds: Int = 120,
        notchCloseDelayMilliseconds: Int = 220,
        automaticWorkTimerEnabled: Bool = false,
        workdayStartMinutes: Int = 9 * 60,
        workdayEndMinutes: Int = 17 * 60,
        holidayDates: [Date] = []
    ) {
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.breakRemindersEnabled = breakRemindersEnabled
        self.breakReminderMinutes = breakReminderMinutes
        self.notchRevealDelayMilliseconds = notchRevealDelayMilliseconds
        self.notchCloseDelayMilliseconds = notchCloseDelayMilliseconds
        self.automaticWorkTimerEnabled = automaticWorkTimerEnabled
        self.workdayStartMinutes = workdayStartMinutes
        self.workdayEndMinutes = workdayEndMinutes
        self.holidayDates = holidayDates
    }

    private enum CodingKeys: String, CodingKey {
        case launchAtLoginEnabled
        case breakRemindersEnabled
        case breakReminderMinutes
        case notchRevealDelayMilliseconds
        case notchCloseDelayMilliseconds
        case automaticWorkTimerEnabled
        case workdayStartMinutes
        case workdayEndMinutes
        case holidayDates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(
            launchAtLoginEnabled: try container.decodeIfPresent(Bool.self, forKey: .launchAtLoginEnabled) ?? false,
            breakRemindersEnabled: try container.decodeIfPresent(Bool.self, forKey: .breakRemindersEnabled) ?? true,
            breakReminderMinutes: try container.decodeIfPresent(Int.self, forKey: .breakReminderMinutes) ?? 60,
            notchRevealDelayMilliseconds: try container.decodeIfPresent(Int.self, forKey: .notchRevealDelayMilliseconds) ?? 120,
            notchCloseDelayMilliseconds: try container.decodeIfPresent(Int.self, forKey: .notchCloseDelayMilliseconds) ?? 220,
            automaticWorkTimerEnabled: try container.decodeIfPresent(Bool.self, forKey: .automaticWorkTimerEnabled) ?? false,
            workdayStartMinutes: try container.decodeIfPresent(Int.self, forKey: .workdayStartMinutes) ?? 9 * 60,
            workdayEndMinutes: try container.decodeIfPresent(Int.self, forKey: .workdayEndMinutes) ?? 17 * 60,
            holidayDates: try container.decodeIfPresent([Date].self, forKey: .holidayDates) ?? []
        )
    }
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

    static let `default` = SessionHistoryFilter(range: .week, state: nil)
}

struct SessionChartPoint: Identifiable, Equatable, Codable {
    var id: String { label }

    var label: String
    var trackedDuration: TimeInterval
    var breakDuration: TimeInterval
    var sessionCount: Int
}
