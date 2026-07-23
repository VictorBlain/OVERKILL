import SwiftUI

// MARK: - Viewport
struct Viewport {
    var xMin: Double = -10
    var xMax: Double =  10
    var yMin: Double = -10
    var yMax: Double =  10

    var xRange: Double { xMax - xMin }
    var yRange: Double { yMax - yMin }

    func toScreen(_ x: Double, _ y: Double, in size: CGSize) -> CGPoint {
        CGPoint(
            x: (x - xMin) / xRange * size.width,
            y: size.height - (y - yMin) / yRange * size.height
        )
    }

    func toMath(_ p: CGPoint, in size: CGSize) -> (x: Double, y: Double) {
        (
            x: xMin + Double(p.x) / Double(size.width)  * xRange,
            y: yMin + (1 - Double(p.y) / Double(size.height)) * yRange
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

    @State private var size: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero
    @State private var lastDragOffset: CGSize = .zero

    // For pinch
    @GestureState private var magnification: CGFloat = 1.0
    @State private var baseViewport: Viewport = Viewport()

    var body: some View {
        Canvas { ctx, sz in
            drawGrid(ctx: ctx, sz: sz)
            drawAxes(ctx: ctx, sz: sz)
            drawFunctions(ctx: ctx, sz: sz)
        }
        .background(Color.black)
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .gesture(magnifyGesture)
        .simultaneousGesture(doubleTapGesture)
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.4)) { viewport.reset() }
        }
        .overlay(alignment: .topTrailing) {
            resetButton
        }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let dx = (Double(value.translation.width  - lastDragOffset.width)  / Double(UIScreen.main.bounds.width))  * viewport.xRange
                let dy = (Double(value.translation.height - lastDragOffset.height) / Double(UIScreen.main.bounds.height)) * viewport.yRange
                lastDragOffset = value.translation
                viewport.pan(dx: -dx, dy: dy)
            }
            .onEnded { _ in lastDragOffset = .zero }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let factor = 1 / Double(value.magnification)
                let cx = (viewport.xMin + viewport.xMax) / 2
                let cy = (viewport.yMin + viewport.yMax) / 2
                var vp = baseViewport
                vp.zoom(factor: factor, centerX: cx, centerY: cy)
                viewport = vp
            }
            .onEnded { _ in baseViewport = viewport }
    }

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2).onEnded { viewport.reset() }
    }

    // MARK: - Drawing

    private func drawGrid(ctx: GraphicsContext, sz: CGSize) {
        let xStep = niceStep(range: viewport.xRange)
        let yStep = niceStep(range: viewport.yRange)

        var x = (viewport.xMin / xStep).rounded(.up) * xStep
        while x <= viewport.xMax {
            let sx = CGFloat((x - viewport.xMin) / viewport.xRange) * sz.width
            ctx.stroke(
                Path { p in p.move(to: CGPoint(x: sx, y: 0)); p.addLine(to: CGPoint(x: sx, y: sz.height)) },
                with: .color(.white.opacity(0.07)),
                lineWidth: 0.5
            )
            x += xStep
        }

        var y = (viewport.yMin / yStep).rounded(.up) * yStep
        while y <= viewport.yMax {
            let sy = sz.height - CGFloat((y - viewport.yMin) / viewport.yRange) * sz.height
            ctx.stroke(
                Path { p in p.move(to: CGPoint(x: 0, y: sy)); p.addLine(to: CGPoint(x: sz.width, y: sy)) },
                with: .color(.white.opacity(0.07)),
                lineWidth: 0.5
            )
            y += yStep
        }

        // Labels
        x = (viewport.xMin / xStep).rounded(.up) * xStep
        while x <= viewport.xMax {
            if abs(x) > xStep * 0.01 {
                let sx = CGFloat((x - viewport.xMin) / viewport.xRange) * sz.width
                let axisY = min(max(sz.height - CGFloat((0 - viewport.yMin) / viewport.yRange) * sz.height, 0), sz.height - 14)
                ctx.draw(Text(formatLabel(x)).font(.system(size: 9)).foregroundStyle(Color.white.opacity(0.3)),
                         at: CGPoint(x: sx + 4, y: axisY + 10))
            }
            x += xStep
        }
        y = (viewport.yMin / yStep).rounded(.up) * yStep
        while y <= viewport.yMax {
            if abs(y) > yStep * 0.01 {
                let sy = sz.height - CGFloat((y - viewport.yMin) / viewport.yRange) * sz.height
                let axisX = min(max(CGFloat((0 - viewport.xMin) / viewport.xRange) * sz.width, 0), sz.width - 30)
                ctx.draw(Text(formatLabel(y)).font(.system(size: 9)).foregroundStyle(Color.white.opacity(0.3)),
                         at: CGPoint(x: axisX + 4, y: sy - 8))
            }
            y += yStep
        }
    }

    private func drawAxes(ctx: GraphicsContext, sz: CGSize) {
        let axisX = CGFloat((0 - viewport.xMin) / viewport.xRange) * sz.width
        let axisY = sz.height - CGFloat((0 - viewport.yMin) / viewport.yRange) * sz.height

        let axisColor = Color.white.opacity(0.4)

        if axisX >= 0 && axisX <= sz.width {
            ctx.stroke(
                Path { p in p.move(to: CGPoint(x: axisX, y: 0)); p.addLine(to: CGPoint(x: axisX, y: sz.height)) },
                with: .color(axisColor), lineWidth: 1.5
            )
        }
        if axisY >= 0 && axisY <= sz.height {
            ctx.stroke(
                Path { p in p.move(to: CGPoint(x: 0, y: axisY)); p.addLine(to: CGPoint(x: sz.width, y: axisY)) },
                with: .color(axisColor), lineWidth: 1.5
            )
        }
    }

    private func drawFunctions(ctx: GraphicsContext, sz: CGSize) {
        let visible = functions.filter { $0.isVisible }
        guard !visible.isEmpty else { return }

        let sampleCount = min(Int(sz.width * 2), 800)

        for fn in visible {
            let points = ExpressionEvaluator.samplePoints(
                expr: fn.expression,
                xMin: viewport.xMin,
                xMax: viewport.xMax,
                count: sampleCount
            )

            var path = Path()
            var penDown = false
            var prevY: Double? = nil
            let yPad = viewport.yRange * 3

            for pt in points {
                guard let y = pt.y else { penDown = false; prevY = nil; continue }
                if let py = prevY, abs(y - py) > viewport.yRange * 10 { penDown = false }
                if y < viewport.yMin - yPad || y > viewport.yMax + yPad { penDown = false; prevY = y; continue }

                let sx = CGFloat((pt.x - viewport.xMin) / viewport.xRange) * sz.width
                let sy = sz.height - CGFloat((y - viewport.yMin) / viewport.yRange) * sz.height

                if !penDown { path.move(to: CGPoint(x: sx, y: sy)); penDown = true }
                else        { path.addLine(to: CGPoint(x: sx, y: sy)) }
                prevY = y
            }

            ctx.stroke(path, with: .color(fn.color), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

            // Glow layer
            ctx.stroke(path, with: .color(fn.color.opacity(0.25)), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: - UI
    private var resetButton: some View {
        Button {
            withAnimation(.spring(response: 0.4)) { viewport.reset() }
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.muted)
                .padding(10)
                .background(Theme.surface1.opacity(0.8))
                .clipShape(Circle())
        }
        .padding(12)
    }

    // MARK: - Helpers
    private func niceStep(range: Double, targetLines: Int = 8) -> Double {
        let rough = range / Double(targetLines)
        let mag = pow(10, floor(log10(abs(rough) < 1e-14 ? 1 : abs(rough))))
        let n = rough / mag
        if n <= 1 { return mag }
        if n <= 2 { return 2 * mag }
        if n <= 5 { return 5 * mag }
        return 10 * mag
    }

    private func formatLabel(_ v: Double) -> String {
        if v == v.rounded() && abs(v) < 1e6 { return "\(Int(v))" }
        return String(format: "%.2g", v)
    }
}
