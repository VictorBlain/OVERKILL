import SwiftUI

struct GraphView: View {
    @EnvironmentObject var appState: AppState
    @State private var viewport = Viewport()

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Full-bleed canvas
                GraphCanvas(functions: appState.graphFunctions, viewport: $viewport)
                    .ignoresSafeArea()

                // Floating header — pinned to safe area top
                headerOverlay
                    .padding(.top, geo.safeAreaInsets.top)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FunctionPanel()
                .environmentObject(appState)
        }
        .background(.black)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Header

    private var headerOverlay: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("OVERKILL")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .kerning(3)
                        .foregroundStyle(Theme.foreground)

                    let active = appState.graphFunctions.filter(\.isVisible).count
                    let total  = appState.graphFunctions.count
                    Text("\(active) of \(total) visible")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.electric)
                }

                Spacer()

                // Viewport readout
                VStack(alignment: .trailing, spacing: 1) {
                    Text("x [\(fmt(viewport.xMin)), \(fmt(viewport.xMax))]")
                    Text("y [\(fmt(viewport.yMin)), \(fmt(viewport.yMax))]")
                }
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Theme.muted.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [.black.opacity(0.85), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }

    private func fmt(_ v: Double) -> String {
        abs(v) >= 100 ? String(format: "%.0f", v) : String(format: "%.1f", v)
    }
}
