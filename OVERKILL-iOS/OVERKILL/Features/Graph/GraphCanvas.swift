import SwiftUI

// MARK: - Viewport

struct Viewport: Equatable {
    var xMin: Double = -10
    var xMax: Double =  10
    var yMin: Double = -10
    var yMax: Double =  10

    var xRange: Double { xMax - xMin }
    var yRange: Double { yMax - yMin }

    func toScreen(_ x: Double, _ y: Double, in size: CGSize) -> CGPoint {
        CGPoint(
            x: (x - xMin) / xRange * Double(size.width),
            y: Double(size.height) - (y - yMin) / yRange * Double(size.height)
        )
    }

    func toMath(_ p: CGPoint, in size: CGSize) -> (x: Double, y: Double) {
        (
            x: xMin + Double(p.x) / Double(size.width)  * xRange,
            y: yMin + (1.0 - Double(p.y) / Double(size.height)) * yRange
        )
    }

    mutating func pan(dx: Double, dy: Double) {
        xMin += dx; xMax += dx
        yMin += dy; yMax += dy
    }

    mutating func zoom(factor: Double, centerX: Double, centerY: Double) {
        xMin = centerX + (xMin - centerX) * factor
        xMax = centerX + (xMax - centerX) * factor
        yMin = centerY + (yMin - centerY) * factor
        yMax = centerY + (yMax - centerY) * factor
    }

    mutating func reset() { self = Viewport() }
}

// MARK: - GraphCanvas

struct GraphCanvas: View {
    let functions: [GraphFunction]
    @Binding var viewport: Viewport

    // Canvas size tracked without UIScreen
    @State private var canvasSize: CGSize = .zero

    // Drag state
    @State private var dragStart: Viewport = Viewport()
    @GestureState private var dragTranslation: CGSize = .zero

    // Pinch state
    @State private var pinchStart: Viewport = Viewport()
    @GestureState private var magnification: CGFloat = 1.0

    var body: some View {
        Canvas { ctx, sz in
            drawGrid(ctx: ctx, sz: sz)
            drawAxes(ctx: ctx, sz: sz)
            drawFunctions(ctx: ctx, sz: sz)
        }
        .background(Color.black)
        .contentShape(Rectangle())
        // Size reader — pure SwiftUI, no UIScreen
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear { canvasSize = geo.size }
                    .onChange(of: geo.size) { _, newSize in canvasSize = newSize }
            }
        }
        .gesture(dragGesture)
        .gesture(magnifyGesture)
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                viewport.reset()
            }
        }
        .overlay(alignment: .topTrailing) {
            resetButton
        }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .updating($dragTranslation) { value, state, _ in
                state = value.translation
            }
            .onChanged { value in
                guard canvasSize.width > 0, canvasSize.height > 0 else { return }
                let dx = Double(value.translation.width)  / Double(canvasSize.width)  * dragStart.xRange
                let dy = Double(value.translation.height) / Double(canvasSize.height) * dragStart.yRange
                var vp = dragStart
                vp.pan(dx: -dx, dy: dy)
                viewport = vp
            }
            .onEnded { _ in
                dragStart = viewport
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .updating($magnification) { value, state, _ in
                state = value.magnification
            }
            .onChanged { value in
                let factor = 1.0 / Double(value.magnification)
                let cx = (pinchStart.xMin + pinchStart.xMax) / 2
                let cy = (pinchStart.yMin + pinchStart.yMax) / 2
                var vp = pinchStart
                vp.zoom(factor: factor, centerX: cx, centerY: cy)
                viewport = vp
            }
            .onEnded { _ in
                pinchStart = viewport
            }
    }

    // MARK: - Drawing

    private func drawGrid(ctx: GraphicsContext, sz: CGSize) {
        let xStep = niceStep(range: viewport.xRange)
        let yStep = niceStep(range: viewport.yRange)

        // Vertical grid lines
        var x = (viewport.xMin / xStep).rounded(.up) * xStep
        while x <= viewport.xMax + xStep * 0.01 {
            let sx = CGFloat((x - viewport.xMin) / viewport.xRange) * sz.width
            ctx.stroke(
                Path { p in
                    p.move(to: CGPoint(x: sx, y: 0))
                    p.addLine(to: CGPoint(x: sx, y: sz.height))
                },
                with: .color(.white.opacity(0.06)),
                lineWidth: 0.5
            )
            x += xStep
        }

        // Horizontal grid lines
        var y = (viewport.yMin / yStep).rounded(.up) * yStep
        while y <= viewport.yMax + yStep * 0.01 {
            let sy = sz.height - CGFloat((y - viewport.yMin) / viewport.yRange) * sz.height
            ctx.stroke(
                Path { p in
                    p.move(to: CGPoint(x: 0, y: sy))
                    p.addLine(to: CGPoint(x: sz.width, y: sy))
                },
                with: .color(.white.opacity(0.06)),
                lineWidth: 0.5
            )
            y += yStep
        }

        // X-axis labels
        let axisY = sz.height - CGFloat((0 - viewport.yMin) / viewport.yRange) * sz.height
        let labelY = min(max(axisY + 6, 4), sz.height - 14)
        x = (viewport.xMin / xStep).rounded(.up) * xStep
        while x <= viewport.xMax {
            if abs(x) > xStep * 0.01 {
                let sx = CGFloat((x - viewport.xMin) / viewport.xRange) * sz.width
                ctx.draw(
                    Text(formatLabel(x))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.28)),
                    at: CGPoint(x: sx + 3, y: labelY)
                )
            }
            x += xStep
        }

        // Y-axis labels
        let axisX = CGFloat((0 - viewport.xMin) / viewport.xRange) * sz.width
        let labelX = min(max(axisX + 4, 4), sz.width - 36)
        y = (viewport.yMin / yStep).rounded(.up) * yStep
        while y <= viewport.yMax {
            if abs(y) > yStep * 0.01 {
                let sy = sz.height - CGFloat((y - viewport.yMin) / viewport.yRange) * sz.height
                ctx.draw(
                    Text(formatLabel(y))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.28)),
                    at: CGPoint(x: labelX, y: sy - 9)
                )
            }
            y += yStep
        }
    }

    private func drawAxes(ctx: GraphicsContext, sz: CGSize) {
        let axisX = CGFloat((0 - viewport.xMin) / viewport.xRange) * sz.width
        let axisY = sz.height - CGFloat((0 - viewport.yMin) / viewport.yRange) * sz.height
        let color = Color.white.opacity(0.35)

        if axisX >= 0 && axisX <= sz.width {
            ctx.stroke(
                Path { p in
                    p.move(to: CGPoint(x: axisX, y: 0))
                    p.addLine(to: CGPoint(x: axisX, y: sz.height))
                },
                with: .color(color),
                lineWidth: 1.5
            )
        }
        if axisY >= 0 && axisY <= sz.height {
            ctx.stroke(
                Path { p in
                    p.move(to: CGPoint(x: 0, y: axisY))
                    p.addLine(to: CGPoint(x: sz.width, y: axisY))
                },
                with: .color(color),
                lineWidth: 1.5
            )
        }
    }

    private func drawFunctions(ctx: GraphicsContext, sz: CGSize) {
        let visible = functions.filter(\.isVisible)
        guard !visible.isEmpty else { return }

        let sampleCount = min(Int(sz.width * 2.5), 1200)

        for fn in visible {
            let pts = ExpressionEvaluator.samplePoints(
                expr: fn.expression,
                xMin: viewport.xMin,
                xMax: viewport.xMax,
                count: sampleCount
            )

            var path = Path()
            var penDown = false
            var prevY: Double?
            let jumpThreshold = viewport.yRange * 8
            let yPad = viewport.yRange * 4

            for pt in pts {
                guard let y = pt.y, y.isFinite else {
                    penDown = false; prevY = nil; continue
                }
                if let py = prevY, abs(y - py) > jumpThreshold {
                    penDown = false
                }
                if y < viewport.yMin - yPad || y > viewport.yMax + yPad {
                    penDown = false; prevY = y; continue
                }

                let sx = CGFloat((pt.x - viewport.xMin) / viewport.xRange) * sz.width
                let sy = sz.height - CGFloat((y - viewport.yMin) / viewport.yRange) * sz.height

                if !penDown {
                    path.move(to: CGPoint(x: sx, y: sy))
                    penDown = true
                } else {
                    path.addLine(to: CGPoint(x: sx, y: sy))
                }
                prevY = y
            }

            let style = StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            // Glow pass
            ctx.stroke(path, with: .color(fn.color.opacity(0.22)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
            ctx.stroke(path, with: .color(fn.color.opacity(0.45)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            // Main pass
            ctx.stroke(path, with: .color(fn.color), style: style)
        }
    }

    // MARK: - UI

    private var resetButton: some View {
        Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                viewport.reset()
                pinchStart.reset()
                dragStart.reset()
            }
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.muted)
                .padding(10)
                .background(Theme.surface1.opacity(0.9))
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Theme.border.opacity(0.6), lineWidth: 0.5))
        }
        .padding(.trailing, 12)
        .padding(.top, 60)
    }

    // MARK: - Helpers

    private func niceStep(range: Double, targetLines: Int = 8) -> Double {
        let rough = range / Double(targetLines)
        let safeRough = abs(rough) < 1e-14 ? 1.0 : abs(rough)
        let mag = pow(10.0, floor(log10(safeRough)))
        let n = rough / mag
        if n <= 1 { return mag }
        if n <= 2 { return 2 * mag }
        if n <= 5 { return 5 * mag }
        return 10 * mag
    }

    private func formatLabel(_ v: Double) -> String {
        let abs = Swift.abs(v)
        if abs == 0 { return "0" }
        if abs >= 1000 || abs < 0.01 { return String(format: "%.2e", v) }
        if v == v.rounded() { return "\(Int(v))" }
        return String(format: "%.2g", v)
    }
}
