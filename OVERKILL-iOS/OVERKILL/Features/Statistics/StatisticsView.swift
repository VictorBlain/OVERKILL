import SwiftUI
import Charts

struct StatisticsView: View {
    @State private var inputText = "4, 8, 15, 16, 23, 42, 7, 3, 11, 19, 25, 6"
    @State private var stats: StatisticsEngine.Stats? = nil
    @State private var histData: [(range: ClosedRange<Double>, count: Int)] = []
    @State private var isComputing = false
    @FocusState private var focused: Bool

    private let samples = [
        "4, 8, 15, 16, 23, 42, 7, 3, 11, 19, 25, 6",
        "1, 2, 3, 4, 5, 6, 7, 8, 9, 10",
        "100, 95, 87, 92, 88, 79, 84, 91, 96, 73",
        "2.5, 3.1, 4.2, 1.8, 5.5, 3.7, 2.9, 4.4",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    inputCard
                    if let s = stats {
                        if !histData.isEmpty { histogramCard }
                        statsCard(s)
                        regressionCard(s)
                    }
                    Spacer(minLength: 40)
                }
                .padding(16)
            }
            .background(.black)
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Subviews

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Data Set", systemImage: "number.square")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.muted)

            TextField("Enter numbers separated by commas…", text: $inputText, axis: .vertical)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(Theme.foreground)
                .lineLimit(3...5)
                .focused($focused)
                .autocorrectionDisabled()
                .padding(12)
                .background(Theme.surface2)
                .clipShape(RoundedRectangle(cornerRadius: Theme.r12, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(samples, id: \.self) { s in
                        Button(String(s.prefix(20)) + "…") {
                            inputText = s; focused = false
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Theme.muted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.surface2)
                        .clipShape(Capsule())
                    }
                }
            }

            Button { compute() } label: {
                HStack {
                    if isComputing { ProgressView().tint(.white) }
                    else { Image(systemName: "chart.bar.fill") }
                    Text(isComputing ? "Analyzing…" : "Analyze")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Theme.electric)
                .clipShape(RoundedRectangle(cornerRadius: Theme.r12, style: .continuous))
            }
            .disabled(isComputing)
        }
        .padding(16)
        .glassCard()
    }

    @ViewBuilder
    private var histogramCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DISTRIBUTION")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.muted)

            Chart {
                ForEach(histData.indices, id: \.self) { i in
                    let bin = histData[i]
                    BarMark(
                        x: .value("Range", "\(String(format: "%.1f", bin.range.lowerBound))"),
                        y: .value("Count", bin.count)
                    )
                    .foregroundStyle(Theme.electric.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { v in
                    AxisValueLabel()
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Theme.muted)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { v in
                    AxisValueLabel()
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Theme.muted)
                    AxisGridLine().foregroundStyle(Theme.border)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private func statsCard(_ s: StatisticsEngine.Stats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DESCRIPTIVE STATISTICS  (\(s.count) values)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.muted)

            let rows: [(String, String)] = [
                ("Mean",       fmt(s.mean)),
                ("Median",     fmt(s.median)),
                ("Mode",       s.mode.map(fmt).joined(separator: ", ")),
                ("Std Dev",    fmt(s.std)),
                ("Variance",   fmt(s.variance)),
                ("Min",        fmt(s.min)),
                ("Max",        fmt(s.max)),
                ("Range",      fmt(s.range)),
                ("Q1",         fmt(s.q1)),
                ("Q3",         fmt(s.q3)),
                ("IQR",        fmt(s.iqr)),
                ("Skewness",   fmt(s.skewness)),
                ("Kurtosis",   fmt(s.kurtosis)),
            ]

            ForEach(rows, id: \.0) { label, value in
                StatRow(label: label, value: value)
            }
        }
        .padding(16)
        .glassCard()
    }

    private func regressionCard(_ s: StatisticsEngine.Stats) -> some View {
        let data = StatisticsEngine.parse(inputText)
        let xs = data.indices.map { Double($0) }
        guard let lr = StatisticsEngine.linearRegression(xs: xs, ys: data) else {
            return AnyView(EmptyView())
        }

        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                Text("LINEAR REGRESSION")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.muted)

                StatRow(label: "Slope (m)",     value: fmt(lr.slope))
                StatRow(label: "Intercept (b)", value: fmt(lr.intercept))
                StatRow(label: "R² fit",        value: String(format: "%.4f", lr.r2))

                Text("y = \(fmt(lr.slope))x + \(fmt(lr.intercept))")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.foreground)
                    .padding(.top, 4)
            }
            .padding(16)
            .glassCard()
        )
    }

    // MARK: - Actions

    private func compute() {
        let data = StatisticsEngine.parse(inputText)
        guard !data.isEmpty else { return }
        isComputing = true

        Task {
            let s = StatisticsEngine.compute(data: data)
            let hist = StatisticsEngine.histogram(data: data)
            await MainActor.run {
                withAnimation(.spring(response: 0.4)) {
                    stats = s
                    histData = hist
                }
                isComputing = false
            }
        }
    }

    private func fmt(_ v: Double) -> String {
        if v == v.rounded() && abs(v) < 1e8 { return "\(Int(v))" }
        return String(format: "%.4f", v)
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Theme.muted)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.foreground)
                .textSelection(.enabled)
        }
        .padding(.vertical, 6)
        .overlay(alignment: .bottom) {
            Divider().background(Theme.border.opacity(0.5))
        }
    }
}
