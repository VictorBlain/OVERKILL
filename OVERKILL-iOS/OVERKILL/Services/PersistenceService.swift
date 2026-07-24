import Foundation
import SwiftUI

// MARK: - PersistenceService
//
// Manages all local data persistence for OVERKILL.
// Uses UserDefaults for lightweight data (expressions, preferences, history).
// Each key is namespaced to avoid collisions.

struct PersistenceService {

    // MARK: - Keys

    private enum Key: String {
        case savedExpressions  = "overkill.savedExpressions"
        case calculationHistory = "overkill.calculationHistory"
        case lastMatrixSize    = "overkill.lastMatrixSize"
        case lastStatsData     = "overkill.lastStatsData"
        case graphDomain       = "overkill.graphDomain"
    }

    private static let defaults = UserDefaults.standard

    // MARK: - Saved Expressions

    /// Expressions the user has bookmarked for quick access.
    static var savedExpressions: [String] {
        get { defaults.stringArray(forKey: Key.savedExpressions.rawValue) ?? defaultExpressions }
        set { defaults.set(newValue, forKey: Key.savedExpressions.rawValue) }
    }

    static func saveExpression(_ expr: String) {
        var current = savedExpressions
        if !current.contains(expr) {
            current.insert(expr, at: 0)
            if current.count > 20 { current = Array(current.prefix(20)) }
            savedExpressions = current
        }
    }

    static func removeExpression(_ expr: String) {
        savedExpressions = savedExpressions.filter { $0 != expr }
    }

    // MARK: - Calculation History

    static var calculationHistory: [PersistedEntry] {
        get {
            guard let data = defaults.data(forKey: Key.calculationHistory.rawValue),
                  let decoded = try? JSONDecoder().decode([PersistedEntry].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Key.calculationHistory.rawValue)
            }
        }
    }

    static func appendHistory(_ entry: PersistedEntry) {
        var history = calculationHistory
        history.insert(entry, at: 0)
        if history.count > 50 { history = Array(history.prefix(50)) }
        calculationHistory = history
    }

    static func clearHistory() {
        defaults.removeObject(forKey: Key.calculationHistory.rawValue)
    }

    // MARK: - Matrix preferences

    static var lastMatrixSize: Int {
        get {
            let v = defaults.integer(forKey: Key.lastMatrixSize.rawValue)
            return (2...4).contains(v) ? v : 3
        }
        set { defaults.set(newValue, forKey: Key.lastMatrixSize.rawValue) }
    }

    // MARK: - Stats preferences

    static var lastStatsData: String {
        get { defaults.string(forKey: Key.lastStatsData.rawValue) ?? "4, 8, 15, 16, 23, 42" }
        set { defaults.set(newValue, forKey: Key.lastStatsData.rawValue) }
    }

    // MARK: - Graph domain

    static var graphDomain: GraphDomainPreference {
        get {
            guard let data = defaults.data(forKey: Key.graphDomain.rawValue),
                  let decoded = try? JSONDecoder().decode(GraphDomainPreference.self, from: data) else {
                return .init()
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Key.graphDomain.rawValue)
            }
        }
    }

    // MARK: - Private

    private static let defaultExpressions = [
        "x^2 + 3*x + 2",
        "sin(x)*cos(x)",
        "e^x",
        "log(x)",
        "1/(1+x^2)",
        "x^3 - x",
        "sqrt(abs(x))",
        "tan(x)",
    ]
}

// MARK: - Supporting types

struct PersistedEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let input: String
    let operation: String
    let result: String

    init(input: String, operation: String, result: String) {
        self.id        = UUID()
        self.date      = Date()
        self.input     = input
        self.operation = operation
        self.result    = result
    }
}

struct GraphDomainPreference: Codable {
    var xMin: Double = -10
    var xMax: Double =  10
    var yMin: Double = -10
    var yMax: Double =  10
}
