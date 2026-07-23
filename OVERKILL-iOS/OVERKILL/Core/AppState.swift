import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    // MARK: - Onboarding
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    // MARK: - Appearance
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = "dark"

    var colorScheme: ColorScheme? {
        switch appearanceModeRaw {
        case "dark":  return .dark
        case "light": return .light
        default:      return nil   // system
        }
    }

    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .dark }
        set { appearanceModeRaw = newValue.rawValue }
    }

    // MARK: - Accessibility
    @AppStorage("largeText") var largeText: Bool = false
    @AppStorage("highContrast") var highContrast: Bool = false
    @AppStorage("reduceMotion") var reduceMotion: Bool = false

    // MARK: - Graph functions
    @Published var graphFunctions: [GraphFunction] = [
        GraphFunction(expression: "x^2", color: Theme.functionColors[0]),
    ]

    func addFunction(_ expr: String) {
        let color = Theme.functionColors[graphFunctions.count % Theme.functionColors.count]
        graphFunctions.append(GraphFunction(expression: expr, color: color))
    }

    func removeFunction(id: UUID) {
        graphFunctions.removeAll { $0.id == id }
    }

    func toggleFunction(id: UUID) {
        if let idx = graphFunctions.firstIndex(where: { $0.id == id }) {
            graphFunctions[idx].isVisible.toggle()
        }
    }

    func updateFunction(id: UUID, expression: String) {
        if let idx = graphFunctions.firstIndex(where: { $0.id == id }) {
            graphFunctions[idx].expression = expression
        }
    }

    // MARK: - History
    @Published private(set) var calculationHistory: [HistoryEntry] = []

    func addHistory(_ entry: HistoryEntry) {
        calculationHistory.insert(entry, at: 0)
        if calculationHistory.count > 50 { calculationHistory.removeLast() }
    }

    // MARK: - Tutorial replay
    func resetTutorial() {
        hasCompletedOnboarding = false
    }
}

// MARK: - Supporting types

enum AppearanceMode: String, CaseIterable {
    case dark   = "dark"
    case light  = "light"
    case system = "system"

    var label: String {
        switch self {
        case .dark:   return "Dark"
        case .light:  return "Light"
        case .system: return "System"
        }
    }
}

struct HistoryEntry: Identifiable {
    let id   = UUID()
    let date = Date()
    let input: String
    let operation: String
    let result: String
}
