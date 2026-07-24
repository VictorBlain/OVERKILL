import SwiftUI
import Foundation

// MARK: - Double formatting

extension Double {

    /// Format for display in result cards. Strips trailing zeros.
    var display: String {
        if isNaN       { return "NaN" }
        if isInfinite  { return self > 0 ? "∞" : "-∞" }
        let abs = Swift.abs(self)
        if self == self.rounded() && abs < 1e9 { return "\(Int(self))" }
        if abs >= 1e6 || (abs < 1e-3 && abs > 0) {
            return String(format: "%.4e", self)
        }
        return String(format: "%.6g", self)
    }

    /// Compact label format for graph axes.
    var axisLabel: String {
        let abs = Swift.abs(self)
        if self == 0 { return "0" }
        if self == self.rounded() && abs < 1e6 { return "\(Int(self))" }
        if abs >= 1e4 || abs < 0.01 { return String(format: "%.1e", self) }
        return String(format: "%.2g", self)
    }

    /// Round to a specified number of decimal places.
    func rounded(to places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }

    /// True if the value is a finite, non-NaN number.
    var isUsable: Bool { isFinite && !isNaN }
}

// MARK: - Collection utilities

extension Collection {
    /// Split a collection into chunks of a given size.
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            let start = index(self.startIndex, offsetBy: $0)
            let end   = index(start, offsetBy: Swift.min(size, distance(from: start, to: endIndex)))
            return Array(self[start..<end])
        }
    }
}

extension Array where Element == Double {
    /// Remove values beyond `n` standard deviations from the mean.
    func removingOutliers(sigmas n: Double = 3) -> [Double] {
        guard count >= 2 else { return self }
        let mean = reduce(0, +) / Double(count)
        let variance = map { pow($0 - mean, 2) }.reduce(0, +) / Double(count)
        let std = sqrt(variance)
        guard std > 0 else { return self }
        return filter { abs($0 - mean) <= n * std }
    }
}

// MARK: - String utilities

extension String {
    /// Returns the string with leading/trailing whitespace stripped.
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    /// True if the string contains only numeric characters, dots, and operators.
    var looksLikeMathExpression: Bool {
        let allowed = CharacterSet.alphanumerics
            .union(.init(charactersIn: "+-*/^().,_ "))
        return !isEmpty && unicodeScalars.allSatisfy { allowed.contains($0) }
    }
}

// MARK: - View utilities

extension View {

    /// Calls `action` once when the view first appears.
    func onFirstAppear(_ action: @escaping () -> Void) -> some View {
        modifier(FirstAppearModifier(action: action))
    }

    /// Applies a conditional modifier.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }

    /// Hidden placeholder that takes up the same space.
    func hidden(if condition: Bool) -> some View {
        opacity(condition ? 0 : 1)
    }

    /// Clips to a rounded rect with system-continuous style.
    func roundedClip(_ radius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

// MARK: - FirstAppearModifier

private struct FirstAppearModifier: ViewModifier {
    let action: () -> Void
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content.onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            action()
        }
    }
}

// MARK: - Color utilities

extension Color {
    /// Create a colour from an RGBA tuple (0–255).
    init(r: Int, g: Int, b: Int, a: Int = 255) {
        self.init(
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Math constants namespace

enum MathConstants {
    static let pi    = Double.pi
    static let e     = M_E
    static let phi   = (1 + sqrt(5.0)) / 2   // golden ratio
    static let sqrt2 = sqrt(2.0)
    static let sqrt3 = sqrt(3.0)
    static let ln2   = log(2.0)
    static let ln10  = log(10.0)

    /// Human-readable constant name for display.
    static func name(for value: Double) -> String? {
        let tol = 1e-6
        if abs(value - pi)    < tol { return "π" }
        if abs(value - e)     < tol { return "e" }
        if abs(value - phi)   < tol { return "φ" }
        if abs(value - sqrt2) < tol { return "√2" }
        if abs(value - sqrt3) < tol { return "√3" }
        return nil
    }
}

// MARK: - Binding convenience

extension Binding where Value == Bool {
    /// A binding that is always `true` (useful for sheet/overlay presence).
    static var alwaysTrue: Binding<Bool> {
        Binding(get: { true }, set: { _ in })
    }
}
