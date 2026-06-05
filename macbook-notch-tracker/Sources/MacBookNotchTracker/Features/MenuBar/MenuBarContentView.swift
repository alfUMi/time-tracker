import SwiftUI

struct MenuBarContentView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Label(container.sessionEngine.currentState.title, systemImage: container.sessionEngine.currentState.symbolName)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text(container.sessionEngine.todaySummary.totalTracked.formattedDuration)
                .font(.system(size: 22, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Divider()

            Button("Open Dashboard") {
                openDashboard()
            }

            Button(container.isNotchPreviewVisible ? "Hide Notch Surface" : "Pin Notch Surface") {
                container.commandRouter.dispatch(.toggleNotchPreview)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .frame(width: 260)
    }

    private func openDashboard() {
        container.commandRouter.dispatch(.openDashboard)
        let didFocusExistingWindow = container.focusDashboardWindow()

        if !didFocusExistingWindow {
            openWindow(id: AppWindowID.dashboard)
        }

        DispatchQueue.main.async {
            container.focusDashboardWindow()
        }
    }
}
