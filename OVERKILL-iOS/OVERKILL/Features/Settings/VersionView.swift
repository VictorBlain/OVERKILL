import SwiftUI

struct VersionView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Version badge
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("v1.0")
                            .font(.system(size: 52, weight: .black, design: .monospaced))
                            .foregroundStyle(Theme.electric)
                            .electricGlow(radius: 20)

                        Text("Operation Phoenix")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.muted)
                            .kerning(2)
                    }
                    Spacer()
                }
                .padding(.top, 8)

                // Build info
                VStack(alignment: .leading, spacing: 12) {
                    Text("BUILD INFORMATION")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.muted)

                    VStack(spacing: 0) {
                        VersionRow(label: "Application", value: "OVERKILL")
                        VersionRow(label: "Version",     value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        VersionRow(label: "Build",       value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        VersionRow(label: "Bundle ID",   value: Bundle.main.bundleIdentifier ?? "com.vihaanvaghela.overkill")
                        VersionRow(label: "Min iOS",     value: "17.0")
                        VersionRow(label: "Branch",      value: "feature/project-phoenix")
                        VersionRow(label: "Engine",      value: "Operation Phoenix")
                        VersionRow(label: "Build Date",  value: buildDate)
                    }
                    .glassCard()
                }

                // Changelog
                VStack(alignment: .leading, spacing: 12) {
                    Text("CHANGELOG — v1.0")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.muted)

                    VStack(alignment: .leading, spacing: 10) {
                        ChangeEntry(emoji: "🚀", text: "Full SwiftUI migration from React Native (Operation Phoenix)")
                        ChangeEntry(emoji: "📐", text: "High-performance Canvas-based graphing engine with pan/zoom/glow effects")
                        ChangeEntry(emoji: "∫",  text: "Symbolic derivative, numerical integral, Taylor series, root finder, limit evaluator")
                        ChangeEntry(emoji: "⬛", text: "Matrix engine: det, inv, transpose, multiply, eigenvalues, LU decomposition")
                        ChangeEntry(emoji: "📊", text: "Statistics: descriptive stats, regression, histograms (Swift Charts)")
                        ChangeEntry(emoji: "🧠", text: "Hyperion Math Edition — offline AI math guide with 18 curated topics")
                        ChangeEntry(emoji: "🎓", text: "Interactive 7-page onboarding tutorial with replay from Settings")
                        ChangeEntry(emoji: "⚙️", text: "Settings: color scheme, accessibility, version info, about, credits")
                        ChangeEntry(emoji: "🌑", text: "Dark mode first design, Apple HIG throughout, SF Symbols, Dynamic Type")
                    }
                    .padding(16)
                    .glassCard()
                }

                // Future roadmap
                VStack(alignment: .leading, spacing: 12) {
                    Text("ROADMAP — v1.1 +")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.muted)

                    VStack(alignment: .leading, spacing: 10) {
                        ChangeEntry(emoji: "🧊", text: "3D surface graphing with Metal acceleration")
                        ChangeEntry(emoji: "🔵", text: "Polar and parametric plot modes")
                        ChangeEntry(emoji: "🧮", text: "Complex number visualisation (Argand plane)")
                        ChangeEntry(emoji: "📱", text: "iCloud sync for saved functions and history")
                        ChangeEntry(emoji: "🎨", text: "Custom colour themes and graph styles")
                        ChangeEntry(emoji: "⚛️", text: "Physics simulation engine")
                        ChangeEntry(emoji: "📒", text: "Mathematical notebooks (LaTeX rendering)")
                        ChangeEntry(emoji: "🤖", text: "Enhanced Hyperion with on-device ML (iOS 18 Core ML)")
                    }
                    .padding(16)
                    .glassCard()
                }

                Spacer(minLength: 40)
            }
            .padding(20)
        }
        .background(.black)
        .navigationTitle("Version")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var buildDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: Date())
    }
}

private struct VersionRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Theme.muted)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.foreground)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Divider().background(Theme.border.opacity(0.5))
        }
    }
}

private struct ChangeEntry: View {
    let emoji: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(emoji).font(.system(size: 14))
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Theme.muted)
                .lineSpacing(2)
        }
    }
}
