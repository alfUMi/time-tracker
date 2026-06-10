import AppKit
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
        .background(DashboardWindowFocusBridge())
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

private struct DashboardWindowFocusBridge: NSViewRepresentable {
    func makeNSView(context: Context) -> DashboardWindowFocusNSView {
        DashboardWindowFocusNSView()
    }

    func updateNSView(_ nsView: DashboardWindowFocusNSView, context: Context) {}
}

private final class DashboardWindowFocusNSView: NSView {
    private weak var observedWindow: NSWindow?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        guard window !== observedWindow else { return }
        observedWindow = window

        DispatchQueue.main.async { [weak self] in
            guard let window = self?.window else { return }

            window.identifier = NSUserInterfaceItemIdentifier(AppWindowID.dashboard)
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(window.contentView)
        }
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

                Text(activeSessionSummary)
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

    private var activeSessionSummary: String {
        if container.sessionEngine.activeSession == nil {
            return "No active session"
        }

        if container.sessionEngine.currentState == .onBreak {
            return "Break in progress"
        }

        return "Work in progress"
    }
}

private struct DashboardDetailView: View {
    @Environment(AppContainer.self) private var container

    let section: DashboardSection

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                DashboardHeader(section: section)

                switch section.id {
                case DashboardSection.history.id:
                    HistoryWorkspaceView()
                case DashboardSection.insights.id:
                    InsightsWorkspaceView()
                case DashboardSection.settings.id:
                    SettingsWorkspaceView()
                default:
                    CurrentSessionPanel()

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

            DashboardStateChip(state: container.sessionEngine.currentState)
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
            "Current situation and charts for today."
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

                    Text(sessionHeadline)
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

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.md),
                    count: 3
                ),
                alignment: .leading,
                spacing: DesignTokens.Spacing.md
            ) {
                MetricTile(title: "Today Tracked", value: todaySummary.totalTracked.formattedDuration)
                MetricTile(title: "Today Break", value: todaySummary.totalBreak.formattedDuration)
                MetricTile(title: "Today Sessions", value: "\(todaySummary.sessionsCount)")
            }
        }
        .panelCardStyle()
    }

    private var todaySummary: SessionSummary {
        container.sessionEngine.summary(for: .day)
    }

    private var sessionHeadline: String {
        if container.sessionEngine.activeSession == nil {
            return "Ready to start."
        }

        if container.sessionEngine.currentState == .onBreak {
            return "Break in progress"
        }

        return "Work in progress"
    }
}

private struct OverviewWorkspaceView: View {
    @Environment(AppContainer.self) private var container

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            DashboardSectionCard(title: "Activity", subtitle: "Today by time") {
                DashboardActivityChart(points: container.sessionEngine.chartPoints(for: .day))
            }
        }
    }
}

private struct HistoryWorkspaceView: View {
    @Environment(AppContainer.self) private var container

    @State private var selectedRange: SummaryRange = .week
    @State private var stateFilter: HistoryStateFilter = .all
    @State private var editingRecord: SessionRecord?
    @State private var pendingDeletion: SessionRecord?
    @State private var recentlyDeleted: SessionRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            if let recentlyDeleted {
                DashboardUndoBanner {
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
                }
            }

            DashboardSectionCard(title: "Session History", subtitle: "\(filteredRecords.count) record\(filteredRecords.count == 1 ? "" : "s") in the current filter.") {
                if filteredRecords.isEmpty {
                    EmptyDashboardState(
                        title: "No matching sessions",
                        message: "Adjust the range or state filter to widen the history results."
                    )
                } else {
                    VStack(spacing: 0) {
                        historyTableHeader

                        historyTableDivider

                        ForEach(Array(filteredRecords.enumerated()), id: \.element.id) { index, record in
                            HistoryRow(record: record, showsActions: true) {
                                editingRecord = record
                            } onDelete: {
                                pendingDeletion = record
                            }

                            if index < filteredRecords.count - 1 {
                                historyTableDivider
                                    .padding(.leading, DesignTokens.Spacing.md)
                            }
                        }
                    }
                    .background(DesignTokens.Colors.surfaceRaised.opacity(0.42))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.large, style: .continuous)
                            .stroke(DesignTokens.Colors.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.large, style: .continuous))
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
            Text("Remove this record? You can undo the deletion from the history panel.")
        }
    }

    private var filteredRecords: [SessionRecord] {
        container.sessionEngine.filteredHistory(
            SessionHistoryFilter(
                range: selectedRange,
                state: stateFilter.sessionState
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
            headerCell("Notes", width: nil, alignment: .leading)
            headerCell("Duration", width: 120, alignment: .trailing)
            headerCell("Actions", width: 150, alignment: .trailing)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surfaceRaised.opacity(0.72))
    }

    private func headerCell(_ title: String, width: CGFloat?, alignment: Alignment) -> some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(DesignTokens.Colors.textSecondary)
            .frame(maxWidth: width == nil ? .infinity : width, alignment: alignment)
            .frame(width: width, alignment: alignment)
    }

    private var historyTableDivider: some View {
        Rectangle()
            .fill(DesignTokens.Colors.border)
            .frame(height: 1)
    }
}

private struct InsightsWorkspaceView: View {
    @Environment(AppContainer.self) private var container

    @State private var selectedRange: SummaryRange = .week
    @State private var lowerCardHeight: CGFloat = 0

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
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(cardHeightReader)
                .frame(height: lowerCardHeight == 0 ? nil : lowerCardHeight, alignment: .top)

                DashboardSectionCard(title: "Split", subtitle: "Tracked vs break") {
                    DashboardCompositionChart(summary: container.sessionEngine.summary(for: selectedRange))
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(cardHeightReader)
                .frame(height: lowerCardHeight == 0 ? nil : lowerCardHeight, alignment: .top)
            }
        }
        .onPreferenceChange(InsightsCardHeightPreferenceKey.self) { height in
            lowerCardHeight = height
        }
    }

    private var cardHeightReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(key: InsightsCardHeightPreferenceKey.self, value: proxy.size.height)
        }
    }
}

private struct InsightsCardHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct SettingsWorkspaceView: View {
    @Environment(AppContainer.self) private var container
    @State private var holidayDraftDate = Calendar.current.startOfDay(for: .now)

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            DashboardSectionCard(title: "Launch", subtitle: "Startup") {
                Toggle("Launch at login", isOn: launchAtLoginBinding)
                    .toggleStyle(.switch)
            }

            DashboardSectionCard(title: "Work Schedule", subtitle: "Automatic weekday timer") {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Toggle("Automatic work timer", isOn: automaticWorkTimerBinding)
                        .toggleStyle(.switch)

                    HStack(spacing: DesignTokens.Spacing.md) {
                        settingsTimeField(title: "Start", selection: workdayStartBinding)

                        settingsTimeField(title: "End", selection: workdayEndBinding)
                    }
                    .disabled(!container.settings.automaticWorkTimerEnabled)
                }
            }

            DashboardSectionCard(title: "Holidays", subtitle: "Skip automatic starts on these dates") {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        SettingsDateInputField(selection: $holidayDraftDate)

                        Button("Add Holiday") {
                            addHolidayDate()
                        }
                        .buttonStyle(GlassButtonStyle(prominence: .secondary(DesignTokens.Colors.textSecondary)))
                        .frame(maxWidth: 140)
                    }

                    if holidayDates.isEmpty {
                        Text("No holidays configured.")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    } else {
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            ForEach(holidayDates, id: \.self) { holiday in
                                HStack(spacing: DesignTokens.Spacing.md) {
                                    Text(holiday.formatted(date: .abbreviated, time: .omitted))
                                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                                    Spacer()

                                    Button("Remove") {
                                        removeHolidayDate(holiday)
                                    }
                                    .buttonStyle(GlassButtonStyle(prominence: .secondary(DesignTokens.Colors.accentRed)))
                                    .frame(maxWidth: 100)
                                }

                                if holiday != holidayDates.last {
                                    Rectangle()
                                        .fill(DesignTokens.Colors.border)
                                        .frame(height: 1)
                                }
                            }
                        }
                    }
                }
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

    private var automaticWorkTimerBinding: Binding<Bool> {
        Binding(
            get: { container.settings.automaticWorkTimerEnabled },
            set: { newValue in
                var updated = container.settings
                updated.automaticWorkTimerEnabled = newValue
                container.saveSettings(updated)
            }
        )
    }

    private var workdayStartBinding: Binding<Date> {
        Binding(
            get: { timeOnlyDate(for: container.settings.workdayStartMinutes) },
            set: { newValue in
                var updated = container.settings
                let proposedStart = minutesSinceMidnight(for: newValue)
                updated.workdayStartMinutes = min(proposedStart, updated.workdayEndMinutes - 15)
                container.saveSettings(updated)
            }
        )
    }

    private var workdayEndBinding: Binding<Date> {
        Binding(
            get: { timeOnlyDate(for: container.settings.workdayEndMinutes) },
            set: { newValue in
                var updated = container.settings
                let proposedEnd = minutesSinceMidnight(for: newValue)
                updated.workdayEndMinutes = max(proposedEnd, updated.workdayStartMinutes + 15)
                container.saveSettings(updated)
            }
        )
    }

    private var holidayDates: [Date] {
        container.settings.holidayDates
            .map { Calendar.current.startOfDay(for: $0) }
            .sorted()
    }

    private func addHolidayDate() {
        let normalizedDate = Calendar.current.startOfDay(for: holidayDraftDate)
        guard !holidayDates.contains(normalizedDate) else { return }

        var updated = container.settings
        updated.holidayDates.append(normalizedDate)
        updated.holidayDates.sort()
        container.saveSettings(updated)
    }

    private func removeHolidayDate(_ date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        var updated = container.settings
        updated.holidayDates.removeAll {
            Calendar.current.isDate(Calendar.current.startOfDay(for: $0), inSameDayAs: normalizedDate)
        }
        container.saveSettings(updated)
    }

    private func timeOnlyDate(for minutes: Int) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        return calendar.date(
            bySettingHour: hours,
            minute: remainingMinutes,
            second: 0,
            of: startOfDay
        ) ?? startOfDay
    }

    private func minutesSinceMidnight(for date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        return (hour * 60) + minute
    }

    private func settingsTimeField(title: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            SettingsTimeInputField(selection: selection)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

private struct SettingsTimeInputField: View {
    let selection: Binding<Date>

    @State private var hourText: String
    @State private var minuteText: String
    @FocusState private var focusedSegment: Segment?

    private enum Segment {
        case hour
        case minute
    }

    init(selection: Binding<Date>) {
        self.selection = selection

        let components = Calendar.current.dateComponents([.hour, .minute], from: selection.wrappedValue)
        _hourText = State(initialValue: Self.formattedSegment(components.hour ?? 0))
        _minuteText = State(initialValue: Self.formattedSegment(components.minute ?? 0))
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            SettingsTimeSegmentField(text: $hourText, placeholder: "HH")
                .focused($focusedSegment, equals: .hour)
                .onSubmit {
                    commitAndNormalize()
                    focusedSegment = .minute
                }

            Text(":")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            SettingsTimeSegmentField(text: $minuteText, placeholder: "MM")
                .focused($focusedSegment, equals: .minute)
                .onSubmit {
                    commitAndNormalize()
                }
        }
        .frame(maxWidth: .infinity, minHeight: 38, maxHeight: 38, alignment: .leading)
        .onChange(of: hourText) { oldValue, newValue in
            let sanitized = Self.sanitizedSegmentInput(
                newValue,
                previous: oldValue,
                allowedRange: 0...23
            )

            guard sanitized != newValue else { return }
            hourText = sanitized
        }
        .onChange(of: minuteText) { oldValue, newValue in
            let sanitized = Self.sanitizedSegmentInput(
                newValue,
                previous: oldValue,
                allowedRange: 0...59
            )

            guard sanitized != newValue else { return }
            minuteText = sanitized
        }
        .onChange(of: focusedSegment) { _, newValue in
            guard newValue == nil else { return }
            commitAndNormalize()
        }
        .onChange(of: selection.wrappedValue) { _, newValue in
            guard focusedSegment == nil else { return }
            syncSegments(with: newValue)
        }
    }

    private func commitAndNormalize() {
        guard
            let hour = Int(hourText),
            let minute = Int(minuteText),
            (0...23).contains(hour),
            (0...59).contains(minute)
        else {
            syncSegments(with: selection.wrappedValue)
            return
        }

        let normalizedDate = Self.date(hour: hour, minute: minute, basedOn: selection.wrappedValue)
        selection.wrappedValue = normalizedDate
        syncSegments(with: normalizedDate)
    }

    private func syncSegments(with date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        hourText = Self.formattedSegment(components.hour ?? 0)
        minuteText = Self.formattedSegment(components.minute ?? 0)
    }

    private static func sanitizedSegmentInput(
        _ value: String,
        previous: String,
        allowedRange: ClosedRange<Int>
    ) -> String {
        let digits = value.filter(\.isNumber)
        let trimmedDigits = String(digits.prefix(2))

        guard trimmedDigits.count == 2 else {
            return trimmedDigits
        }

        guard let parsedValue = Int(trimmedDigits), allowedRange.contains(parsedValue) else {
            return String(previous.filter(\.isNumber).prefix(2))
        }

        return trimmedDigits
    }

    private static func formattedSegment(_ value: Int) -> String {
        String(format: "%02d", value)
    }

    private static func date(hour: Int, minute: Int, basedOn date: Date) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: startOfDay
        ) ?? startOfDay
    }
}

private struct SettingsDateInputField: View {
    let selection: Binding<Date>

    @State private var isPickerPresented = false

    private var formattedDate: String {
        selection.wrappedValue.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        Button {
            isPickerPresented.toggle()
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Text(formattedDate)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Spacer(minLength: 0)

                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 38, maxHeight: 38, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous)
                    .fill(DesignTokens.Colors.surfaceRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous)
                            .stroke(DesignTokens.Colors.border, lineWidth: 1)
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Holiday")
        .popover(isPresented: $isPickerPresented) {
            DatePicker("Holiday", selection: selection, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(DesignTokens.Spacing.md)
                .frame(minWidth: 260)
        }
    }
}

private struct SettingsTimeSegmentField: View {
    @Binding var text: String

    let placeholder: String

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(.system(size: 16, weight: .medium, design: .monospaced))
            .multilineTextAlignment(.center)
            .foregroundStyle(DesignTokens.Colors.textPrimary)
            .frame(width: 48)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous)
                    .fill(DesignTokens.Colors.surfaceRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous)
                            .stroke(DesignTokens.Colors.border, lineWidth: 1)
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous))
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            GeometryReader { proxy in
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
                .frame(
                    maxWidth: .infinity,
                    minHeight: 220,
                    idealHeight: max(proxy.size.height, 220),
                    maxHeight: .infinity,
                    alignment: .top
                )
            }
            .frame(minHeight: 220)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        let notesText = (record.notes ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

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
                Text(notesText.isEmpty ? "No notes" : notesText)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
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
        .background(DesignTokens.Colors.surface.opacity(0.18))
    }
}

private struct SessionEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var startedAt: Date
    @State private var endedAt: Date
    @State private var state: SessionState
    @State private var notes: String

    let record: SessionRecord
    let onSave: (SessionRecord) -> Void

    init(record: SessionRecord, onSave: @escaping (SessionRecord) -> Void) {
        self.record = record
        self.onSave = onSave
        _startedAt = State(initialValue: record.startedAt)
        _endedAt = State(initialValue: record.endedAt)
        _state = State(initialValue: record.state)
        _notes = State(initialValue: record.notes ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("Edit Record")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Form {
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
    let undoAction: () -> Void
    let dismissAction: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .foregroundStyle(DesignTokens.Colors.accentBlue)

            VStack(alignment: .leading, spacing: 4) {
                Text("Session deleted")
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
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
