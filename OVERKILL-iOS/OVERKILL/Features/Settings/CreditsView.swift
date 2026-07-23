import SwiftUI

struct CreditsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Developer
                VStack(alignment: .leading, spacing: 12) {
                    Text("DEVELOPER")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.muted)

                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Theme.electric.opacity(0.12))
                                .frame(width: 60, height: 60)
                            Text("VV")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundStyle(Theme.electric)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Vihaan Vaghela")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Theme.foreground)
                            Text("Engineer · Designer · Mathematician")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.muted)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .glassCard()
                }

                // Apple Frameworks
                CreditSection(title: "APPLE FRAMEWORKS USED") {
                    CreditRow(icon: "swift", iconColor: Theme.rose,      name: "Swift 5.9",         role: "Primary language")
                    CreditRow(icon: "paintbrush.fill", iconColor: Theme.electric, name: "SwiftUI",  role: "Declarative UI framework")
                    CreditRow(icon: "chart.line.uptrend.xyaxis", iconColor: Theme.mint, name: "Swift Charts", role: "Native histogram rendering")
                    CreditRow(icon: "pencil.and.outline", iconColor: Theme.amber, name: "Canvas API", role: "60fps graph rendering")
                    CreditRow(icon: "hand.raised.fill", iconColor: Theme.violet, name: "Combine",   role: "Reactive state management")
                }

                // Open Source
                CreditSection(title: "OPEN SOURCE & INSPIRATION") {
                    CreditRow(icon: "waveform", iconColor: Theme.sky,      name: "Wolfram Alpha",    role: "Mathematical reference & inspiration")
                    CreditRow(icon: "function",  iconColor: Theme.electric, name: "Desmos",           role: "Graphing UX inspiration")
                    CreditRow(icon: "apple.logo", iconColor: Theme.muted,  name: "Apple HIG",        role: "Design language & principles")
                    CreditRow(icon: "arrow.triangle.2.circlepath", iconColor: Theme.mint, name: "Linear / Arc Browser", role: "UI/UX philosophy")
                }

                // Acknowledgements
                VStack(alignment: .leading, spacing: 12) {
                    Text("ACKNOWLEDGEMENTS")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.muted)

                    Text("OVERKILL was built as a demonstration of what is possible when a student-level ambition meets production-quality engineering discipline.\n\nEvery algorithm — expression parsing, symbolic differentiation, matrix decomposition, statistical computation — was implemented from first principles in pure Swift, without external mathematical libraries.\n\nSpecial thanks to the educators, textbooks, and open-source community that made learning these algorithms possible.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.muted)
                        .lineSpacing(4)
                        .padding(16)
                        .glassCard()
                }

                // Legal
                VStack(alignment: .leading, spacing: 8) {
                    Text("LEGAL")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.muted)
                    Text("OVERKILL © \(currentYear) Vihaan Vaghela. All rights reserved.\nBuilt with Apple frameworks under standard SDK license. No third-party dependencies.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted.opacity(0.6))
                        .lineSpacing(3)
                }

                Spacer(minLength: 40)
            }
            .padding(20)
        }
        .background(.black)
        .navigationTitle("Credits")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
}

private struct CreditSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.muted)
            VStack(spacing: 0) {
                content
            }
            .glassCard()
        }
    }
}

private struct CreditRow: View {
    let icon: String
    let iconColor: Color
    let name: String
    let role: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.foreground)
                Text(role)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Divider().background(Theme.border.opacity(0.5)).padding(.leading, 62)
        }
    }
}
