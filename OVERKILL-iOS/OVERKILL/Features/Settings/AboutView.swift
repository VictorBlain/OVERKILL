import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Hero
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Theme.electric.opacity(0.08)).frame(width: 80, height: 80)
                            Circle().strokeBorder(Theme.electric.opacity(0.25), lineWidth: 1).frame(width: 80, height: 80)
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 32, weight: .thin))
                                .foregroundStyle(Theme.electric)
                        }
                        Text("OVERKILL")
                            .font(.system(size: 22, weight: .black, design: .monospaced))
                            .kerning(4)
                            .foregroundStyle(Theme.foreground)
                        Text("The Ultimate Graphing Calculator")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.muted)
                    }
                    Spacer()
                }
                .padding(.top, 8)

                // Overview
                InfoSection(title: "OVERVIEW") {
                    Text("OVERKILL is a production-grade graphing calculator built entirely in SwiftUI. It brings together a high-performance 2D graphing engine, symbolic calculus, linear algebra, statistics, and an offline mathematical knowledge assistant into a single, cohesive iOS application.\n\nDesigned to demonstrate what a motivated student can ship to the App Store.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.muted)
                        .lineSpacing(4)
                }

                // Philosophy
                InfoSection(title: "ENGINEERING PHILOSOPHY") {
                    VStack(alignment: .leading, spacing: 10) {
                        PhilosophyRow(icon: "paintbrush.pointed", text: "Apple HIG first — native spacing, materials, and motion")
                        PhilosophyRow(icon: "bolt.fill",          text: "Performance over convenience — Canvas API for smooth 60fps rendering")
                        PhilosophyRow(icon: "square.stack.3d.up", text: "Modular architecture — each feature is an isolated SwiftUI module")
                        PhilosophyRow(icon: "lock.fill",          text: "No external dependencies — pure Swift, pure Apple frameworks")
                        PhilosophyRow(icon: "wifi.slash",         text: "Offline first — every calculation runs locally on device")
                    }
                }

                // Stack
                InfoSection(title: "TECHNOLOGY STACK") {
                    VStack(alignment: .leading, spacing: 8) {
                        StackRow(label: "Language",   value: "Swift 5.9+")
                        StackRow(label: "UI",         value: "SwiftUI")
                        StackRow(label: "Charts",     value: "Swift Charts (histogram)")
                        StackRow(label: "Drawing",    value: "Canvas API (graph rendering)")
                        StackRow(label: "Storage",    value: "UserDefaults / AppStorage")
                        StackRow(label: "Math",       value: "Custom expression evaluator")
                        StackRow(label: "Min Target", value: "iOS 17.0")
                    }
                }

                // Repository
                InfoSection(title: "REPOSITORY") {
                    VStack(alignment: .leading, spacing: 8) {
                        StackRow(label: "Remote", value: "github.com/VictorBlain/OVERKILL")
                        StackRow(label: "Branch", value: "feature/project-phoenix")
                        StackRow(label: "Engine", value: "Operation Phoenix")
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(20)
        }
        .background(.black)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.muted)
            content
        }
        .padding(16)
        .glassCard()
    }
}

private struct PhilosophyRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Theme.electric)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Theme.muted)
        }
    }
}

private struct StackRow: View {
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
        }
    }
}
