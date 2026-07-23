import SwiftUI

private enum Operation: String, CaseIterable {
    case derivative = "d/dx"
    case integral   = "∫ dx"
    case taylor     = "Taylor"
    case roots      = "Roots"
    case limit      = "Limit"

    var icon: String {
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
        case .integral:   return "Numerical definite integral from −10 to 10"
        case .taylor:     return "Maclaurin series expansion (order 5)"
        case .roots:      return "Numerical root finding on [−20, 20]"
        case .limit:      return "Numerical limit as x → 0"
        }
    }
}

private struct ResultCard {
    let operation: Operation
    let input: String
    let output: String
    let detail: String?
}

struct CalculatorView: View {
    @EnvironmentObject var appState: AppState
    @State private var expression = "x^3 - 3*x"
    @State private var selectedOp: Operation = .derivative
    @State private var result: ResultCard? = nil
    @State private var isComputing = false
    @State private var errorMsg: String? = nil
    @FocusState private var focused: Bool

    private let quickExprs = [
        "x^2 + 3*x + 2", "sin(x)*cos(x)", "e^x", "log(x)", "1/(1+x^2)", "x^3 - x"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    expressionCard
                    operationGrid
                    computeButton
                    if let r = result { resultCard(r) }
                    if let e = errorMsg { errorCard(e) }
                    Spacer(minLength: 40)
                }
                .padding(16)
            }
            .background(.black)
            .navigationTitle("Calculus")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Subviews

    private var expressionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Expression", systemImage: "f.cursive")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.muted)

            TextField("Enter f(x) …", text: $expression)
                .font(.system(size: 18, design: .monospaced))
                .foregroundStyle(Theme.foreground)
                .focused($focused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(12)
                .background(Theme.surface2)
                .clipShape(RoundedRectangle(cornerRadius: Theme.r12, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickExprs, id: \.self) { expr in
                        Button(expr) {
                            expression = expr
                            focused = false
                        }
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.muted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.surface2)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private var operationGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OPERATION")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.muted)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Operation.allCases, id: \.self) { op in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { selectedOp = op }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: op.icon)
                                .font(.system(size: 16))
                            Text(op.rawValue)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                        }
                        .foregroundStyle(selectedOp == op ? .white : Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.r12, style: .continuous)
                                .fill(selectedOp == op ? Theme.electric : Theme.surface2)
                        )
                    }
                    .animation(.easeInOut(duration: 0.15), value: selectedOp)
                }
            }

            Text(selectedOp.description)
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .padding(.top, 2)
        }
        .padding(16)
        .glassCard()
    }

    private var computeButton: some View {
        Button {
            compute()
        } label: {
            HStack {
                if isComputing {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "play.fill")
                }
                Text(isComputing ? "Computing…" : "Compute")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.electric)
            .clipShape(RoundedRectangle(cornerRadius: Theme.r12, style: .continuous))
        }
        .disabled(isComputing || expression.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private func resultCard(_ r: ResultCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(r.operation.rawValue.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.electric)
                Spacer()
                Button {
                    UIPasteboard.general.string = r.output
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.muted)
                }
            }

            Text("f(x) = \(r.input)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.muted)

            Text(r.output)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.foreground)
                .textSelection(.enabled)

            if let d = r.detail {
                Text(d)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .glassCard()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func errorCard(_ msg: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.destructive)
            Text(msg)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(Theme.foreground)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.destructive.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: Theme.r12, style: .continuous))
    }

    // MARK: - Compute
    private func compute() {
        let expr = expression.trimmingCharacters(in: .whitespaces)
        guard !expr.isEmpty else { return }
        focused = false
        isComputing = true
        errorMsg = nil

        Task {
            await MainActor.run {
                withAnimation(.spring(response: 0.4)) {
                    result = buildResult(expr: expr, op: selectedOp)
                }
                isComputing = false
            }
        }
    }

    private func buildResult(expr: String, op: Operation) -> ResultCard {
        switch op {
        case .derivative:
            let output = ExpressionEvaluator.symbolicDerivative(of: expr) ?? "Could not differentiate"
            return ResultCard(operation: op, input: expr, output: output, detail: "d/dx[\(expr)] = \(output)")

        case .integral:
            if let v = ExpressionEvaluator.numericalIntegral(expr: expr) {
                return ResultCard(operation: op, input: expr, output: String(format: "≈ %.6f", v),
                                  detail: "∫₋₁₀¹⁰ \(expr) dx  [Simpson's rule, n=10000]")
            }
            return ResultCard(operation: op, input: expr, output: "Undefined", detail: nil)

        case .taylor:
            let series = ExpressionEvaluator.taylorSeries(expr: expr)
            return ResultCard(operation: op, input: expr, output: series, detail: "Maclaurin series (order 5)")

        case .roots:
            let roots = ExpressionEvaluator.findRoots(expr: expr)
            let output = roots.isEmpty ? "No real roots found" : roots.map { String(format: "%.6f", $0) }.joined(separator: ", ")
            return ResultCard(operation: op, input: expr, output: output, detail: roots.isEmpty ? nil : "\(roots.count) root(s) on [−20, 20]")

        case .limit:
            if let v = ExpressionEvaluator.numericalLimit(expr: expr) {
                return ResultCard(operation: op, input: expr, output: String(format: "≈ %.8f", v), detail: "lim(x→0) \(expr)")
            }
            return ResultCard(operation: op, input: expr, output: "Undefined / DNE", detail: nil)
        }
    }
}
