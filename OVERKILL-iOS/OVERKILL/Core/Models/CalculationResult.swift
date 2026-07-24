import Foundation

// MARK: - CalculationOperation

/// Every operation the Calculus tab can perform.
enum CalculationOperation: String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }

    case derivative = "d/dx"
    case integral   = "∫ dx"
    case taylor     = "Taylor"
    case roots      = "Roots"
    case limit      = "Limit"

    var title: String { rawValue }

    var systemImage: String {
        switch self {
        case .derivative: return "function"
        case .integral:   return "chart.line.downtrend.xyaxis"
        case .taylor:     return "text.alignleft"
        case .roots:      return "xmark.circle"
        case .limit:      return "arrow.right.to.line"
        }
    }

    var description: String {
        switch self {
        case .derivative: return "Symbolic derivative using differentiation rules"
        case .integral:   return "Numerical definite integral  −10 to 10 (Simpson's rule)"
        case .taylor:     return "Maclaurin series expansion — order 5"
        case .roots:      return "Bisection root-finding on [−20, 20]"
        case .limit:      return "Numerical limit as x → 0"
        }
    }
}

// MARK: - CalculationResultRecord

/// A fully resolved calculation result ready for display and persistence.
struct CalculationResultRecord: Identifiable {
    let id        = UUID()
    let timestamp = Date()

    let operation: CalculationOperation
    let inputExpression: String
    let outputText: String
    let detailText: String?
    let isError: Bool

    // MARK: Display helpers

    var operationLabel: String { operation.rawValue.uppercased() }

    var formattedDate: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: timestamp)
    }

    // MARK: Factories

    static func success(
        operation: CalculationOperation,
        input: String,
        output: String,
        detail: String? = nil
    ) -> CalculationResultRecord {
        CalculationResultRecord(
            operation: operation,
            inputExpression: input,
            outputText: output,
            detailText: detail,
            isError: false
        )
    }

    static func error(
        operation: CalculationOperation,
        input: String,
        message: String
    ) -> CalculationResultRecord {
        CalculationResultRecord(
            operation: operation,
            inputExpression: input,
            outputText: message,
            detailText: nil,
            isError: true
        )
    }
}

// MARK: - MatrixOperation

/// Every operation the Matrix tab can perform.
enum MatrixOperation: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case determinant  = "Determinant"
    case inverse      = "Inverse"
    case transpose    = "Transpose"
    case multiply     = "A × A"
    case eigenvalues  = "Eigenvalues"
    case lu           = "LU Decomp"

    var systemImage: String {
        switch self {
        case .determinant: return "number"
        case .inverse:     return "arrow.2.squarepath"
        case .transpose:   return "arrow.up.right.and.arrow.down.left"
        case .multiply:    return "multiply"
        case .eigenvalues: return "waveform.path"
        case .lu:          return "square.split.2x2"
        }
    }
}

// MARK: - StatisticsResultRecord

/// Encapsulates all output from a statistics computation session.
struct StatisticsResultRecord {
    let count:      Int
    let mean:       Double
    let median:     Double
    let std:        Double
    let variance:   Double
    let min:        Double
    let max:        Double
    let range:      Double
    let q1:         Double
    let q3:         Double
    let iqr:        Double
    let skewness:   Double
    let kurtosis:   Double
    let mode:       [Double]

    let regressionSlope:     Double?
    let regressionIntercept: Double?
    let regressionR2:        Double?

    var regressionEquation: String? {
        guard let m = regressionSlope, let b = regressionIntercept else { return nil }
        let mStr = String(format: "%.4g", m)
        let bStr = String(format: "%.4g", abs(b))
        let sign = b >= 0 ? "+" : "−"
        return "y = \(mStr)x \(sign) \(bStr)"
    }
}
