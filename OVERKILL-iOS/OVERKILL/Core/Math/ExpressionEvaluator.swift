import Foundation

// MARK: - Token
private enum Token: Equatable {
    case number(Double)
    case identifier(String)
    case plus, minus, star, slash, caret, lparen, rparen, comma
    case end
}

// MARK: - Lexer
private struct Lexer {
    let source: [Character]
    var pos: Int = 0

    init(_ s: String) { source = Array(s) }

    var current: Character? { pos < source.count ? source[pos] : nil }

    mutating func next() -> Token {
        // skip whitespace
        while let c = current, c.isWhitespace { pos += 1 }
        guard let c = current else { return .end }

        // number
        if c.isNumber || (c == "." && pos + 1 < source.count && source[pos + 1].isNumber) {
            var s = ""
            while let d = current, d.isNumber || d == "." { s.append(d); pos += 1 }
            if let e = current, e == "e" || e == "E" {
                s.append(e); pos += 1
                if let sign = current, sign == "+" || sign == "-" { s.append(sign); pos += 1 }
                while let d = current, d.isNumber { s.append(d); pos += 1 }
            }
            return .number(Double(s) ?? 0)
        }

        // identifier
        if c.isLetter || c == "_" {
            var s = ""
            while let d = current, d.isLetter || d.isNumber || d == "_" { s.append(d); pos += 1 }
            return .identifier(s)
        }

        pos += 1
        switch c {
        case "+": return .plus
        case "-": return .minus
        case "*": return .star
        case "/": return .slash
        case "^": return .caret
        case "(": return .lparen
        case ")": return .rparen
        case ",": return .comma
        default:  return .end
        }
    }
}

// MARK: - Parser / Evaluator
struct ExpressionEvaluator {

    // MARK: evaluate
    static func evaluate(_ expr: String, x: Double) throws -> Double {
        var lex = Lexer(expr)
        var tokens: [Token] = []
        var t = lex.next()
        while t != .end { tokens.append(t); t = lex.next() }
        tokens.append(.end)
        var parser = Parser(tokens: tokens, x: x)
        let value = try parser.parseExpr()
        return value
    }

    // MARK: buildSamplePoints
    /// Returns an array of (x, y?) pairs. y is nil when undefined.
    static func samplePoints(
        expr: String,
        xMin: Double, xMax: Double,
        count: Int = 600
    ) -> [(x: Double, y: Double?)] {
        let step = (xMax - xMin) / Double(count - 1)
        return (0..<count).map { i in
            let xv = xMin + Double(i) * step
            let yv = try? evaluate(expr, x: xv)
            let finite = yv.map { $0.isFinite } ?? false
            return (xv, finite ? yv : nil)
        }
    }

    // MARK: symbolicDerivative
    static func symbolicDerivative(of expr: String) -> String? {
        guard let node = parse(expr) else { return nil }
        return differentiate(node).simplified().description
    }

    // MARK: numericalIntegral (Simpson's rule, -10 to 10)
    static func numericalIntegral(
        expr: String,
        from a: Double = -10,
        to b: Double = 10,
        n: Int = 10_000
    ) -> Double? {
        let n = n % 2 == 0 ? n : n + 1
        let h = (b - a) / Double(n)
        var sum = 0.0
        for i in 0...n {
            let xv = a + Double(i) * h
            guard let y = try? evaluate(expr, x: xv), y.isFinite else { continue }
            let w: Double = (i == 0 || i == n) ? 1 : (i % 2 == 0 ? 2 : 4)
            sum += w * y
        }
        return (h / 3) * sum
    }

    // MARK: taylorSeries (around 0, up to order 5)
    static func taylorSeries(expr: String, order: Int = 5) -> String {
        var terms: [String] = []
        var factorial: Double = 1
        var currentExpr = expr
        for n in 0...order {
            if n > 0 { factorial *= Double(n) }
            guard let coeff = try? evaluate(currentExpr, x: 0) else { break }
            let c = coeff / factorial
            if abs(c) > 1e-12 {
                let s: String
                if n == 0       { s = fmt(c) }
                else if n == 1  { s = fmtCoeff(c) + "x" }
                else            { s = fmtCoeff(c) + "x^\(n)" }
                terms.append(s)
            }
            if n < order {
                guard let derived = symbolicDerivative(of: currentExpr) else { break }
                currentExpr = derived
            }
        }
        return terms.isEmpty ? "0" : terms.joined(separator: " + ")
            .replacingOccurrences(of: "+ -", with: "- ")
    }

    // MARK: numericalRoots (bisection on [-20, 20])
    static func findRoots(expr: String, interval: ClosedRange<Double> = -20...20, steps: Int = 1000) -> [Double] {
        let h = (interval.upperBound - interval.lowerBound) / Double(steps)
        var roots: [Double] = []
        for i in 0..<steps {
            let x1 = interval.lowerBound + Double(i) * h
            let x2 = x1 + h
            guard let y1 = try? evaluate(expr, x: x1),
                  let y2 = try? evaluate(expr, x: x2),
                  y1.isFinite, y2.isFinite, y1 * y2 <= 0 else { continue }
            // bisect
            var lo = x1, hi = x2
            for _ in 0..<50 {
                let mid = (lo + hi) / 2
                guard let ym = try? evaluate(expr, x: mid), ym.isFinite else { break }
                if abs(ym) < 1e-10 { lo = mid; break }
                if (try? evaluate(expr, x: lo)).map({ $0 * ym }) ?? 1 <= 0 { hi = mid } else { lo = mid }
            }
            let root = (lo + hi) / 2
            if !roots.contains(where: { abs($0 - root) < 1e-6 }) {
                roots.append(root)
            }
        }
        return roots.sorted()
    }

    // MARK: numericalLimit (approaches 0)
    static func numericalLimit(expr: String, approaching a: Double = 0) -> Double? {
        let deltas = [1e-4, 1e-5, 1e-6, 1e-7]
        var vals: [Double] = []
        for d in deltas {
            if let v = try? evaluate(expr, x: a + d), v.isFinite { vals.append(v) }
        }
        guard !vals.isEmpty else { return nil }
        let result = vals.last!
        return result.isFinite ? result : nil
    }

    // MARK: helpers
    private static func fmt(_ v: Double) -> String {
        if v == v.rounded() && abs(v) < 1e10 { return "\(Int(v))" }
        return String(format: "%.4g", v)
    }
    private static func fmtCoeff(_ v: Double) -> String {
        if abs(abs(v) - 1) < 1e-10 { return v < 0 ? "-" : "" }
        return fmt(v)
    }
}

// MARK: - Recursive-descent parser (internal)

private struct Parser {
    let tokens: [Token]
    var pos: Int = 0
    let xValue: Double

    init(tokens: [Token], x: Double) { self.tokens = tokens; xValue = x }

    var current: Token { tokens[min(pos, tokens.count - 1)] }
    mutating func consume() -> Token { let t = current; pos += 1; return t }
    @discardableResult mutating func expect(_ t: Token) throws -> Token {
        guard current == t else { throw EvalError.syntax }
        return consume()
    }

    mutating func parseExpr() throws -> Double { try parseAddSub() }

    mutating func parseAddSub() throws -> Double {
        var lhs = try parseMulDiv()
        while current == .plus || current == .minus {
            let op = consume()
            let rhs = try parseMulDiv()
            lhs = op == .plus ? lhs + rhs : lhs - rhs
        }
        return lhs
    }

    mutating func parseMulDiv() throws -> Double {
        var lhs = try parseUnary()
        while current == .star || current == .slash {
            let op = consume()
            let rhs = try parseUnary()
            if op == .slash { guard rhs != 0 else { return .nan }; lhs /= rhs }
            else { lhs *= rhs }
        }
        return lhs
    }

    mutating func parseUnary() throws -> Double {
        if current == .minus { consume(); return try -parsePower() }
        if current == .plus  { consume(); return try  parsePower() }
        return try parsePower()
    }

    mutating func parsePower() throws -> Double {
        let base = try parseCall()
        if current == .caret {
            consume()
            let exp = try parseUnary() // right-associative
            return pow(base, exp)
        }
        return base
    }

    mutating func parseCall() throws -> Double {
        if case .identifier(let name) = current {
            // peek: is next token lparen?
            if pos + 1 < tokens.count, tokens[pos + 1] == .lparen {
                consume() // name
                consume() // (
                var args: [Double] = []
                if current != .rparen {
                    args.append(try parseExpr())
                    while current == .comma { consume(); args.append(try parseExpr()) }
                }
                try expect(.rparen)
                return try callFunction(name, args: args)
            }
        }
        return try parseAtom()
    }

    mutating func parseAtom() throws -> Double {
        switch current {
        case .number(let v):
            consume(); return v
        case .identifier(let name):
            consume()
            switch name.lowercased() {
            case "x":   return xValue
            case "pi":  return .pi
            case "e":   return M_E
            case "inf", "infinity": return .infinity
            default: throw EvalError.unknownVariable(name)
            }
        case .lparen:
            consume()
            let v = try parseExpr()
            try expect(.rparen)
            return v
        default:
            throw EvalError.syntax
        }
    }

    func callFunction(_ name: String, args: [Double]) throws -> Double {
        let a = args.first ?? 0
        let b = args.dropFirst().first ?? 0
        switch name.lowercased() {
        case "sin":   return sin(a)
        case "cos":   return cos(a)
        case "tan":   return tan(a)
        case "asin", "arcsin": return asin(a)
        case "acos", "arccos": return acos(a)
        case "atan", "arctan": return atan(a)
        case "atan2":          return atan2(a, b)
        case "sinh":  return sinh(a)
        case "cosh":  return cosh(a)
        case "tanh":  return tanh(a)
        case "sqrt":  return sqrt(a)
        case "cbrt":  return cbrt(a)
        case "abs":   return abs(a)
        case "ceil":  return ceil(a)
        case "floor": return floor(a)
        case "round": return round(a)
        case "exp":   return exp(a)
        case "log", "ln": return log(a)
        case "log10": return log10(a)
        case "log2":  return log2(a)
        case "pow":   return pow(a, b)
        case "max":   return max(a, b)
        case "min":   return min(a, b)
        case "sign":  return a > 0 ? 1 : (a < 0 ? -1 : 0)
        case "fac", "factorial":
            let n = Int(a)
            guard n >= 0, n <= 20 else { return .nan }
            return Double((1...max(n,1)).reduce(1, *))
        default: throw EvalError.unknownFunction(name)
        }
    }
}

// MARK: - Symbolic AST for differentiation

indirect enum Expr {
    case num(Double)
    case variable
    case add(Expr, Expr)
    case sub(Expr, Expr)
    case mul(Expr, Expr)
    case div(Expr, Expr)
    case pow(Expr, Expr)
    case neg(Expr)
    case fn(String, Expr)

    var description: String {
        switch self {
        case .num(let v):
            if v == v.rounded() && abs(v) < 1e10 { return "\(Int(v))" }
            return String(format: "%.4g", v)
        case .variable: return "x"
        case .add(let a, let b): return "(\(a.description) + \(b.description))"
        case .sub(let a, let b): return "(\(a.description) - \(b.description))"
        case .mul(let a, let b): return "(\(a.description) * \(b.description))"
        case .div(let a, let b): return "(\(a.description) / \(b.description))"
        case .pow(let a, let b): return "(\(a.description) ^ \(b.description))"
        case .neg(let a):        return "-\(a.description)"
        case .fn(let name, let a): return "\(name)(\(a.description))"
        }
    }

    func simplified() -> Expr {
        switch self {
        case .add(.num(0), let e), .add(let e, .num(0)): return e.simplified()
        case .sub(let e, .num(0)): return e.simplified()
        case .mul(.num(0), _), .mul(_, .num(0)): return .num(0)
        case .mul(.num(1), let e), .mul(let e, .num(1)): return e.simplified()
        case .div(let e, .num(1)): return e.simplified()
        case .pow(let e, .num(1)): return e.simplified()
        case .pow(_, .num(0)):     return .num(1)
        case .neg(.num(let v)):    return .num(-v)
        case .add(.num(let a), .num(let b)): return .num(a + b)
        case .sub(.num(let a), .num(let b)): return .num(a - b)
        case .mul(.num(let a), .num(let b)): return .num(a * b)
        case .div(.num(let a), .num(let b)) where b != 0: return .num(a / b)
        case .pow(.num(let a), .num(let b)): return .num(Foundation.pow(a, b))
        case .add(let a, let b): return .add(a.simplified(), b.simplified())
        case .sub(let a, let b): return .sub(a.simplified(), b.simplified())
        case .mul(let a, let b): return .mul(a.simplified(), b.simplified())
        case .div(let a, let b): return .div(a.simplified(), b.simplified())
        case .pow(let a, let b): return .pow(a.simplified(), b.simplified())
        case .neg(let a):        return .neg(a.simplified())
        case .fn(let name, let a): return .fn(name, a.simplified())
        default: return self
        }
    }
}

private func differentiate(_ e: Expr) -> Expr {
    switch e {
    case .num:    return .num(0)
    case .variable: return .num(1)
    case .neg(let a): return .neg(differentiate(a))
    case .add(let a, let b): return .add(differentiate(a), differentiate(b))
    case .sub(let a, let b): return .sub(differentiate(a), differentiate(b))
    // product rule
    case .mul(let a, let b):
        return .add(.mul(differentiate(a), b), .mul(a, differentiate(b)))
    // quotient rule
    case .div(let a, let b):
        return .div(
            .sub(.mul(differentiate(a), b), .mul(a, differentiate(b))),
            .pow(b, .num(2))
        )
    // power rule  d/dx x^n = n*x^(n-1)
    case .pow(.variable, .num(let n)):
        return .mul(.num(n), .pow(.variable, .num(n - 1)))
    // general power rule: d/dx f^g = f^g*(g'*ln(f) + g*f'/f)
    case .pow(let f, let g):
        let term1 = .mul(differentiate(g), .fn("log", f))
        let term2: Expr = .mul(g, .div(differentiate(f), f))
        return .mul(.pow(f, g), .add(term1, term2))
    // chain rule for standard functions
    case .fn(let name, let u):
        let du = differentiate(u)
        let dOuter: Expr
        switch name {
        case "sin": dOuter = .fn("cos", u)
        case "cos": dOuter = .neg(.fn("sin", u))
        case "tan": dOuter = .div(.num(1), .pow(.fn("cos", u), .num(2)))
        case "asin": dOuter = .div(.num(1), .fn("sqrt", .sub(.num(1), .pow(u, .num(2)))))
        case "acos": dOuter = .neg(.div(.num(1), .fn("sqrt", .sub(.num(1), .pow(u, .num(2))))))
        case "atan": dOuter = .div(.num(1), .add(.num(1), .pow(u, .num(2))))
        case "exp":  dOuter = .fn("exp", u)
        case "log", "ln": dOuter = .div(.num(1), u)
        case "log10": dOuter = .div(.num(1), .mul(u, .fn("log", .num(M_E * log(10)))))
        case "sqrt": dOuter = .div(.num(1), .mul(.num(2), .fn("sqrt", u)))
        case "abs":  dOuter = .div(u, .fn("abs", u))
        case "sinh": dOuter = .fn("cosh", u)
        case "cosh": dOuter = .fn("sinh", u)
        case "tanh": dOuter = .sub(.num(1), .pow(.fn("tanh", u), .num(2)))
        default: dOuter = .num(0)
        }
        return .mul(dOuter, du)
    }
}

private func parse(_ expr: String) -> Expr? {
    var lex = Lexer(expr)
    var tokens: [Token] = []
    var t = lex.next()
    while t != .end { tokens.append(t); t = lex.next() }
    tokens.append(.end)
    var parser = SymbolicParser(tokens: tokens)
    return try? parser.parseExpr()
}

// MARK: - Symbolic parser
private struct SymbolicParser {
    let tokens: [Token]
    var pos: Int = 0
    var current: Token { tokens[min(pos, tokens.count - 1)] }
    mutating func consume() -> Token { let t = current; pos += 1; return t }

    mutating func parseExpr() throws -> Expr { try parseAddSub() }

    mutating func parseAddSub() throws -> Expr {
        var lhs = try parseMulDiv()
        while current == .plus || current == .minus {
            let op = consume()
            let rhs = try parseMulDiv()
            lhs = op == .plus ? .add(lhs, rhs) : .sub(lhs, rhs)
        }
        return lhs
    }

    mutating func parseMulDiv() throws -> Expr {
        var lhs = try parseUnary()
        while current == .star || current == .slash {
            let op = consume()
            let rhs = try parseUnary()
            lhs = op == .star ? .mul(lhs, rhs) : .div(lhs, rhs)
        }
        return lhs
    }

    mutating func parseUnary() throws -> Expr {
        if current == .minus { consume(); return .neg(try parsePower()) }
        if current == .plus  { consume(); return try parsePower() }
        return try parsePower()
    }

    mutating func parsePower() throws -> Expr {
        let base = try parseCall()
        if current == .caret { consume(); let exp = try parseUnary(); return .pow(base, exp) }
        return base
    }

    mutating func parseCall() throws -> Expr {
        if case .identifier(let name) = current, pos + 1 < tokens.count, tokens[pos + 1] == .lparen {
            consume(); consume()
            let arg = try parseExpr()
            if current == .rparen { consume() }
            return .fn(name.lowercased(), arg)
        }
        return try parseAtom()
    }

    mutating func parseAtom() throws -> Expr {
        switch current {
        case .number(let v): consume(); return .num(v)
        case .identifier(let n):
            consume()
            switch n.lowercased() {
            case "x":  return .variable
            case "pi": return .num(.pi)
            case "e":  return .num(M_E)
            default:   return .num(0)
            }
        case .lparen:
            consume()
            let v = try parseExpr()
            if current == .rparen { consume() }
            return v
        default: throw EvalError.syntax
        }
    }
}

// MARK: - Errors
enum EvalError: Error, LocalizedError {
    case syntax
    case unknownVariable(String)
    case unknownFunction(String)

    var errorDescription: String? {
        switch self {
        case .syntax:                  return "Invalid expression syntax"
        case .unknownVariable(let n):  return "Unknown variable '\(n)'"
        case .unknownFunction(let n):  return "Unknown function '\(n)'"
        }
    }
}
