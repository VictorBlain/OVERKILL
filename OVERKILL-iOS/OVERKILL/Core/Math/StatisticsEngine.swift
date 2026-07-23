import Foundation

struct StatisticsEngine {

    struct Stats {
        let count:    Int
        let mean:     Double
        let median:   Double
        let mode:     [Double]
        let std:      Double
        let variance: Double
        let min:      Double
        let max:      Double
        let range:    Double
        let q1:       Double
        let q3:       Double
        let iqr:      Double
        let skewness: Double
        let kurtosis: Double
    }

    static func compute(data: [Double]) -> Stats? {
        let sorted = data.sorted()
        let n = sorted.count
        guard n > 0 else { return nil }

        let sum = sorted.reduce(0, +)
        let mean = sum / Double(n)

        // median
        let median: Double
        if n % 2 == 0 { median = (sorted[n/2 - 1] + sorted[n/2]) / 2 }
        else           { median = sorted[n/2] }

        // variance / std
        let variance = sorted.map { pow($0 - mean, 2) }.reduce(0, +) / Double(n)
        let std = sqrt(variance)

        // mode
        var freq: [Double: Int] = [:]
        sorted.forEach { freq[$0, default: 0] += 1 }
        let maxFreq = freq.values.max() ?? 0
        let mode = freq.filter { $0.value == maxFreq }.keys.sorted()

        // quartiles
        let q1 = percentile(sorted: sorted, p: 0.25)
        let q3 = percentile(sorted: sorted, p: 0.75)

        // skewness (Fisher)
        let skewness: Double
        if std > 0 {
            skewness = sorted.map { pow(($0 - mean) / std, 3) }.reduce(0, +) / Double(n)
        } else { skewness = 0 }

        // excess kurtosis
        let kurtosis: Double
        if std > 0 {
            kurtosis = sorted.map { pow(($0 - mean) / std, 4) }.reduce(0, +) / Double(n) - 3
        } else { kurtosis = 0 }

        return Stats(
            count: n, mean: mean, median: median, mode: mode,
            std: std, variance: variance,
            min: sorted.first!, max: sorted.last!, range: sorted.last! - sorted.first!,
            q1: q1, q3: q3, iqr: q3 - q1,
            skewness: skewness, kurtosis: kurtosis
        )
    }

    // MARK: Linear regression
    struct LinearRegression {
        let slope:     Double
        let intercept: Double
        let r2:        Double

        func predict(_ x: Double) -> Double { slope * x + intercept }
    }

    static func linearRegression(xs: [Double], ys: [Double]) -> LinearRegression? {
        let n = Double(xs.count)
        guard xs.count == ys.count, xs.count >= 2 else { return nil }
        let sumX = xs.reduce(0, +), sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).map(*).reduce(0, +)
        let sumXX = xs.map { $0 * $0 }.reduce(0, +)
        let denom = n * sumXX - sumX * sumX
        guard abs(denom) > 1e-14 else { return nil }
        let slope = (n * sumXY - sumX * sumY) / denom
        let intercept = (sumY - slope * sumX) / n
        let meanY = sumY / n
        let ssTot = ys.map { pow($0 - meanY, 2) }.reduce(0, +)
        let ssRes = zip(ys, xs).map { ($0.0 - (slope * $0.1 + intercept)) }.map { $0 * $0 }.reduce(0, +)
        let r2 = ssTot > 0 ? 1 - ssRes / ssTot : 1
        return LinearRegression(slope: slope, intercept: intercept, r2: r2)
    }

    // MARK: Histogram bins
    static func histogram(data: [Double], bins: Int = 10) -> [(range: ClosedRange<Double>, count: Int)] {
        guard let lo = data.min(), let hi = data.max(), hi > lo else { return [] }
        let width = (hi - lo) / Double(bins)
        return (0..<bins).map { i in
            let lower = lo + Double(i) * width
            let upper = lower + width
            let range = lower...upper
            let count = data.filter { $0 >= lower && (i == bins - 1 ? $0 <= upper : $0 < upper) }.count
            return (range, count)
        }
    }

    // MARK: Parse input
    static func parse(_ text: String) -> [Double] {
        text.components(separatedBy: CharacterSet(charactersIn: ",; \n\t"))
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
    }

    // MARK: helpers
    private static func percentile(sorted data: [Double], p: Double) -> Double {
        let n = data.count
        guard n > 0 else { return 0 }
        let idx = p * Double(n - 1)
        let lo = Int(idx), hi = min(lo + 1, n - 1)
        let frac = idx - Double(lo)
        return data[lo] * (1 - frac) + data[hi] * frac
    }
}
