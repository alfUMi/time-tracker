import SwiftUI

enum DesignTokens {
    enum Colors {
        static let canvas = Color.black
        static let surface = Color(red: 22 / 255, green: 22 / 255, blue: 22 / 255)
        static let surfaceRaised = Color(red: 32 / 255, green: 32 / 255, blue: 32 / 255)
        static let glassFill = surface
        static let glassHighlight = Color.clear
        static let border = Color.white.opacity(0.08)
        static let textPrimary = Color(red: 243 / 255, green: 245 / 255, blue: 247 / 255)
        static let textSecondary = Color(red: 156 / 255, green: 167 / 255, blue: 179 / 255)
        static let accentBlue = Color(red: 76 / 255, green: 141 / 255, blue: 1.0)
        static let accentMint = Color(red: 49 / 255, green: 196 / 255, blue: 141 / 255)
        static let accentAmber = Color(red: 245 / 255, green: 185 / 255, blue: 66 / 255)
        static let accentRed = Color(red: 240 / 255, green: 93 / 255, blue: 94 / 255)
    }

    enum Spacing {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 3
        static let medium: CGFloat = 5
        static let large: CGFloat = 7
        static let pill: CGFloat = 999
    }

    enum Shadow {
        static let soft = Color.black.opacity(0.22)
    }
}

struct GlassBackgroundView: View {
    var body: some View {
        DesignTokens.Colors.canvas
            .ignoresSafeArea()
    }
}

struct PanelCardStyle: ViewModifier {
    let padding: CGFloat

    init(padding: CGFloat = DesignTokens.Spacing.lg) {
        self.padding = padding
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.large, style: .continuous)
                    .fill(DesignTokens.Colors.glassFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.large, style: .continuous)
                            .stroke(DesignTokens.Colors.border, lineWidth: 1)
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.large, style: .continuous))
    }
}

struct GlassChipStyle: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous)
                    .fill(DesignTokens.Colors.surfaceRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous)
                            .stroke(tint.opacity(0.18), lineWidth: 1)
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous))
    }
}

struct GlassButtonStyle: ButtonStyle {
    enum Prominence {
        case primary(Color)
        case secondary(Color)
    }

    let prominence: Prominence

    func makeBody(configuration: Configuration) -> some View {
        let tint: Color = switch prominence {
        case .primary(let color), .secondary(let color):
            color
        }

        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(DesignTokens.Colors.textPrimary.opacity(configuration.isPressed ? 0.82 : 1))
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous)
                    .fill(backgroundFill(for: tint, pressed: configuration.isPressed))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous)
                            .stroke(borderColor(for: tint), lineWidth: 1)
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.medium, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }

    private func backgroundFill(for tint: Color, pressed: Bool) -> Color {
        switch prominence {
        case .primary:
            return tint.opacity(pressed ? 0.54 : 0.40)
        case .secondary:
            return DesignTokens.Colors.surfaceRaised.opacity(pressed ? 0.96 : 1)
        }
    }

    private func borderColor(for tint: Color) -> Color {
        switch prominence {
        case .primary:
            return tint.opacity(0.36)
        case .secondary:
            return DesignTokens.Colors.border
        }
    }
}

extension View {
    func panelCardStyle(padding: CGFloat = DesignTokens.Spacing.lg) -> some View {
        modifier(PanelCardStyle(padding: padding))
    }

    func glassChipStyle(tint: Color) -> some View {
        modifier(GlassChipStyle(tint: tint))
    }
}
