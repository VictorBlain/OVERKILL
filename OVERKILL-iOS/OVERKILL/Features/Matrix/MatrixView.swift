import SwiftUI

private typealias Size = Int   // 2, 3, or 4

private enum MatOp: String, CaseIterable {
    case det        = "Determinant"
    case inv        = "Inverse"
    case transpose  = "Transpose"
    case multiply   = "A × A"
    case eigenvalues = "Eigenvalues"
    case lu         = "LU Decomp"

    var icon: String {
        switch self {
        case .det:         return "number"
        case .inv:         return "arrow.2.squarepath"
        case .transpose:   return "arrow.up.right.and.arrow.down.left"
        case .multiply:    return "multiply"
        case .eigenvalues: return "waveform.path"
        case .lu:          return "square.split.2x2"
        }
    }
}

struct MatrixView: View {
    @State private var size: Size = 3
    @State private var cells: [[String]] = Self.makeEmpty(3)
    @State private var operation: MatOp = .det
    @State private var result: String? = nil
    @State private var isComputing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sizeSelector
                    matrixGrid
                    operationGrid
                    computeButton
                    if let r = result { resultCard(r) }
                    Spacer(minLength: 40)
                }
                .padding(16)
            }
            .background(.black)
            .navigationTitle("Matrix")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Subviews

    private var sizeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MATRIX SIZE")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.muted)

            HStack(spacing: 8) {
                ForEach([2, 3, 4], id: \.self) { s in
                    Button("\(s)×\(s)") {
                        size = s
                        cells = Self.makeEmpty(s)
                        result = nil
                    }
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(size == s ? .white : Theme.muted)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.r12, style: .continuous)
                            .fill(size == s ? Theme.electric : Theme.surface2)
                    )
                }

                Spacer()

                Button("Identity") { fillIdentity() }
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.electric)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.electric.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.r8, style: .continuous))

                Button("Random") { fillRandom() }
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.mint)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.mint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.r8, style: .continuous))
            }
        }
        .padding(16)
        .glassCard()
    }

    private var matrixGrid: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("MATRIX A")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(0..<size, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<size, id: \.self) { col in
                        TextField("0", text: Binding(
                            get: { cells[row][col] },
                            set: { cells[row][col] = $0 }
                        ))
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.foreground)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numbersAndPunctuation)
                        .frame(width: cellWidth, height: cellWidth)
                        .background(Theme.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.r8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.r8, style: .continuous)
                                .strokeBorder(Theme.border, lineWidth: 0.5)
                        )
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private var cellWidth: CGFloat {
        let available = UIScreen.main.bounds.width - 32 - 32 - CGFloat(size - 1) * 8
        return min(available / CGFloat(size), 72)
    }

    private var operationGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OPERATION")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.muted)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(MatOp.allCases, id: \.self) { op in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { operation = op }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: op.icon)
                                .font(.system(size: 15))
                            Text(op.rawValue)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .multilineTextAlignment(.center)
                        }
                        .foregroundStyle(operation == op ? .white : Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.r12, style: .continuous)
                                .fill(operation == op ? Theme.electric : Theme.surface2)
                        )
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private var computeButton: some View {
        Button { compute() } label: {
            HStack {
                if isComputing { ProgressView().tint(.white) }
                else { Image(systemName: "play.fill") }
                Text(isComputing ? "Computing…" : "Compute")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.electric)
            .clipShape(RoundedRectangle(cornerRadius: Theme.r12, style: .continuous))
        }
        .disabled(isComputing)
    }

    private func resultCard(_ r: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(operation.rawValue.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.electric)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(r)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(Theme.foreground)
                    .textSelection(.enabled)
            }
        }
        .padding(16)
        .glassCard()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    private func fillIdentity() {
        cells = (0..<size).map { i in (0..<size).map { j in i == j ? "1" : "0" } }
    }

    private func fillRandom() {
        cells = (0..<size).map { _ in (0..<size).map { _ in "\(Int.random(in: -9...9))" } }
    }

    private func compute() {
        isComputing = true
        let mat = cells.map { row in row.map { Double($0) ?? 0 } }
        let op = operation

        Task {
            let output: String = {
                switch op {
                case .det:
                    let d = MatrixEngine.determinant(mat)
                    return d.isNaN ? "Undefined" : String(format: "%.6f", d)
                case .inv:
                    if let inv = MatrixEngine.inverse(mat) { return MatrixEngine.format(inv) }
                    return "Matrix is singular (not invertible)"
                case .transpose:
                    return MatrixEngine.format(MatrixEngine.transpose(mat))
                case .multiply:
                    if let res = MatrixEngine.multiply(mat, mat) { return MatrixEngine.format(res) }
                    return "Multiplication failed"
                case .eigenvalues:
                    if let ev = MatrixEngine.eigenvalues(mat) {
                        return "λ = " + ev.map { String(format: "%.4f", $0) }.joined(separator: ", ")
                    }
                    return "Could not compute (try 2×2 or 3×3)"
                case .lu:
                    if let (L, U, _) = MatrixEngine.luDecomposition(mat) {
                        return "L:\n\(MatrixEngine.format(L))\n\nU:\n\(MatrixEngine.format(U))"
                    }
                    return "LU decomposition failed"
                }
            }()

            await MainActor.run {
                withAnimation(.spring(response: 0.4)) { result = output }
                isComputing = false
            }
        }
    }

    static func makeEmpty(_ n: Int) -> [[String]] {
        (0..<n).map { _ in Array(repeating: "", count: n) }
    }
}
