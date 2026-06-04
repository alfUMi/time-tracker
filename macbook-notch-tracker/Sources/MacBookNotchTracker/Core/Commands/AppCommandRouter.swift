import Foundation

@MainActor
final class AppCommandRouter {
    private unowned let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    func dispatch(_ command: AppCommand) {
        switch command {
        case .openDashboard:
            container.selectedSection = .overview

        case .toggleNotchPreview:
            container.toggleNotchPreview()

        case .selectDashboardSection(let section):
            container.selectedSection = section

        case .startSession,
             .stopSession,
             .pauseSession,
             .resumeSession,
             .extendSession,
             .startBreak,
             .endBreak:
            container.sessionEngine.handle(command)
        }
    }
}
