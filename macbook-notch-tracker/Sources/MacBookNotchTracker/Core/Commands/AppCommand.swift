import Foundation

enum AppCommand {
    case startSession
    case stopSession
    case pauseSession
    case resumeSession
    case extendSession
    case startBreak
    case endBreak
    case openDashboard
    case toggleNotchPreview
    case selectDashboardSection(DashboardSection)
}
