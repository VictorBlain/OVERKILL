import SwiftUI

enum Theme {
    // MARK: - Brand colours
    static let electric    = Color(red: 0.039, green: 0.518, blue: 1.0)   // #0A84FF
    static let mint        = Color(red: 0.188, green: 0.820, blue: 0.345) // #30D158
    static let amber       = Color(red: 1.0,   green: 0.624, blue: 0.039) // #FF9F0A
    static let rose        = Color(red: 1.0,   green: 0.216, blue: 0.373) // #FF375F
    static let violet      = Color(red: 0.749, green: 0.353, blue: 0.949) // #BF5AF2
    static let sky         = Color(red: 0.353, green: 0.784, blue: 0.980) // #5AC8FA

    static let functionColors: [Color] = [
        electric, mint, amber, rose, violet, sky,
    ]

    // MARK: - Surface
    static let black       = Color.black
    static let surface1    = Color(white: 0.067)  // #111111
    static let surface2    = Color(white: 0.110)  // #1C1C1E
    static let surface3    = Color(white: 0.173)  // #2C2C2E
    static let border      = Color(white: 0.173)  // #2C2C2E
    static let muted       = Color(hex: "8E8E93")!
    static let foreground  = Color(white: 0.961)  // #F5F5F7

    // MARK: - Semantics
    static let destructive = Color(red: 1.0, green: 0.271, blue: 0.227)   // #FF453A

    // MARK: - Radius
    static let r8:  CGFloat = 8
    static let r12: CGFloat = 12
    static let r16: CGFloat = 16
    static let r20: CGFloat = 20

    // MARK: - Typography scale
    static let monoFont = Font.system(.body, design: .monospaced)

    // MARK: - Glow modifier helper
    static func glow(_ color: Color, radius: CGFloat = 8) -> some ViewModifier {
        GlowModifier(color: color, radius: radius)
    }
}

// MARK: - Color hex init
extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s = String(s.dropFirst()) }
        guard s.count == 6, let val = UInt64(s, radix: 16) else { return nil }
        self.init(
            red:   Double((val >> 16) & 0xFF) / 255,
            green: Double((val >>  8) & 0xFF) / 255,
            blue:  Double( val        & 0xFF) / 255
        )
    }
}

// MARK: - Glow modifier
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}

// MARK: - Glass card background
struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = Theme.r16

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.surface1)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Theme.border.opacity(0.6), lineWidth: 0.5)
                    )
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = Theme.r16) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius))
    }

    func electricGlow(radius: CGFloat = 8) -> some View {
        modifier(GlowModifier(color: Theme.electric, radius: radius))
    }
}
