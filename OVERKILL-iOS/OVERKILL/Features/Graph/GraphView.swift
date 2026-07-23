import SwiftUI

struct GraphView: View {
    @EnvironmentObject var appState: AppState
    @State private var viewport = Viewport()

    var body: some View {
        ZStack(alignment: .top) {
            GraphCanvas(functions: appState.graphFunctions, viewport: $viewport)
                .ignoresSafeArea()

            // Header
            VStack(spacing: 0) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("OVERKILL")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .kerning(3)
                            .foregroundStyle(Theme.foreground)

                        let active = appState.graphFunctions.filter { $0.isVisible }.count
                        Text("\(active) active")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.electric)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .padding(.top, 8)
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.9), .black.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .padding(.top, safeAreaTop)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FunctionPanel()
                .environmentObject(appState)
        }
        .background(.black)
    }

    private var safeAreaTop: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.top ?? 0
    }
}
