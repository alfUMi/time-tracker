import Foundation
import Observation

@MainActor
@Observable
final class IslandStateMachine {
    private(set) var sceneState: IslandSceneState = .notch
    private(set) var isPinned = false
    var onStateChanged: (() -> Void)?

    var hoverRevealDelayMilliseconds = 120
    var idleCollapseDelayMilliseconds = 900

    private var isPointerInsideHotzone = false
    private var isPointerInsideIsland = false
    private var hasFocusedContent = false
    private var revealTask: Task<Void, Never>?
    private var collapseTask: Task<Void, Never>?

    var isExpanded: Bool {
        isPinned
    }

    func updateSettings(_ settings: AppSettings) {
        hoverRevealDelayMilliseconds = settings.notchRevealDelayMilliseconds
        idleCollapseDelayMilliseconds = max(settings.notchCloseDelayMilliseconds * 3, 900)
    }

    func togglePinnedExpansion() {
        if isPinned {
            collapseToNotch()
        } else {
            pinCompactIsland()
        }
    }

    func expandFromInteraction() {
        // Clicking the island should not promote it into a larger panel.
    }

    func collapseToNotch() {
        cancelPendingTasks()
        isPinned = false
        isPointerInsideHotzone = false
        isPointerInsideIsland = false
        hasFocusedContent = false
        setSceneState(.notch)
    }

    func hotzoneHoverChanged(_ isHovering: Bool) {
        isPointerInsideHotzone = isHovering

        if isHovering {
            scheduleCompactReveal()
        } else {
            scheduleCollapseIfNeeded()
        }
    }

    func islandHoverChanged(_ isHovering: Bool) {
        isPointerInsideIsland = isHovering

        if isHovering {
            cancelCollapseTask()
        } else {
            scheduleCollapseIfNeeded()
        }
    }

    func contentFocusChanged(_ isFocused: Bool) {
        hasFocusedContent = isFocused

        if isFocused {
            cancelCollapseTask()
        } else {
            scheduleCollapseIfNeeded()
        }
    }

    func handleOutsideInteraction() {
        guard sceneState == .compactIsland else { return }
        guard !isPinned else { return }

        collapseToNotch()
    }

    private func pinCompactIsland() {
        cancelPendingTasks()
        isPinned = true
        setSceneState(.compactIsland)
    }

    private func scheduleCompactReveal() {
        guard !isPinned else { return }

        cancelRevealTask()
        cancelCollapseTask()

        revealTask = Task { [weak self] in
            guard let self else { return }

            try? await Task.sleep(nanoseconds: UInt64(hoverRevealDelayMilliseconds) * 1_000_000)
            guard !Task.isCancelled else { return }
            guard isPointerInsideHotzone else { return }
            guard sceneState == .notch else { return }

            setSceneState(.compactIsland)
        }
    }

    private func scheduleCollapseIfNeeded() {
        guard !isPinned else { return }
        guard !isPointerInsideHotzone, !isPointerInsideIsland, !hasFocusedContent else { return }

        cancelRevealTask()
        cancelCollapseTask()

        collapseTask = Task { [weak self] in
            guard let self else { return }

            try? await Task.sleep(nanoseconds: UInt64(idleCollapseDelayMilliseconds) * 1_000_000)
            guard !Task.isCancelled else { return }
            guard !isPointerInsideHotzone, !isPointerInsideIsland, !hasFocusedContent else { return }

            setSceneState(.notch)
        }
    }

    private func setSceneState(_ newState: IslandSceneState) {
        guard sceneState != newState else { return }
        sceneState = newState
        onStateChanged?()
    }

    private func cancelPendingTasks() {
        cancelRevealTask()
        cancelCollapseTask()
    }

    private func cancelRevealTask() {
        revealTask?.cancel()
        revealTask = nil
    }

    private func cancelCollapseTask() {
        collapseTask?.cancel()
        collapseTask = nil
    }
}
