import SwiftUI

enum DesignSystem {
    enum Spacing {
        static let xs: CGFloat = 6
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Metrics {
        static let cardCornerRadius: CGFloat = 18
        static let controlCornerRadius: CGFloat = 14
        static let cardPadding: CGFloat = 16
        static let hairline: CGFloat = 1 / UIScreen.main.scale
    }

    enum Shadow {
        static let cardRadius: CGFloat = 14
        static let cardY: CGFloat = 10
        static let cardOpacity: Double = 0.12
    }

    enum Colors {
        // Brand
        static let brandOrange = Color(hex: 0xFF8500)

        // Dark-first palette
        static let backgroundTop = Color(hex: 0x090A0C)
        static let backgroundBottom = Color(hex: 0x0F1115)
        static let cardFill = Color(hex: 0x141821)
        static let cardStroke = Color(hex: 0x2A3140, alpha: 0.70)
        static let controlFill = Color(hex: 0x0E1117)
        static let secondaryText = Color(hex: 0xA7B0C0)
    }

    static let maxContentWidth: CGFloat = 680

    static let gradientBackground = LinearGradient(
        colors: [Colors.backgroundTop, Colors.backgroundBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.95), Color.accentColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Metrics.controlCornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 10, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Metrics.controlCornerRadius, style: .continuous)
                    .stroke(DesignSystem.Colors.cardStroke, lineWidth: DesignSystem.Metrics.hairline)
            )
            .foregroundStyle(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Metrics.controlCornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}

struct SectionHeaderView: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(DesignSystem.Metrics.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Metrics.cardCornerRadius, style: .continuous)
                    .fill(DesignSystem.Colors.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Metrics.cardCornerRadius, style: .continuous)
                    .stroke(DesignSystem.Colors.cardStroke, lineWidth: DesignSystem.Metrics.hairline)
            )
            .shadow(
                color: Color.black.opacity(DesignSystem.Shadow.cardOpacity),
                radius: DesignSystem.Shadow.cardRadius,
                y: DesignSystem.Shadow.cardY
            )
    }
}

struct IconBadge: View {
    let systemName: String
    var color: Color = .accentColor

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.14))
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: 34, height: 34)
        .accessibilityHidden(true)
    }
}

struct DSField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Metrics.controlCornerRadius, style: .continuous)
                    .fill(DesignSystem.Colors.controlFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Metrics.controlCornerRadius, style: .continuous)
                    .stroke(DesignSystem.Colors.cardStroke, lineWidth: DesignSystem.Metrics.hairline)
            )
    }
}

extension View {
    func dsFieldStyle() -> some View {
        modifier(DSField())
    }
}
