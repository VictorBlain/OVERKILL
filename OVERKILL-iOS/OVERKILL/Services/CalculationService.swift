import Foundation

// MARK: - CalculationService
//
// Actor-based service that centralises all async mathematical computation.
// Wraps ExpressionEvaluator to provide consistent error handling, history
// tracking, and a clean async interface that Views can await directly.

actor CalculationService {

    // MARK: - Shared instance
    static let shared = CalculationService()
    private init() {}

    // MARK: - Computation

    /// Compute the symbolic derivative of `expression`.
    func derivative(of expression: String) async -> CalcResult<String> {
        guard !expression.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure("Expression is empty")
        }
        if let result = ExpressionEvaluator.symbolicDerivative(of: expression) {
            return .success(result)
        }
        return .failure("Could not differentiate '\(expression)'.\nCheck syntax and try again.")
    }

    /// Numerical definite integral from `a` to `b` using Simpson's rule.
    func integral(
        of expression: String,
        from a: Double = -10,
        to b: Double = 10,
        n: Int = 10_000
    ) async -> CalcResult<Double> {
        guard !expression.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure("Expression is empty")
        }
        if let value = ExpressionEvaluator.numericalIntegral(expr: expression, from: a, to: b, n: n) {
            return .success(value)
        }
        return .failure("Integral is undefined or diverges on [\(fmt(a)), \(fmt(b))]")
    }

    /// Maclaurin series expansion around x = 0 up to the specified order.
    func taylorSeries(of expression: String, order: Int = 5) async -> CalcResult<String> {
        guard !expression.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure("Expression is empty")
        }
        let series = ExpressionEvaluator.taylorSeries(expr: expression, order: order)
        return .success(series)
    }

    /// Find real roots of `expression` on the specified closed interval.
    func roots(
        of expression: String,
        interval: ClosedRange<Double> = -20.0...20.0
    ) async -> CalcResult<[Double]> {
        guard !expression.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure("Expression is empty")
        }
        let roots = ExpressionEvaluator.findRoots(expr: expression, interval: interval)
        return .success(roots)
    }

    /// Numerical limit as x approaches `a`.
    func limit(of expression: String, approaching a: Double = 0) async -> CalcResult<Double> {
        guard !expression.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure("Expression is empty")
        }
        if let value = ExpressionEvaluator.numericalLimit(expr: expression, approaching: a) {
            return .success(value)
        }
        return .failure("Limit does not exist or is indeterminate as x → \(fmt(a))")
    }

    /// Evaluate the expression at a specific x value.
    func evaluate(_ expression: String, at x: Double) async -> CalcResult<Double> {
        do {
            let value = try ExpressionEvaluator.evaluate(expression, x: x)
            return .success(value)
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    // MARK: - Batch sampling for graphing

    /// Returns sample points for plotting, suitable for direct use by GraphCanvas.
    func samplePoints(
        expression: String,
        xMin: Double,
        xMax: Double,
        count: Int = 800
    ) async -> [(x: Double, y: Double?)] {
        ExpressionEvaluator.samplePoints(expr: expression, xMin: xMin, xMax: xMax, count: count)
    }

    // MARK: - Private helpers

    private func fmt(_ v: Double) -> String {
        v == v.rounded() && abs(v) < 1e6 ? "\(Int(v))" : String(format: "%.2g", v)
    }
}

// MARK: - CalcResult

/// A type-safe result wrapper for calculation operations.
enum CalcResult<T> {
    case success(T)
    case failure(String)

    var value: T? {
        if case .success(let v) = self { return v }
        return nil
    }

    var errorMessage: String? {
        if case .failure(let msg) = self { return msg }
        return nil
    }

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    func map<U>(_ transform: (T) -> U) -> CalcResult<U> {
        switch self {
        case .success(let v): return .success(transform(v))
        case .failure(let e): return .failure(e)
        }
    }
}
