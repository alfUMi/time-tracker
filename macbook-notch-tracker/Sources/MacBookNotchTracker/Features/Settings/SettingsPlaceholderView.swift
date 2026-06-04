import SwiftUI

struct SettingsPlaceholderView: View {
    @Environment(AppContainer.self) private var container

    var body: some View {
        Form {
            Section("Launch") {
                Toggle("Launch at login", isOn: launchAtLoginBinding)
            }

            Section("Notch") {
                Stepper(
                    "Reveal delay: \(container.settings.notchRevealDelayMilliseconds) ms",
                    value: revealDelayBinding,
                    in: 80...300,
                    step: 10
                )

                Stepper(
                    "Close delay: \(container.settings.notchCloseDelayMilliseconds) ms",
                    value: closeDelayBinding,
                    in: 120...400,
                    step: 10
                )
            }

            Section("Reminders") {
                Toggle("Break reminders", isOn: remindersEnabledBinding)

                Stepper(
                    "Reminder interval: \(container.settings.breakReminderMinutes) min",
                    value: reminderMinutesBinding,
                    in: 15...180,
                    step: 15
                )
            }
        }
        .formStyle(.grouped)
        .padding(DesignTokens.Spacing.lg)
        .frame(minWidth: 520, minHeight: 320)
        .background(DesignTokens.Colors.canvas)
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { container.settings.launchAtLoginEnabled },
            set: { newValue in
                var updated = container.settings
                updated.launchAtLoginEnabled = newValue
                container.saveSettings(updated)
            }
        )
    }

    private var revealDelayBinding: Binding<Int> {
        Binding(
            get: { container.settings.notchRevealDelayMilliseconds },
            set: { newValue in
                var updated = container.settings
                updated.notchRevealDelayMilliseconds = newValue
                container.saveSettings(updated)
            }
        )
    }

    private var closeDelayBinding: Binding<Int> {
        Binding(
            get: { container.settings.notchCloseDelayMilliseconds },
            set: { newValue in
                var updated = container.settings
                updated.notchCloseDelayMilliseconds = newValue
                container.saveSettings(updated)
            }
        )
    }

    private var remindersEnabledBinding: Binding<Bool> {
        Binding(
            get: { container.settings.breakRemindersEnabled },
            set: { newValue in
                var updated = container.settings
                updated.breakRemindersEnabled = newValue
                container.saveSettings(updated)
            }
        )
    }

    private var reminderMinutesBinding: Binding<Int> {
        Binding(
            get: { container.settings.breakReminderMinutes },
            set: { newValue in
                var updated = container.settings
                updated.breakReminderMinutes = newValue
                container.saveSettings(updated)
            }
        )
    }
}
