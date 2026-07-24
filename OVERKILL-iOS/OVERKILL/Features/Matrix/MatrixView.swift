import SwiftUI

private typealias MatSize = Int   // 2, 3, or 4

private enum MatOp: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case det         = "Determinant"
    case inv         = "Inverse"
    case transpose   = "Transpose"
    case multiply    = "A × A"
    case eigenvalues = "Eigenvalues"
    case lu          = "LU Decomp"

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
    @State private var size: MatSize = 3
    @State private var cells: [[String]] = MatrixView.makeEmpty(3)
    @State private var operation: MatOp = .det
    @State private var result: String?
    @State private var isComputing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sizeSelector
                    matrixGrid
                    operationGrid
                    computeButton
                    if let r = result {
                        resultCard(r)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
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
                        withAnimation(.easeInOut(duration: 0.2)) {
                            size = s
                            cells = MatrixView.makeEmpty(s)
                            result = nil
                        }
                    }
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(size == s ? .white : Theme.muted)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.r12, style: .continuous)
                            .fill(size == s ? Theme.electric : Theme.surface2)
                    )
                    .animation(.easeInOut(duration: 0.15), value: size)
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
        VStack(alignment: .leading, spacing: 10) {
            Text("MATRIX A")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.muted)

            // Use GeometryReader for cell sizing — no UIScreen
            GeometryReader { geo in
                let spacing: CGFloat = 8
                let totalSpacing = spacing * CGFloat(size - 1)
                let cellW = min((geo.size.width - totalSpacing) / CGFloat(size), 76)

                VStack(spacing: spacing) {
                    ForEach(0..<size, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<size, id: \.self) { col in
                                MatrixCell(
                                    text: Binding(
                                        get: { cells[row][col] },
                                        set: { cells[row][col] = $0 }
                                    ),
                                    width: cellW
                                )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: CGFloat(size) * 52 + CGFloat(size - 1) * 8)
        }
        .padding(16)
        .glassCard()
    }

    private var operationGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OPERATION")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.muted)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 8
            ) {
                ForEach(MatOp.allCases) { op in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { operation = op }
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: op.icon)
                                .font(.system(size: 15))
                            Text(op.rawValue)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .foregroundStyle(operation == op ? .white : Theme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.r12, style: .continuous)
                                .fill(operation == op ? Theme.electric : Theme.surface2)
                        )
                    }
                    .animation(.easeInOut(duration: 0.15), value: operation)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private var computeButton: some View {
        Button { compute() } label: {
            HStack(spacing: 10) {
                if isComputing {
                    ProgressView().tint(.white).scaleEffect(0.85)
                } else {
                    Image(systemName: "play.fill")
                }
                Text(isComputing ? "Computing…" : "Compute")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isComputing ? Theme.electric.opacity(0.6) : Theme.electric)
            .clipShape(RoundedRectangle(cornerRadius: Theme.r12, style: .continuous))
        }
        .disabled(isComputing)
        .animation(.easeInOut(duration: 0.15), value: isComputing)
    }

    private func resultCard(_ r: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(operation.rawValue.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.electric)
                Spacer()
                Button {
                    copyToClipboard(r)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.muted)
                }
            }

            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                Text(r)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Theme.foreground)
                    .textSelection(.enabled)
                    .padding(4)
            }
            .frame(maxHeight: 240)
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Actions

    private func fillIdentity() {
        withAnimation(.easeInOut(duration: 0.2)) {
            cells = (0..<size).map { i in (0..<size).map { j in i == j ? "1" : "0" } }
            result = nil
        }
    }

    private func fillRandom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            cells = (0..<size).map { _ in (0..<size).map { _ in "\(Int.random(in: -9...9))" } }
            result = nil
        }
    }

    private func compute() {
        isComputing = true
        let mat = cells.map { row in row.map { Double($0) ?? 0.0 } }
        let op = operation

        Task {
            let output: String = {
                switch op {
                case .det:
                    let d = MatrixEngine.determinant(mat)
                    return d.isNaN ? "Undefined" : String(format: "%.6g", d)

                case .inv:
                    guard let inv = MatrixEngine.inverse(mat) else {
                        return "Matrix is singular — not invertible"
                    }
                    return MatrixEngine.format(inv)

                case .transpose:
                    return MatrixEngine.format(MatrixEngine.transpose(mat))

                case .multiply:
                    guard let res = MatrixEngine.multiply(mat, mat) else {
                        return "Multiplication failed"
                    }
                    return MatrixEngine.format(res)

                case .eigenvalues:
                    guard let ev = MatrixEngine.eigenvalues(mat) else {
                        return "Could not compute eigenvalues\n(supported for 2×2 – 4×4)"
                    }
                    return "λ = " + ev.map { String(format: "%.4g", $0) }.joined(separator: ",  ")

                case .lu:
                    guard let (L, U, _) = MatrixEngine.luDecomposition(mat) else {
                        return "LU decomposition failed\n(matrix may be singular)"
                    }
                    return "L:\n\(MatrixEngine.format(L))\n\nU:\n\(MatrixEngine.format(U))"
                }
            }()

            await MainActor.run {
                withAnimation(.spring(response: 0.4)) { result = output }
                isComputing = false
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        // Required UIKit usage: SwiftUI has no programmatic clipboard API
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }

    // MARK: - Helpers

    static func makeEmpty(_ n: Int) -> [[String]] {
        (0..<n).map { _ in Array(repeating: "", count: n) }
    }
}

// MARK: - MatrixCell

private struct MatrixCell: View {
    @Binding var text: String
    let width: CGFloat

    var body: some View {
        TextField("0", text: $text)
            .font(.system(size: 16, weight: .medium, design: .monospaced))
            .foregroundStyle(Theme.foreground)
            .multilineTextAlignment(.center)
            .keyboardType(.numbersAndPunctuation)
            .frame(width: width, height: 48)
            .background(Theme.surface2)
            .clipShape(RoundedRectangle(cornerRadius: Theme.r8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.r8, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 0.5)
            )
    }
}
