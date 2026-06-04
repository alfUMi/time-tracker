import Charts
import SwiftUI

struct DashboardRootView: View {
    @Environment(AppContainer.self) private var container

    var body: some View {
        NavigationSplitView {
            DashboardSidebar(selection: selectionBinding)
                .navigationSplitViewColumnWidth(min: 210, ideal: 230)
        } detail: {
            DashboardDetailView(section: container.selectedSection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(GlassBackgroundView())
        }
        .tint(DesignTokens.Colors.accentBlue)
        .background(GlassBackgroundView())
    }

    private var selectionBinding: Binding<DashboardSection?> {
        Binding(
            get: { container.selectedSection },
            set: { newValue in
                guard let newValue else { return }
                container.commandRouter.dispatch(.selectDashboardSection(newValue))
            }
        )
    }
}

private struct DashboardSidebar: View {
    @Environment(AppContainer.self) private var container

    let selection: Binding<DashboardSection?>

    var body: some View {
        List(container.sectionRegistry.sections, selection: selection) { section in
            Label(section.title, systemImage: section.symbolName)
                .tag(section)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(GlassBackgroundView())
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Current State")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                DashboardStateChip(state: container.sessionEngine.currentState)

                Text(container.sessionEngine.activeSession?.taskLabel ?? "No active task")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .panelCardStyle(padding: DesignTokens.Spacing.md)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.md)
            .background(GlassBackgroundView())
        }
    }
}

private struct DashboardDetailView: View {
    @Environment(AppContainer.self) private var container

    let section: DashboardSection

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                DashboardHeader(section: section)

                CurrentSessionPanel()

                switch section.id {
                case DashboardSection.history.id:
                    HistoryWorkspaceView()
                case DashboardSection.insights.id:
                    InsightsWorkspaceView()
                case DashboardSection.settings.id:
                    SettingsWorkspaceView()
                default:
                    OverviewWorkspaceView()
                }
            }
            .padding(DesignTokens.Spacing.xl)
        }
        .background(GlassBackgroundView())
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
            if section == .history {
                HistoryHintBar()
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .padding(.bottom, DesignTokens.Spacing.md)
            }
        }
    }
}

private struct DashboardHeader: View {
    @Environment(AppContainer.self) private var container

    let section: DashboardSection

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(section.title)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(sectionDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Spacer()

            HStack(spacing: DesignTokens.Spacing.sm) {
                DashboardStateChip(state: container.sessionEngine.currentState)

                Button(container.isNotchPreviewVisible ? "Hide Notch Surface" : "Pin Notch Surface") {
                    container.commandRouter.dispatch(.toggleNotchPreview)
                }
                .buttonStyle(GlassButtonStyle(prominence: .secondary(DesignTokens.Colors.textSecondary)))
            }
        }
    }

    private var sectionDescription: String {
        switch section.id {
        case DashboardSection.history.id:
            "Filter, edit, and clean up recorded sessions."
        case DashboardSection.insights.id:
            "Charts first, details second."
        case DashboardSection.settings.id:
            "Tune startup, reminders, and notch behavior."
        default:
            "Live activity and trends at a glance."
        }
    }
}

private struct CurrentSessionPanel: View {
    @Environment(AppContainer.self) private var container

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        DashboardStateChip(state: container.sessionEngine.currentState)

                        Text(container.islandStateMachine.isPinned ? "Pinned Notch" : "Hover Notch")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .glassChipStyle(tint: DesignTokens.Colors.textSecondary)
                    }

                    Text(container.sessionEngine.activeSession?.taskLabel ?? "Ready to start a focused session.")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xs) {
                    Text("Live Timer")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    LiveDurationText(activeSession: container.sessionEngine.activeSession)
                        .font(.system(size: 34, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                }
            }

            SessionActionRow()

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 180), spacing: DesignTokens.Spacing.md)],
                alignment: .leading,
                spacing: DesignTokens.Spacing.md
            ) {
                MetricTile(title: "Today Tracked", value: container.sessionEngine.summary(for: .day).totalTracked.formattedDuration)
                MetricTile(title: "This Week", value: container.sessionEngine.summary(for: .week).totalTracked.formattedDuration)
                MetricTile(title: "Sessions This Month", value: "\(container.sessionEngine.summary(for: .month).sessionsCount)")
            }
        }
        .panelCardStyle()
    }

}

private struct SessionActionRow: View {
    @Environment(AppContainer.self) private var container

    private let columns = Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.sm), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            if isWorkingLike {
                Button {
                    container.commandRouter.dispatch(.pauseSession)
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .buttonStyle(GlassButtonStyle(prominence: .secondary(DesignTokens.Colors.textSecondary)))
                .frame(maxWidth: 140)
            }

            LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.sm) {
                dashboardControlButton(
                    label: isPaused ? "Resume" : "Start",
                    symbol: "play.fill",
                    tint: DesignTokens.Colors.accentBlue,
                    prominence: isIdle || isPaused ? .primary(DesignTokens.Colors.accentBlue) : .secondary(DesignTokens.Colors.accentBlue),
                    isDisabled: !(isIdle || isPaused)
                ) {
                    if isPaused {
                        container.commandRouter.dispatch(.resumeSession)
                    } else {
                        container.commandRouter.dispatch(.startSession(taskLabel: "Deep Work"))
                    }
                }

                dashboardControlButton(
                    label: "Stop",
                    symbol: "stop.fill",
                    tint: DesignTokens.Colors.accentRed,
                    prominence: .primary(DesignTokens.Colors.accentRed),
                    isDisabled: isIdle
                ) {
                    container.commandRouter.dispatch(.stopSession)
                }

                dashboardControlButton(
                    label: "Start Break",
                    symbol: "cup.and.saucer.fill",
                    tint: DesignTokens.Colors.accentMint,
                    prominence: .secondary(DesignTokens.Colors.accentMint),
                    isDisabled: !(isRunning || isExtended)
                ) {
                    container.commandRouter.dispatch(.startBreak)
                }

                dashboardControlButton(
                    label: "End Break",
                    symbol: "play.fill",
                    tint: DesignTokens.Colors.accentMint,
                    prominence: isOnBreak ? .primary(DesignTokens.Colors.accentMint) : .secondary(DesignTokens.Colors.accentMint),
                    isDisabled: !isOnBreak
                ) {
                    container.commandRouter.dispatch(.endBreak)
                }

                dashboardControlButton(
                    label: "Extend",
                    symbol: "forward.fill",
                    tint: DesignTokens.Colors.accentAmber,
                    prominence: .secondary(DesignTokens.Colors.accentAmber),
                    isDisabled: !isRunning
                ) {
                    container.commandRouter.dispatch(.extendSession)
                }

                dashboardControlButton(
                    label: "Dashboard",
                    symbol: "rectangle.grid.2x2",
                    tint: DesignTokens.Colors.textSecondary,
                    prominence: .secondary(DesignTokens.Colors.textSecondary),
                    isDisabled: false
                ) {
                    container.commandRouter.dispatch(.openDashboard)
                }
            }
        }
    }

    private var isIdle: Bool { container.sessionEngine.currentState == .idle }
    private var isRunning: Bool { container.sessionEngine.currentState == .running }
    private var isExtended: Bool { container.sessionEngine.currentState == .extended }
    private var isPaused: Bool { container.sessionEngine.currentState == .paused }
    private var isOnBreak: Bool { container.sessionEngine.currentState == .onBreak }
    private var isWorkingLike: Bool { isRunning || isExtended }

    private func dashboardControlButton(
        label: String,
        symbol: String,
        tint: Color,
        prominence: GlassButtonStyle.Prominence,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(label, systemImage: symbol)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlassButtonStyle(prominence: prominence))
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.46 : 1)
    }
}

private struct OverviewWorkspaceView: View {
    @Environment(AppContainer.self) private var container

    @State private var selectedRange: SummaryRange = .week

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            DashboardSectionCard(title: "Overview", subtitle: "Live totals") {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    Picker("Range", selection: $selectedRange) {
                        ForEach(SummaryRange.allCases) { range in
                            Text(range.title).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 180), spacing: DesignTokens.Spacing.md)],
                        alignment: .leading,
                        spacing: DesignTokens.Spacing.md
                    ) {
                        MetricTile(title: "Today", value: container.sessionEngine.summary(for: .day).totalTracked.formattedDuration)
                        MetricTile(title: "This Week", value: container.sessionEngine.summary(for: .week).totalTracked.formattedDuration)
                        MetricTile(title: "This Month", value: container.sessionEngine.summary(for: .month).totalTracked.formattedDuration)
                        MetricTile(title: "Range Sessions", value: "\(container.sessionEngine.summary(for: selectedRange).sessionsCount)")
                    }
                }
            }

            HStack(alignment: .top, spacing: DesignTokens.Spacing.lg) {
                DashboardSectionCard(title: "Activity", subtitle: "Tracked vs break time") {
                    DashboardActivityChart(points: container.sessionEngine.chartPoints(for: selectedRange))
                }

                DashboardSectionCard(title: "Composition", subtitle: "Time split") {
                    DashboardCompositionChart(summary: container.sessionEngine.summary(for: selectedRange))
                }
            }

            DashboardSectionCard(title: "Recent Sessions", subtitle: "Latest records") {
                if container.sessionEngine.recentHistory().isEmpty {
                    EmptyDashboardState(
                        title: "No sessions yet",
                        message: "Start a session from the card above and your first records will appear here."
                    )
                } else {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(container.sessionEngine.recentHistory()) { record in
                            HistoryRow(record: record, showsActions: false, onEdit: {}, onDelete: {})
                        }
                    }
                }
            }
        }
    }
}

private struct HistoryWorkspaceView: View {
    @Environment(AppContainer.self) private var container

    @State private var selectedRange: SummaryRange = .week
    @State private var stateFilter: HistoryStateFilter = .all
    @State private var searchText = ""
    @State private var editingRecord: SessionRecord?
    @State private var pendingDeletion: SessionRecord?
    @State private var recentlyDeleted: SessionRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            if let recentlyDeleted {
                DashboardUndoBanner(taskLabel: recentlyDeleted.taskLabel) {
                    container.sessionEngine.restoreRecord(recentlyDeleted)
                    self.recentlyDeleted = nil
                } dismissAction: {
                    self.recentlyDeleted = nil
                }
            }

            DashboardSectionCard(title: "Filters", subtitle: "Use desktop-friendly filters to narrow history before correcting any records.") {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Picker("Range", selection: $selectedRange) {
                            ForEach(SummaryRange.allCases) { range in
                                Text(range.title).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("State", selection: $stateFilter) {
                            ForEach(HistoryStateFilter.allCases) { filter in
                                Text(filter.title).tag(filter)
                            }
                        }
                        .frame(maxWidth: 200)
                    }

                    TextField("Search task or notes", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                }
            }

            DashboardSectionCard(title: "Session History", subtitle: "\(filteredRecords.count) record\(filteredRecords.count == 1 ? "" : "s") in the current filter.") {
                if filteredRecords.isEmpty {
                    EmptyDashboardState(
                        title: "No matching sessions",
                        message: "Adjust the range, state, or search term to widen the history results."
                    )
                } else {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        historyTableHeader

                        ForEach(filteredRecords) { record in
                            HistoryRow(record: record, showsActions: true) {
                                editingRecord = record
                            } onDelete: {
                                pendingDeletion = record
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $editingRecord) { record in
            SessionEditSheet(record: record) { updatedRecord in
                container.sessionEngine.updateRecord(updatedRecord)
            }
        }
        .alert("Delete Session?", isPresented: deleteAlertBinding, presenting: pendingDeletion) { record in
            Button("Delete", role: .destructive) {
                recentlyDeleted = container.sessionEngine.deleteRecord(id: record.id)
                pendingDeletion = nil
            }

            Button("Cancel", role: .cancel) {
                pendingDeletion = nil
            }
        } message: { record in
            Text("Remove the session for \(record.taskLabel)? You can undo the deletion from the history panel.")
        }
    }

    private var filteredRecords: [SessionRecord] {
        container.sessionEngine.filteredHistory(
            SessionHistoryFilter(
                range: selectedRange,
                state: stateFilter.sessionState,
                searchText: searchText
            )
        )
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDeletion = nil
                }
            }
        )
    }

    private var historyTableHeader: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            headerCell("Date", width: 130, alignment: .leading)
            headerCell("State", width: 110, alignment: .leading)
            headerCell("Task", width: nil, alignment: .leading)
            headerCell("Duration", width: 120, alignment: .trailing)
            headerCell("Actions", width: 150, alignment: .trailing)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.bottom, DesignTokens.Spacing.xs)
    }

    private func headerCell(_ title: String, width: CGFloat?, alignment: Alignment) -> some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(DesignTokens.Colors.textSecondary)
            .frame(maxWidth: width == nil ? .infinity : width, alignment: alignment)
            .frame(width: width, alignment: alignment)
    }
}

private struct InsightsWorkspaceView: View {
    @Environment(AppContainer.self) private var container

    @State private var selectedRange: SummaryRange = .week

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            DashboardSectionCard(title: "Trend View", subtitle: "Range chart") {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    Picker("Insights Range", selection: $selectedRange) {
                        ForEach(SummaryRange.allCases) { range in
                            Text(range.title).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    DashboardActivityChart(points: container.sessionEngine.chartPoints(for: selectedRange))
                }
            }

            HStack(alignment: .top, spacing: DesignTokens.Spacing.lg) {
                DashboardSectionCard(title: "Session Volume", subtitle: "Per period") {
                    DashboardSessionCountChart(points: container.sessionEngine.chartPoints(for: selectedRange))
                }

                DashboardSectionCard(title: "Split", subtitle: "Tracked vs break") {
                    DashboardCompositionChart(summary: container.sessionEngine.summary(for: selectedRange))
                }
            }
        }
    }
}

private struct SettingsWorkspaceView: View {
    @Environment(AppContainer.self) private var container

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            DashboardSectionCard(title: "Launch", subtitle: "Startup") {
                Toggle("Launch at login", isOn: launchAtLoginBinding)
                    .toggleStyle(.switch)
            }

            DashboardSectionCard(title: "Notch Behavior", subtitle: "Hover timings") {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
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
            }

            DashboardSectionCard(title: "Reminders", subtitle: "Break alerts") {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Toggle("Break reminders", isOn: remindersEnabledBinding)
                        .toggleStyle(.switch)

                    Stepper(
                        "Reminder interval: \(container.settings.breakReminderMinutes) min",
                        value: reminderMinutesBinding,
                        in: 15...180,
                        step: 15
                    )
                    .disabled(!container.settings.breakRemindersEnabled)
                }
            }
        }
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

private struct DashboardSectionCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            content
        }
        .panelCardStyle()
    }
}

private struct DashboardActivityChart: View {
    let points: [SessionChartPoint]

    var body: some View {
        if points.isEmpty {
            EmptyDashboardState(
                title: "No chart data",
                message: "Complete a few sessions to build up trend data for this range."
            )
        } else {
            Chart(points) { point in
                AreaMark(
                    x: .value("Period", point.label),
                    y: .value("Tracked", point.trackedDuration / 3600)
                )
                .foregroundStyle(DesignTokens.Colors.accentBlue.opacity(0.16))

                LineMark(
                    x: .value("Period", point.label),
                    y: .value("Tracked", point.trackedDuration / 3600)
                )
                .foregroundStyle(DesignTokens.Colors.accentBlue)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)

                BarMark(
                    x: .value("Period", point.label),
                    y: .value("Break", point.breakDuration / 3600)
                )
                .foregroundStyle(DesignTokens.Colors.accentAmber.opacity(0.72))
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartLegend(position: .top, alignment: .leading)
            .frame(height: 220)
        }
    }
}

private struct DashboardCompositionChart: View {
    let summary: SessionSummary

    private var bars: [(label: String, value: Double, color: Color)] {
        [
            ("Tracked", summary.totalTracked / 3600, DesignTokens.Colors.accentBlue),
            ("Break", summary.totalBreak / 3600, DesignTokens.Colors.accentAmber)
        ]
    }

    var body: some View {
        if summary == .empty {
            EmptyDashboardState(
                title: "No split yet",
                message: "Run a few sessions to compare tracked time against breaks."
            )
        } else {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Chart(bars, id: \.label) { item in
                    BarMark(
                        x: .value("Hours", item.value),
                        y: .value("Type", item.label)
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .frame(height: 160)

                HStack(spacing: DesignTokens.Spacing.md) {
                    MetricTile(title: "Tracked", value: summary.totalTracked.formattedDuration)
                    MetricTile(title: "Break", value: summary.totalBreak.formattedDuration)
                }
            }
        }
    }
}

private struct DashboardSessionCountChart: View {
    let points: [SessionChartPoint]

    var body: some View {
        if points.isEmpty {
            EmptyDashboardState(
                title: "No session volume",
                message: "Start tracking to build a volume chart."
            )
        } else {
            Chart(points) { point in
                BarMark(
                    x: .value("Period", point.label),
                    y: .value("Sessions", point.sessionCount)
                )
                .foregroundStyle(DesignTokens.Colors.accentMint)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 220)
        }
    }
}

private struct DashboardStateChip: View {
    let state: SessionState

    var body: some View {
        Label(state.title, systemImage: state.symbolName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(DesignTokens.Colors.textPrimary)
            .glassChipStyle(tint: tint)
    }

    private var tint: Color {
        switch state {
        case .idle:
            DesignTokens.Colors.textSecondary
        case .running:
            DesignTokens.Colors.accentBlue
        case .extended:
            DesignTokens.Colors.accentAmber
        case .paused:
            DesignTokens.Colors.accentAmber
        case .onBreak:
            DesignTokens.Colors.accentMint
        }
    }
}

private struct HistoryRow: View {
    let record: SessionRecord
    let showsActions: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(record.endedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            .frame(width: 130, alignment: .leading)

            DashboardStateChip(state: record.state)
                .frame(width: 110, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.taskLabel)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                if let notes = record.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(record.duration.formattedDuration)
                .monospacedDigit()
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .frame(width: 120, alignment: .trailing)

            if showsActions {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Button("Edit", action: onEdit)
                        .buttonStyle(GlassButtonStyle(prominence: .secondary(DesignTokens.Colors.textSecondary)))

                    Button("Delete", role: .destructive, action: onDelete)
                        .buttonStyle(GlassButtonStyle(prominence: .secondary(DesignTokens.Colors.accentRed)))
                }
                .frame(width: 150, alignment: .trailing)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .panelCardStyle(padding: DesignTokens.Spacing.md)
    }
}

private struct SessionEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var taskLabel: String
    @State private var startedAt: Date
    @State private var endedAt: Date
    @State private var state: SessionState
    @State private var notes: String

    let record: SessionRecord
    let onSave: (SessionRecord) -> Void

    init(record: SessionRecord, onSave: @escaping (SessionRecord) -> Void) {
        self.record = record
        self.onSave = onSave
        _taskLabel = State(initialValue: record.taskLabel)
        _startedAt = State(initialValue: record.startedAt)
        _endedAt = State(initialValue: record.endedAt)
        _state = State(initialValue: record.state)
        _notes = State(initialValue: record.notes ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("Edit Session")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Form {
                TextField("Task", text: $taskLabel)

                Picker("State", selection: $state) {
                    ForEach(SessionState.allCases.filter { $0 != .idle }) { state in
                        Text(state.title).tag(state)
                    }
                }

                DatePicker("Started", selection: $startedAt, displayedComponents: [.date, .hourAndMinute])
                DatePicker("Ended", selection: $endedAt, displayedComponents: [.date, .hourAndMinute])

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .padding(6)
                        .panelCardStyle(padding: 6)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(GlassButtonStyle(prominence: .secondary(DesignTokens.Colors.textSecondary)))

                Button("Save Changes") {
                    onSave(
                        SessionRecord(
                            id: record.id,
                            startedAt: startedAt,
                            endedAt: endedAt,
                            taskLabel: taskLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Session" : taskLabel,
                            state: state,
                            createdAt: record.createdAt,
                            updatedAt: .now,
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
                        )
                    )
                    dismiss()
                }
                .buttonStyle(GlassButtonStyle(prominence: .primary(DesignTokens.Colors.accentBlue)))
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(minWidth: 520, minHeight: 440)
        .background(GlassBackgroundView())
    }
}

private struct DashboardUndoBanner: View {
    let taskLabel: String
    let undoAction: () -> Void
    let dismissAction: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .foregroundStyle(DesignTokens.Colors.accentBlue)

            VStack(alignment: .leading, spacing: 4) {
                Text("Session deleted")
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(taskLabel)
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Spacer()

            Button("Undo", action: undoAction)
                .buttonStyle(GlassButtonStyle(prominence: .primary(DesignTokens.Colors.accentBlue)))

            Button("Dismiss", action: dismissAction)
                .buttonStyle(GlassButtonStyle(prominence: .secondary(DesignTokens.Colors.textSecondary)))
        }
        .padding(DesignTokens.Spacing.md)
        .panelCardStyle(padding: DesignTokens.Spacing.md)
    }
}

private struct EmptyDashboardState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title)
                .font(.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text(message)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .panelCardStyle()
    }
}

private struct MetricTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            Text(value)
                .font(.system(size: 22, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(DesignTokens.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .panelCardStyle(padding: DesignTokens.Spacing.md)
    }
}

private struct LiveDurationText: View {
    let activeSession: ActiveSession?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            Text(durationString(for: timeline.date))
        }
    }

    private func durationString(for date: Date) -> String {
        guard let activeSession else {
            return "00:00:00"
        }

        return max(0, date.timeIntervalSince(activeSession.startedAt)).formattedDuration
    }
}

private struct HistoryHintBar: View {
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "info.circle")
                .foregroundStyle(DesignTokens.Colors.accentBlue)

            Text("Deletion requires confirmation, and the dashboard offers an immediate undo path to keep corrections safe.")
                .font(.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .panelCardStyle(padding: DesignTokens.Spacing.md)
    }
}

private enum HistoryStateFilter: String, CaseIterable, Identifiable {
    case all
    case running
    case extended
    case paused
    case onBreak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "All States"
        case .running:
            "Running"
        case .extended:
            "Extended"
        case .paused:
            "Paused"
        case .onBreak:
            "On Break"
        }
    }

    var sessionState: SessionState? {
        switch self {
        case .all:
            nil
        case .running:
            .running
        case .extended:
            .extended
        case .paused:
            .paused
        case .onBreak:
            .onBreak
        }
    }
}
