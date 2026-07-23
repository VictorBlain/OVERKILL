import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var showTutorial = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Background glow
            RadialGradient(
                colors: [Theme.electric.opacity(0.15), .clear],
                center: .init(x: 0.5, y: 0.3),
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo mark
                ZStack {
                    Circle()
                        .fill(Theme.electric.opacity(0.08))
                        .frame(width: 120, height: 120)
                    Circle()
                        .strokeBorder(Theme.electric.opacity(0.3), lineWidth: 1)
                        .frame(width: 120, height: 120)
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundStyle(Theme.electric)
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 40)

                // Title
                VStack(spacing: 8) {
                    Text("OVERKILL")
                        .font(.system(size: 40, weight: .black, design: .monospaced))
                        .kerning(6)
                        .foregroundStyle(Theme.foreground)

                    Text("The Ultimate Graphing Calculator")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                }
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 60)

                // Feature highlights
                VStack(spacing: 16) {
                    FeatureRow(icon: "waveform.path.ecg",  color: Theme.electric, title: "Graphing Engine",    desc: "Plot any function with pan & pinch zoom")
                    FeatureRow(icon: "function",           color: Theme.mint,     title: "Calculus Suite",     desc: "Derivatives, integrals, Taylor series, roots")
                    FeatureRow(icon: "square.grid.3x3",    color: Theme.amber,    title: "Matrix Engine",      desc: "Determinant, inverse, eigenvalues, LU")
                    FeatureRow(icon: "chart.bar.fill",     color: Theme.rose,     title: "Statistics",         desc: "Descriptive stats, regression, histograms")
                    FeatureRow(icon: "brain.head.profile", color: Theme.violet,   title: "Hyperion Math",      desc: "Offline AI guide — no internet required")
                }
                .padding(.horizontal, 24)
                .offset(y: appeared ? 0 : 30)
                .opacity(appeared ? 1 : 0)

                Spacer()

                // CTA
                VStack(spacing: 14) {
                    Button {
                        showTutorial = true
                    } label: {
                        HStack {
                            Text("Take the Tour")
                                .font(.system(size: 16, weight: .semibold))
                            Image(systemName: "arrow.right")
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.electric)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.r16, style: .continuous))
                    }

                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Skip — Take me to the calculator")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.muted)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
        }
        .fullScreenCover(isPresented: $showTutorial) {
            TutorialView(onComplete: completeOnboarding)
                .environmentObject(appState)
        }
    }

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.4)) {
            appState.hasCompletedOnboarding = true
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.foreground)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
            }

            Spacer()
        }
    }
}
