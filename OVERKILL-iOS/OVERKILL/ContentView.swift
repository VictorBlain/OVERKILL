import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .graph
    @State private var showSettings = false

    var body: some View {
        TabView(selection: $selectedTab) {
            GraphView()
                .tabItem {
                    Label("Graph", systemImage: "waveform.path.ecg")
                }
                .tag(Tab.graph)

            CalculatorView()
                .tabItem {
                    Label("Calculus", systemImage: "function")
                }
                .tag(Tab.calculator)

            MatrixView()
                .tabItem {
                    Label("Matrix", systemImage: "square.grid.3x3.fill")
                }
                .tag(Tab.matrix)

            StatisticsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(Tab.stats)

            HyperionView()
                .tabItem {
                    Label("Hyperion", systemImage: "brain.head.profile")
                }
                .tag(Tab.hyperion)
        }
        .tint(Theme.electric)
        .overlay(alignment: .topTrailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.muted)
                    .padding(12)
            }
            .padding(.top, 52)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
    }

    enum Tab: Int {
        case graph, calculator, matrix, stats, hyperion
    }
}
