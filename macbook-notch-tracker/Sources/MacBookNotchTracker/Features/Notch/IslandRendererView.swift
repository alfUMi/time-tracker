import SwiftUI

private enum IslandRendererMetrics {
    static let pureBlack = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
    static let earRadius: CGFloat = 18

    static func contentPadding(for state: IslandSceneState, shape: IslandShapeSnapshot) -> EdgeInsets {
        let overflowInset = max(shape.topCurveOverflow, 0)

        switch state {
        case .hidden, .notch:
            return EdgeInsets()
        case .compactIsland:
            return EdgeInsets(
                top: overflowInset + 10,
                leading: 14,
                bottom: 10,
                trailing: 14
            )
        case .expandedIsland:
            return contentPadding(for: .compactIsland, shape: shape)
        }
    }

    static func contentAlignment(for state: IslandSceneState) -> Alignment {
        switch state {
        case .compactIsland:
            .topLeading
        case .hidden, .notch, .expandedIsland:
            .topLeading
        }
    }
}

struct IslandRendererView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.openWindow) private var openWindow

    let sceneState: IslandSceneState
    let shape: IslandShapeSnapshot

    var body: some View {
        let islandShape = IslandMorphShape(snapshot: shape)

        ZStack(alignment: .top) {
            ZStack(alignment: .top) {
                IslandSurfaceBackground()

                islandContent
                    .padding(IslandRendererMetrics.contentPadding(for: sceneState, shape: shape))
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: IslandRendererMetrics.contentAlignment(for: sceneState)
                    )
            }
            .clipShape(islandShape)

            IslandEarOverlay(
                sceneState: sceneState,
                snapshot: shape
            )
                .allowsHitTesting(false)
        }
        .frame(width: shape.frame.width, height: shape.frame.height, alignment: .top)
        .contentShape(islandShape)
        .onHover { isHovering in
            container.handleIslandHover(isHovering)
        }
        .opacity(sceneState == .hidden ? 0 : 1)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: sceneState)
    }

    @ViewBuilder
    private var islandContent: some View {
        switch sceneState {
        case .hidden, .notch:
            EmptyView()
        case .compactIsland, .expandedIsland:
            compactContent
        }
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Circle()
                    .fill(stateTint)
                    .frame(width: 8, height: 8)

                Text(compactLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.84)

                Spacer(minLength: 8)

                Text(timerText)
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }

            compactActionRow
        }
    }

    private var compactLabel: String {
        if let activeSession = container.sessionEngine.activeSession {
            return activeSession.taskLabel
        }

        return container.sessionEngine.currentState.title
    }

    private var timerText: String {
        guard let activeSession = container.sessionEngine.activeSession else {
            return "00:00:00"
        }

        return Date.now.timeIntervalSince(activeSession.startedAt).formattedDuration
    }

    private var compactActionRow: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            workActionButton

            breakActionButton

            iconButton(systemName: "rectangle.grid.2x2.fill", label: "Open dashboard") {
                openDashboard()
            }
        }
    }

    private func openDashboard() {
        container.commandRouter.dispatch(.openDashboard)

        openWindow(id: AppWindowID.dashboard)
    }

    @ViewBuilder
    private var workActionButton: some View {
        if hasStartedWorkPeriod {
            iconButton(systemName: "stop.circle.fill", label: "Stop work period") {
                container.commandRouter.dispatch(.stopSession)
            }
        } else {
            iconButton(
                systemName: "play.circle.fill",
                label: "Start work period",
                isDisabled: !isIdle
            ) {
                container.commandRouter.dispatch(.startSession(taskLabel: "Deep Work"))
            }
        }
    }

    @ViewBuilder
    private var breakActionButton: some View {
        if isOnBreak {
            iconButton(systemName: "stop.circle.fill", label: "Stop break") {
                container.commandRouter.dispatch(.endBreak)
            }
        } else {
            iconButton(
                systemName: "cup.and.saucer.fill",
                label: "Start break",
                isDisabled: !canStartBreak
            ) {
                container.commandRouter.dispatch(.startBreak)
            }
        }
    }

    private var stateTint: Color {
        switch container.sessionEngine.currentState {
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

    private var isIdle: Bool { container.sessionEngine.currentState == .idle }
    private var isRunning: Bool { container.sessionEngine.currentState == .running }
    private var isExtended: Bool { container.sessionEngine.currentState == .extended }
    private var isOnBreak: Bool { container.sessionEngine.currentState == .onBreak }
    private var isPaused: Bool { container.sessionEngine.currentState == .paused }
    private var hasStartedWorkPeriod: Bool { isRunning || isExtended || isPaused }
    private var canStartBreak: Bool { isRunning || isExtended }

    private func iconButton(
        systemName: String,
        label: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(NotchIconButtonStyle())
        .foregroundStyle(DesignTokens.Colors.textSecondary)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.46 : 1)
        .accessibilityLabel(label)
        .help(label)
    }
}

private struct IslandSurfaceBackground: View {
    var body: some View {
        IslandRendererMetrics.pureBlack
    }
}

private struct IslandMorphShape: Shape {
    let snapshot: IslandShapeSnapshot

    func path(in rect: CGRect) -> Path {
        let bottomRadius = min(snapshot.bottomCornerRadius, rect.width / 2, rect.height / 2)
        let topWidth = min(snapshot.topAttachmentWidth, rect.width)
        let shoulderDepth = min(snapshot.shoulderDepth, rect.height)
        let topMinX = rect.midX - (topWidth / 2)
        let topMaxX = rect.midX + (topWidth / 2)
        let shoulderControlInset = max((rect.width - topWidth) * 0.24, 1)
        let usesFullTopEdge = abs(topWidth - rect.width) < 0.5

        var path = Path()

        path.move(to: CGPoint(x: topMinX, y: rect.minY))
        path.addLine(to: CGPoint(x: topMaxX, y: rect.minY))

        if !usesFullTopEdge, shoulderDepth > 0.5 {
            path.addCurve(
                to: CGPoint(x: rect.maxX, y: shoulderDepth),
                control1: CGPoint(x: topMaxX + shoulderControlInset, y: rect.minY),
                control2: CGPoint(x: rect.maxX - shoulderControlInset, y: shoulderDepth)
            )
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRadius))
        path.addArc(
            tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
            tangent2End: CGPoint(x: rect.maxX - bottomRadius, y: rect.maxY),
            radius: bottomRadius
        )
        path.addLine(to: CGPoint(x: rect.minX + bottomRadius, y: rect.maxY))
        path.addArc(
            tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
            tangent2End: CGPoint(x: rect.minX, y: rect.maxY - bottomRadius),
            radius: bottomRadius
        )

        if !usesFullTopEdge, shoulderDepth > 0.5 {
            path.addLine(to: CGPoint(x: rect.minX, y: shoulderDepth))
            path.addCurve(
                to: CGPoint(x: topMinX, y: rect.minY),
                control1: CGPoint(x: rect.minX + shoulderControlInset, y: shoulderDepth),
                control2: CGPoint(x: topMinX - shoulderControlInset, y: rect.minY)
            )
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: topMinX, y: rect.minY))
        }

        path.closeSubpath()
        return path
    }
}

private struct IslandEarOverlay: View {
    let sceneState: IslandSceneState
    let snapshot: IslandShapeSnapshot

    var body: some View {
        if snapshot.topCornerRadius <= 0.5 {
            let earSize = min(targetEarSize, snapshot.frame.height)

            ZStack {
                MenuBarEarRepresentable(side: .left)
                    .frame(width: earSize, height: earSize)
                    .position(x: -(earSize / 2), y: earSize / 2)

                MenuBarEarRepresentable(side: .right)
                    .frame(width: earSize, height: earSize)
                    .position(x: snapshot.frame.width + (earSize / 2), y: earSize / 2)
            }
            .frame(width: snapshot.frame.width, height: snapshot.frame.height, alignment: .topLeading)
        }
    }

    private var targetEarSize: CGFloat {
        switch sceneState {
        case .hidden:
            0
        case .notch:
            6
        case .compactIsland:
            12
        case .expandedIsland:
            IslandRendererMetrics.earRadius
        }
    }
}

private struct MenuBarEarRepresentable: NSViewRepresentable {
    enum Side {
        case left
        case right
    }

    let side: Side

    func makeNSView(context: Context) -> MenuBarEarNSView {
        MenuBarEarNSView(side: side)
    }

    func updateNSView(_ nsView: MenuBarEarNSView, context: Context) {
        nsView.side = side
        nsView.refreshMask()
    }
}

private final class MenuBarEarNSView: NSView {
    var side: MenuBarEarRepresentable.Side

    private let maskLayer = CAShapeLayer()

    init(side: MenuBarEarRepresentable.Side) {
        self.side = side

        super.init(frame: .zero)

        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.mask = maskLayer
        maskLayer.fillRule = .evenOdd
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layout() {
        super.layout()
        refreshMask()
    }

    func refreshMask() {
        layer?.backgroundColor = NSColor.black.cgColor
        maskLayer.frame = bounds
        maskLayer.path = earMaskPath(in: bounds)
    }

    private func earMaskPath(in bounds: CGRect) -> CGPath {
        let radius = min(bounds.width, bounds.height)
        let path = CGMutablePath()
        path.addRect(bounds)

        let cutout = CGMutablePath()

        switch side {
        case .left:
            let center = CGPoint(x: bounds.minX, y: bounds.minY)
            cutout.move(to: center)
            cutout.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
            cutout.addArc(
                center: center,
                radius: radius,
                startAngle: 0,
                endAngle: .pi * 0.5,
                clockwise: false
            )
            cutout.closeSubpath()
        case .right:
            let center = CGPoint(x: bounds.maxX, y: bounds.minY)
            cutout.move(to: center)
            cutout.addLine(to: CGPoint(x: bounds.minX, y: bounds.minY))
            cutout.addArc(
                center: center,
                radius: radius,
                startAngle: .pi,
                endAngle: .pi * 0.5,
                clockwise: true
            )
            cutout.closeSubpath()
        }

        path.addPath(cutout)
        return path
    }
}

private struct NotchIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(DesignTokens.Colors.textSecondary.opacity(configuration.isPressed ? 0.72 : 1))
            .frame(width: 24, height: 24)
            .padding(6)
            .background(IslandRendererMetrics.pureBlack)
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.10 : 0.06), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
