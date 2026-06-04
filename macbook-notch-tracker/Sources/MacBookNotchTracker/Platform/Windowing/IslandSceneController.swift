import AppKit
import Observation
import SwiftUI

private enum IslandSceneMetrics {
    static let windowLevel = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 2)
}

private func makePlaceholderDisplayGeometry() -> IslandDisplayGeometry {
    let emptyShape = IslandShapeSnapshot(
        frame: .zero,
        visibleHeight: 0,
        topAttachmentWidth: 0,
        topCornerRadius: 0,
        topInnerFilletRadius: 0,
        topClipInset: 0,
        topCurveOverflow: 0,
        shoulderDepth: 0,
        bottomCornerRadius: 0,
        hoverFrame: .zero
    )
    let emptyLayout = IslandWindowLayout(
        surfaceFrame: .zero,
        notchShape: emptyShape,
        compactShape: emptyShape,
        expandedShape: emptyShape
    )

    return IslandDisplayGeometry(
        screenFrame: .zero,
        surfaceLayout: emptyLayout
    )
}

@MainActor
@Observable
private final class IslandRuntimeModel {
    var sceneState: IslandSceneState = .notch
    var displayGeometry: IslandDisplayGeometry = makePlaceholderDisplayGeometry()
}

private final class IslandSurfaceWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class IslandSceneController: IslandSceneControlling {
    private weak var container: AppContainer?
    private let runtimeModel = IslandRuntimeModel()
    private var surfaceWindow: IslandSurfaceWindow?
    private var hostingView: NSHostingView<IslandSurfaceContainerView>?
    private var hotzoneWindow: IslandSurfaceWindow?
    private var hotzoneHostingView: NSHostingView<IslandHotzoneContainerView>?
    private var didInstall = false
    private var screenObserver: NSObjectProtocol?
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?

    deinit {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }

        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
        }

        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
        }
    }

    func install(container: AppContainer) {
        guard !didInstall else { return }

        self.container = container
        self.didInstall = true
        refreshDisplayGeometry()
        createSurfaceWindow(container: container)
        createHotzoneWindow(container: container)
        installEventMonitors()
        updateSceneState(runtimeModel.sceneState)

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshDisplayGeometry()
                self?.repositionSurfaceWindow()
            }
        }
    }

    func updateSceneState(_ state: IslandSceneState) {
        runtimeModel.sceneState = state

        guard let surfaceWindow, let hotzoneWindow else { return }

        if state == .hidden {
            surfaceWindow.orderOut(nil)
            hotzoneWindow.orderOut(nil)
            return
        }

        repositionSurfaceWindow()
        repositionHotzoneWindow()

        let isClosed = state == .notch
        surfaceWindow.ignoresMouseEvents = isClosed

        if isClosed {
            hotzoneWindow.ignoresMouseEvents = false
            hotzoneWindow.orderFrontRegardless()
        } else {
            hotzoneWindow.orderOut(nil)
        }

        surfaceWindow.orderFrontRegardless()
    }

    private func createSurfaceWindow(container: AppContainer) {
        let geometry = runtimeModel.displayGeometry
        let surfaceFrame = geometry.surfaceFrame
        let window = IslandSurfaceWindow(
            contentRect: surfaceFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = IslandSceneMetrics.windowLevel
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle, .fullScreenAuxiliary, .stationary]
        window.animationBehavior = .none
        window.ignoresMouseEvents = false
        window.isMovable = false

        let contentView = NSHostingView(
            rootView: IslandSurfaceContainerView(
                container: container,
                runtimeModel: runtimeModel
            )
        )
        contentView.frame = CGRect(origin: .zero, size: surfaceFrame.size)
        contentView.autoresizingMask = [.width, .height]
        contentView.wantsLayer = true
        contentView.layer?.masksToBounds = false

        window.contentView = contentView

        hostingView = contentView
        surfaceWindow = window
    }

    private func createHotzoneWindow(container: AppContainer) {
        let window = IslandSurfaceWindow(
            contentRect: runtimeModel.displayGeometry.hotzoneWindowFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = IslandSceneMetrics.windowLevel
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle, .fullScreenAuxiliary, .stationary]
        window.animationBehavior = .none
        window.ignoresMouseEvents = false
        window.isMovable = false

        let contentView = NSHostingView(
            rootView: IslandHotzoneContainerView(
                container: container
            )
        )
        contentView.frame = CGRect(origin: .zero, size: runtimeModel.displayGeometry.hotzoneWindowFrame.size)
        contentView.autoresizingMask = [.width, .height]
        contentView.wantsLayer = true
        contentView.layer?.masksToBounds = false

        window.contentView = contentView

        hotzoneHostingView = contentView
        hotzoneWindow = window
    }

    private func installEventMonitors() {
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleMouseDown(at: NSEvent.mouseLocation)
            }

            return event
        }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleMouseDown(at: NSEvent.mouseLocation)
            }
        }
    }

    private func handleMouseDown(at screenLocation: CGPoint) {
        _ = screenLocation
    }

    private func refreshDisplayGeometry() {
        guard let screen = preferredScreen() else { return }
        runtimeModel.displayGeometry = IslandGeometryEngine.geometry(for: screen)
    }

    private func repositionSurfaceWindow() {
        guard let surfaceWindow else { return }

        let surfaceFrame = runtimeModel.displayGeometry.surfaceFrame

        surfaceWindow.setFrame(surfaceFrame, display: true)
        hostingView?.frame = CGRect(origin: .zero, size: surfaceFrame.size)
    }

    private func repositionHotzoneWindow() {
        guard let hotzoneWindow else { return }

        let hotzoneFrame = runtimeModel.displayGeometry.hotzoneWindowFrame

        hotzoneWindow.setFrame(hotzoneFrame, display: true)
        hotzoneHostingView?.frame = CGRect(origin: .zero, size: hotzoneFrame.size)
    }

    private func preferredScreen() -> NSScreen? {
        for screen in NSScreen.screens {
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                continue
            }

            let displayID = CGDirectDisplayID(screenNumber.uint32Value)

            if CGDisplayIsBuiltin(displayID) != 0 {
                return screen
            }
        }

        return NSScreen.main ?? NSScreen.screens.first
    }
}

private struct IslandSurfaceContainerView: View {
    let container: AppContainer
    let runtimeModel: IslandRuntimeModel

    var body: some View {
        IslandSurfaceRootView()
            .environment(container)
            .environment(runtimeModel)
            .preferredColorScheme(.dark)
    }
}

private struct IslandSurfaceRootView: View {
    @Environment(AppContainer.self) private var container
    @Environment(IslandRuntimeModel.self) private var runtimeModel

    var body: some View {
        let layout = runtimeModel.displayGeometry.surfaceLayout
        let shape = layout.shape(for: runtimeModel.sceneState)
        let hotzone = layout.notchShape.frame
        let surfaceSize = layout.surfaceFrame.size

        ZStack(alignment: .topLeading) {
            Color.clear

            interactionRegion(hotzone)

            IslandRendererView(
                sceneState: runtimeModel.sceneState,
                shape: shape
            )
            .position(x: shape.frame.midX, y: shape.frame.midY)
        }
        .frame(width: surfaceSize.width, height: surfaceSize.height, alignment: .topLeading)
        .contentShape(Rectangle())
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: runtimeModel.sceneState)
    }

    private func interactionRegion(_ frame: CGRect) -> some View {
        NotchTrackingRegionView(
            onHoverChanged: { isHovering in
                container.handleIslandHotzone(isHovering)
            },
            onClick: {}
        )
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
    }
}

private struct IslandHotzoneContainerView: View {
    let container: AppContainer

    var body: some View {
        NotchTrackingRegionView(
            onHoverChanged: { isHovering in
                container.handleIslandHotzone(isHovering)
            },
            onClick: {}
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct NotchTrackingRegionView: NSViewRepresentable {
    let onHoverChanged: (Bool) -> Void
    let onClick: () -> Void

    func makeNSView(context: Context) -> TrackingRegionNSView {
        let view = TrackingRegionNSView()
        view.onHoverChanged = onHoverChanged
        view.onClick = onClick
        return view
    }

    func updateNSView(_ nsView: TrackingRegionNSView, context: Context) {
        nsView.onHoverChanged = onHoverChanged
        nsView.onClick = onClick
        nsView.refreshTrackingArea()
    }
}

private final class TrackingRegionNSView: NSView {
    var onHoverChanged: ((Bool) -> Void)?
    var onClick: (() -> Void)?

    private var trackingAreaRef: NSTrackingArea?
    private var isHovered = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        refreshTrackingArea()
    }

    func refreshTrackingArea() {
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }

        let trackingAreaRef = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited, .enabledDuringMouseDrag],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingAreaRef)
        self.trackingAreaRef = trackingAreaRef
    }

    override func mouseEntered(with event: NSEvent) {
        guard !isHovered else { return }
        isHovered = true
        onHoverChanged?(true)
    }

    override func mouseExited(with event: NSEvent) {
        guard isHovered else { return }
        isHovered = false
        onHoverChanged?(false)
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
}
