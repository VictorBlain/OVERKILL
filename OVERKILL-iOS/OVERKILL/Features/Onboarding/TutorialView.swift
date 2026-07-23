import SwiftUI

private struct TutorialPage: Identifiable {
    let id: Int
    let icon: String
    let iconColor: Color
    let title: String
    let body: String
    let gesture: String?
}

private let pages: [TutorialPage] = [
    TutorialPage(id: 0, icon: "waveform.path.ecg", iconColor: Theme.electric,
                 title: "Graph Anything",
                 body: "OVERKILL can plot any mathematical function of x.\n\nType expressions like:\n  sin(x), x^2, e^x, log(x)\n\nAdd multiple functions at once — each gets its own color.",
                 gesture: nil),
    TutorialPage(id: 1, icon: "hand.draw.fill", iconColor: Theme.mint,
                 title: "Pan & Zoom",
                 body: "Navigate the graph with two gestures:\n\n• Drag to pan in any direction\n• Pinch to zoom in or out\n\nThe graph is infinite — explore as far as you like.",
                 gesture: "pinch"),
    TutorialPage(id: 2, icon: "arrow.counterclockwise", iconColor: Theme.amber,
                 title: "Reset the View",
                 body: "Lost your way? Tap the reset button (↺) in the top-right corner of the graph to return to the default view instantly.\n\nDouble-tap anywhere on the canvas also resets.",
                 gesture: nil),
    TutorialPage(id: 3, icon: "function", iconColor: Theme.rose,
                 title: "Calculus Suite",
                 body: "The Calculus tab gives you:\n\n• Symbolic derivatives (d/dx)\n• Numerical integrals (∫)\n• Taylor / Maclaurin series\n• Numerical root finding\n• Limit evaluation as x → 0",
                 gesture: nil),
    TutorialPage(id: 4, icon: "square.grid.3x3.fill", iconColor: Theme.violet,
                 title: "Matrix Engine",
                 body: "The Matrix tab handles:\n\n• 2×2, 3×3, and 4×4 matrices\n• Determinant, inverse, transpose\n• Matrix multiplication\n• Eigenvalues\n• LU decomposition\n\nTap Identity or Random to fill quickly.",
                 gesture: nil),
    TutorialPage(id: 5, icon: "brain.head.profile", iconColor: Theme.sky,
                 title: "Hyperion Math",
                 body: "Hyperion is your offline math guide.\n\nAsk it anything:\n  'What is a derivative?'\n  'How do logarithms work?'\n  'What is the quadratic formula?'\n\nNo internet. No API key. Pure knowledge.",
                 gesture: nil),
    TutorialPage(id: 6, icon: "star.fill", iconColor: Theme.amber,
                 title: "You're Ready",
                 body: "OVERKILL is designed to be the most capable graphing calculator a student could build and ship.\n\nExplore. Compute. Learn.\n\nFrom the Settings tab you can replay this tutorial anytime.",
                 gesture: nil),
]

struct TutorialView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            RadialGradient(
                colors: [pages[currentPage].iconColor.opacity(0.12), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 350
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 6) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Theme.electric : Theme.surface3)
                            .frame(width: i == currentPage ? 24 : 6, height: 6)
                            .animation(.spring(response: 0.4), value: currentPage)
                    }
                }
                .padding(.top, 60)

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages) { page in
                        PageContent(page: page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentPage)

                Spacer()

                // Navigation
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button {
                            withAnimation { currentPage -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.muted)
                                .frame(width: 50, height: 50)
                                .background(Theme.surface2)
                                .clipShape(Circle())
                        }
                    }

                    Spacer()

                    if currentPage < pages.count - 1 {
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            HStack(spacing: 6) {
                                Text("Next")
                                    .font(.system(size: 16, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(Theme.electric)
                            .clipShape(Capsule())
                        }
                    } else {
                        Button {
                            onComplete()
                        } label: {
                            HStack(spacing: 6) {
                                Text("Let's Go")
                                    .font(.system(size: 16, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(Theme.electric)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 50)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { v in
                    if v.translation.width < -30, currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else if v.translation.width > 30, currentPage > 0 {
                        withAnimation { currentPage -= 1 }
                    }
                }
        )
    }
}

private struct PageContent: View {
    let page: TutorialPage

    var body: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.1))
                    .frame(width: 110, height: 110)
                Circle()
                    .strokeBorder(page.iconColor.opacity(0.25), lineWidth: 1)
                    .frame(width: 110, height: 110)
                Image(systemName: page.icon)
                    .font(.system(size: 44, weight: .thin))
                    .foregroundStyle(page.iconColor)
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.foreground)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .frame(maxWidth: 340)
            }
        }
        .padding(.horizontal, 28)
    }
}
