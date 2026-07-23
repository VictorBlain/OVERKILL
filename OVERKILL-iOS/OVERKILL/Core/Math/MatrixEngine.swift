import Foundation

// MARK: - Matrix Engine
struct MatrixEngine {

    // MARK: determinant (Gaussian elimination)
    static func determinant(_ mat: [[Double]]) -> Double {
        let n = mat.count
        guard n > 0, mat.allSatisfy({ $0.count == n }) else { return .nan }
        var A = mat
        var sign: Double = 1

        for col in 0..<n {
            // partial pivot
            guard let pivotRow = (col..<n).max(by: { abs(A[$0][col]) < abs(A[$1][col]) }) else { return 0 }
            if pivotRow != col { A.swapAt(col, pivotRow); sign = -sign }
            guard abs(A[col][col]) > 1e-14 else { return 0 }
            for row in (col+1)..<n {
                let factor = A[row][col] / A[col][col]
                for k in col..<n { A[row][k] -= factor * A[col][k] }
            }
        }
        return sign * (0..<n).map { A[$0][$0] }.reduce(1, *)
    }

    // MARK: inverse (Gauss-Jordan)
    static func inverse(_ mat: [[Double]]) -> [[Double]]? {
        let n = mat.count
        guard n > 0, mat.allSatisfy({ $0.count == n }) else { return nil }
        var A = mat
        // augment with identity
        for i in 0..<n { A[i].append(contentsOf: (0..<n).map { $0 == i ? 1.0 : 0.0 }) }

        for col in 0..<n {
            guard let pivotRow = (col..<n).max(by: { abs(A[$0][col]) < abs(A[$1][col]) }) else { return nil }
            if pivotRow != col { A.swapAt(col, pivotRow) }
            guard abs(A[col][col]) > 1e-14 else { return nil }
            let pivot = A[col][col]
            A[col] = A[col].map { $0 / pivot }
            for row in 0..<n where row != col {
                let factor = A[row][col]
                A[row] = zip(A[row], A[col]).map { $0.0 - factor * $0.1 }
            }
        }
        return A.map { Array($0[n...]) }
    }

    // MARK: transpose
    static func transpose(_ mat: [[Double]]) -> [[Double]] {
        guard let first = mat.first else { return [] }
        let rows = mat.count, cols = first.count
        return (0..<cols).map { c in (0..<rows).map { r in mat[r][c] } }
    }

    // MARK: multiply
    static func multiply(_ A: [[Double]], _ B: [[Double]]) -> [[Double]]? {
        let m = A.count, n = A.first?.count ?? 0, p = B.first?.count ?? 0
        guard n > 0, B.count == n else { return nil }
        return (0..<m).map { i in
            (0..<p).map { j in
                (0..<n).map { k in A[i][k] * B[k][j] }.reduce(0, +)
            }
        }
    }

    // MARK: eigenvalues (power iteration + deflation, real symmetric)
    static func eigenvalues(_ mat: [[Double]]) -> [Double]? {
        let n = mat.count
        guard n > 0, n <= 4 else { return nil }

        // For 2×2: use closed form
        if n == 2 {
            let a = mat[0][0], b = mat[0][1], c = mat[1][0], d = mat[1][1]
            let trace = a + d, det = a*d - b*c
            let disc = trace*trace - 4*det
            guard disc >= 0 else { return [trace/2, trace/2] } // complex
            let sq = sqrt(disc)
            return [(trace + sq) / 2, (trace - sq) / 2].sorted(by: >)
        }

        // QR iteration (Hessenberg, simplified)
        var A = mat
        let maxIter = 200
        for _ in 0..<maxIter {
            let (Q, R) = qrDecompose(A)
            A = matMul(R, Q)
        }
        return (0..<n).map { A[$0][$0] }.sorted(by: >)
    }

    // MARK: LU decomposition (Doolittle)
    static func luDecomposition(_ mat: [[Double]]) -> (L: [[Double]], U: [[Double]], P: [Int])? {
        let n = mat.count
        guard n > 0, mat.allSatisfy({ $0.count == n }) else { return nil }
        var A = mat
        var P = Array(0..<n)

        for col in 0..<n {
            guard let pivotRow = (col..<n).max(by: { abs(A[$0][col]) < abs(A[$1][col]) }),
                  abs(A[pivotRow][col]) > 1e-14 else { return nil }
            if pivotRow != col { A.swapAt(col, pivotRow); P.swapAt(col, pivotRow) }
            for row in (col+1)..<n {
                A[row][col] /= A[col][col]
                for k in (col+1)..<n { A[row][k] -= A[row][col] * A[col][k] }
            }
        }
        var L: [[Double]] = (0..<n).map { i in (0..<n).map { j in i == j ? 1 : (i > j ? A[i][j] : 0) } }
        let U: [[Double]] = (0..<n).map { i in (0..<n).map { j in j >= i ? A[i][j] : 0 } }
        return (L, U, P)
    }

    // MARK: format
    static func format(_ mat: [[Double]], decimals: Int = 4) -> String {
        mat.map { row in
            "[ " + row.map { String(format: "%.\(decimals)f", $0) }.joined(separator: "  ") + " ]"
        }.joined(separator: "\n")
    }

    // MARK: - Private helpers
    private static func qrDecompose(_ A: [[Double]]) -> (Q: [[Double]], R: [[Double]]) {
        let n = A.count
        var Q: [[Double]] = identity(n)
        var R = A

        for col in 0..<n {
            var v = (col..<n).map { R[$0][col] }
            let norm = sqrt(v.map { $0 * $0 }.reduce(0, +))
            if norm < 1e-14 { continue }
            v[0] += (v[0] >= 0 ? 1 : -1) * norm
            let vNorm = sqrt(v.map { $0 * $0 }.reduce(0, +))
            if vNorm < 1e-14 { continue }
            v = v.map { $0 / vNorm }
            // Apply Householder to R and Q
            for c in 0..<n {
                let dot = (0..<v.count).map { v[$0] * R[col + $0][c] }.reduce(0, +)
                for r in 0..<v.count { R[col + r][c] -= 2 * v[r] * dot }
            }
            for r in 0..<n {
                let dot = (0..<v.count).map { Q[r][col + $0] * v[$0] }.reduce(0, +)
                for c in 0..<v.count { Q[r][col + c] -= 2 * dot * v[c] }
            }
        }
        return (Q, R)
    }

    private static func matMul(_ A: [[Double]], _ B: [[Double]]) -> [[Double]] {
        let m = A.count, n = B.first?.count ?? 0, k = B.count
        return (0..<m).map { i in (0..<n).map { j in (0..<k).map { l in A[i][l]*B[l][j] }.reduce(0,+) } }
    }

    private static func identity(_ n: Int) -> [[Double]] {
        (0..<n).map { i in (0..<n).map { j in i == j ? 1.0 : 0.0 } }
    }
}
