import AppKit
import CoreGraphics

struct IslandShapeSnapshot: Equatable {
    let frame: CGRect
    let visibleHeight: CGFloat
    let topAttachmentWidth: CGFloat
    let topCornerRadius: CGFloat
    let topInnerFilletRadius: CGFloat
    let topClipInset: CGFloat
    let topCurveOverflow: CGFloat
    let shoulderDepth: CGFloat
    let bottomCornerRadius: CGFloat
    let hoverFrame: CGRect
}

struct IslandWindowLayout: Equatable {
    let surfaceFrame: CGRect
    let notchShape: IslandShapeSnapshot

    let compactShape: IslandShapeSnapshot

    let expandedShape: IslandShapeSnapshot

    func shape(for state: IslandSceneState) -> IslandShapeSnapshot {
        switch state {
        case .hidden, .notch:
            notchShape
        case .compactIsland:
            compactShape
        case .expandedIsland:
            expandedShape
        }
    }
}

struct IslandDisplayGeometry: Equatable {
    let screenFrame: CGRect
    let surfaceLayout: IslandWindowLayout

    func shape(for state: IslandSceneState) -> IslandShapeSnapshot {
        surfaceLayout.shape(for: state)
    }

    var surfaceFrame: CGRect {
        surfaceLayout.surfaceFrame
    }

    var hotzoneWindowFrame: CGRect {
        screenRect(for: surfaceLayout.notchShape.hoverFrame)
    }

    func screenRect(for localRect: CGRect) -> CGRect {
        CGRect(
            x: surfaceFrame.minX + localRect.minX,
            y: surfaceFrame.maxY - localRect.maxY,
            width: localRect.width,
            height: localRect.height
        )
    }
}

enum IslandGeometryEngine {
    private enum NotchReference {
        static let width: CGFloat = 178
        static let height: CGFloat = 33
    }

    private enum SurfacePadding {
        static let openEarInset: CGFloat = 18
        static let openBottomInset: CGFloat = 8
    }

    static func geometry(for screen: NSScreen) -> IslandDisplayGeometry {
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame
        let menuBarHeight = max(screenFrame.maxY - visibleFrame.maxY, 24)
        let notchWidth = NotchReference.width
        let notchHeight = NotchReference.height
        let notchBottomCornerRadius = notchHeight * 0.36
        let compactWidth = notchWidth * 2.08
        let compactHeight = max(notchHeight * 2.15, 72)
        let anchorX = screenFrame.width / 2

        let notchShape = makeNotchShape(
            anchorX: anchorX,
            width: notchWidth,
            height: notchHeight,
            bottomCornerRadius: notchBottomCornerRadius
        )
        let compactShape = makeShape(
            anchorX: anchorX,
            topWidth: compactWidth,
            topCornerRadius: 0,
            bodyWidth: compactWidth,
            height: compactHeight,
            topClipInset: 0,
            topCurveOverflow: 0,
            shoulderDepth: 0,
            bottomCornerRadius: notchBottomCornerRadius,
            hoverPadding: CGSize(width: menuBarHeight * 1.1, height: menuBarHeight * 0.55)
        )

        let openShapeBounds = notchShape.frame.union(compactShape.frame)
        let openSurfaceBounds = CGRect(
            x: openShapeBounds.minX - SurfacePadding.openEarInset,
            y: openShapeBounds.minY,
            width: openShapeBounds.width + (SurfacePadding.openEarInset * 2),
            height: openShapeBounds.height + SurfacePadding.openBottomInset
        )

        return IslandDisplayGeometry(
            screenFrame: screenFrame,
            surfaceLayout: makeLayout(
                screenFrame: screenFrame,
                surfaceBounds: openSurfaceBounds,
                notchShape: notchShape,
                compactShape: compactShape,
                expandedShape: compactShape
            )
        )
    }

    private static func makeLayout(
        screenFrame: CGRect,
        surfaceBounds: CGRect,
        notchShape: IslandShapeSnapshot,
        compactShape: IslandShapeSnapshot,
        expandedShape: IslandShapeSnapshot
    ) -> IslandWindowLayout {
        let surfaceFrame = CGRect(
            x: screenFrame.minX + surfaceBounds.minX,
            y: screenFrame.maxY - surfaceBounds.maxY,
            width: surfaceBounds.width,
            height: surfaceBounds.height
        )

        return IslandWindowLayout(
            surfaceFrame: surfaceFrame,
            notchShape: offset(snapshot: notchShape, by: surfaceBounds.origin),
            compactShape: offset(snapshot: compactShape, by: surfaceBounds.origin),
            expandedShape: offset(snapshot: expandedShape, by: surfaceBounds.origin)
        )
    }

    private static func offset(
        snapshot: IslandShapeSnapshot,
        by origin: CGPoint
    ) -> IslandShapeSnapshot {
        IslandShapeSnapshot(
            frame: snapshot.frame.offsetBy(dx: -origin.x, dy: -origin.y),
            visibleHeight: snapshot.visibleHeight,
            topAttachmentWidth: snapshot.topAttachmentWidth,
            topCornerRadius: snapshot.topCornerRadius,
            topInnerFilletRadius: snapshot.topInnerFilletRadius,
            topClipInset: snapshot.topClipInset,
            topCurveOverflow: snapshot.topCurveOverflow,
            shoulderDepth: snapshot.shoulderDepth,
            bottomCornerRadius: snapshot.bottomCornerRadius,
            hoverFrame: snapshot.hoverFrame.offsetBy(dx: -origin.x, dy: -origin.y)
        )
    }

    private static func makeShape(
        anchorX: CGFloat,
        topWidth: CGFloat,
        topCornerRadius: CGFloat,
        bodyWidth: CGFloat,
        height: CGFloat,
        topClipInset: CGFloat,
        topCurveOverflow: CGFloat,
        shoulderDepth: CGFloat,
        bottomCornerRadius: CGFloat,
        hoverPadding: CGSize
    ) -> IslandShapeSnapshot {
        let frame = CGRect(
            x: anchorX - (bodyWidth / 2),
            y: -topCurveOverflow,
            width: bodyWidth,
            height: height + topCurveOverflow
        )
        let hoverFrame = frame.insetBy(dx: -hoverPadding.width, dy: -hoverPadding.height)

        return IslandShapeSnapshot(
            frame: frame,
            visibleHeight: height,
            topAttachmentWidth: topWidth,
            topCornerRadius: topCornerRadius,
            topInnerFilletRadius: 0,
            topClipInset: topClipInset,
            topCurveOverflow: topCurveOverflow,
            shoulderDepth: shoulderDepth,
            bottomCornerRadius: bottomCornerRadius,
            hoverFrame: hoverFrame
        )
    }

    private static func makeNotchShape(
        anchorX: CGFloat,
        width: CGFloat,
        height: CGFloat,
        bottomCornerRadius: CGFloat
    ) -> IslandShapeSnapshot {
        let frame = CGRect(
            x: anchorX - (width / 2),
            y: 0,
            width: width,
            height: height
        )
        let hoverFrame = CGRect(
            x: frame.minX,
            y: frame.minY,
            width: frame.width,
            height: frame.height
        )

        return IslandShapeSnapshot(
            frame: frame,
            visibleHeight: height,
            topAttachmentWidth: width,
            topCornerRadius: 0,
            topInnerFilletRadius: 0,
            topClipInset: 0,
            topCurveOverflow: 0,
            shoulderDepth: 0,
            bottomCornerRadius: bottomCornerRadius,
            hoverFrame: hoverFrame
        )
    }
}
