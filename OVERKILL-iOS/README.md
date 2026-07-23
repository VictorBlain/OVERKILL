# OVERKILL — iOS
### The Ultimate Graphing Calculator (Swift Edition)

> **Operation Phoenix** — Professional migration from React Native to native SwiftUI.

---

## Overview

OVERKILL is a production-grade iOS graphing calculator built entirely in Swift and SwiftUI. Every algorithm — expression parsing, symbolic differentiation, matrix decomposition, statistical computation — is implemented from first principles in pure Swift, with no external dependencies.

---

## Requirements

| Item | Requirement |
|---|---|
| Language | Swift 5.9+ |
| IDE | Xcode 15+ |
| Minimum iOS | 17.0 |
| Device | iPhone (portrait) |
| Dependencies | **None** |

---

## Getting Started

```bash
# 1. Clone the repo
git clone https://github.com/VictorBlain/OVERKILL.git
cd OVERKILL/OVERKILL-iOS

# 2. Open in Xcode
open OVERKILL.xcodeproj

# 3. Select a simulator or device, press ⌘R
```

No package installation required. No CocoaPods. No SPM fetch. Open and run.

---

## Feature Set

### 📐 Graphing Engine
- Plot arbitrary functions of x using a high-performance SwiftUI Canvas renderer
- Multiple simultaneous functions, each with a distinct colour and glow effect
- Pan (drag) and zoom (pinch) — infinite exploration
- Double-tap or reset button to return to default viewport
- Intelligent grid and axis labels that adapt to zoom level

### ∫ Calculus Suite
| Feature | Method |
|---|---|
| Symbolic derivative | Full recursive-descent AST with differentiation rules |
| Definite integral | Simpson's rule (n=10,000) on [−10, 10] |
| Taylor / Maclaurin series | Iterative symbolic differentiation, order 5 |
| Root finding | Bisection search on [−20, 20] |
| Limit evaluation | Numerical approach as x → 0 |

### ⬛ Matrix Engine
- 2×2, 3×3, 4×4 matrices
- Determinant (Gaussian elimination)
- Inverse (Gauss-Jordan)
- Transpose, A×A multiplication
- Eigenvalues (QR iteration)
- LU decomposition (Doolittle)

### 📊 Statistics
- Descriptive stats: mean, median, mode, std, variance, min, max, range, Q1, Q3, IQR, skewness, kurtosis
- Native histogram via Swift Charts
- Linear regression with R² coefficient

### 🧠 Hyperion Math Edition
An entirely offline mathematical knowledge assistant. No internet. No API key. No external AI services.  
18 curated topics covering calculus, algebra, trigonometry, linear algebra, statistics, complex numbers, and more.  
Full keyword search with relevance ranking.

### 🎓 Onboarding & Tutorial
- 7-page interactive tutorial with smooth page transitions
- Covers graphing, gestures, calculus, matrix, and Hyperion
- Replay anytime from Settings

### ⚙️ Settings
- Color scheme: Dark / Light / System
- Accessibility: Large Text, High Contrast, Reduce Motion
- Reset tutorial
- About, Credits, Version screens

---

## Architecture

```
OVERKILL-iOS/
├── OVERKILL.xcodeproj/
└── OVERKILL/
    ├── OVERKILLApp.swift          # @main entry point
    ├── ContentView.swift          # TabView root
    ├── Core/
    │   ├── AppState.swift         # @MainActor ObservableObject
    │   ├── Theme.swift            # Design tokens, colour, glow
    │   └── Math/
    │       ├── ExpressionEvaluator.swift  # Parser + evaluator + symbolic diff
    │       ├── MatrixEngine.swift          # LU, QR, eigenvalues
    │       └── StatisticsEngine.swift      # Descriptive stats + regression
    ├── Features/
    │   ├── Graph/                  # Canvas renderer, function panel
    │   ├── Calculator/             # Symbolic calculus UI
    │   ├── Matrix/                 # Matrix operations UI
    │   ├── Statistics/             # Stats + Swift Charts histogram
    │   ├── HyperionMath/           # Offline knowledge assistant
    │   ├── Onboarding/             # Welcome + tutorial pages
    │   └── Settings/               # Settings, About, Credits, Version
    └── Assets.xcassets/
```

### Key Design Decisions
- **No external dependencies** — pure Swift, Apple frameworks only
- **Canvas API** for graph rendering (60fps, no UIKit bridging)
- **Recursive-descent parser** with Pratt-style precedence for expression evaluation
- **Symbolic differentiation** via AST transformation (not numerical everywhere)
- **AppStorage** for persistence — lightweight, no Core Data overhead
- **@MainActor** on AppState for safe SwiftUI state updates

---

## Credits

**Developer:** Vihaan Vaghela

**Apple Frameworks:** SwiftUI · Swift Charts · Canvas API · Combine · AppStorage

**Design Inspiration:** Apple HIG · Desmos · Wolfram Alpha · Linear · Arc Browser

---

## Roadmap

- [ ] 3D surface graphing with Metal
- [ ] Polar and parametric plots
- [ ] Complex number visualisation (Argand plane)  
- [ ] iCloud sync
- [ ] Custom colour themes
- [ ] Physics simulation engine
- [ ] Mathematical notebooks (LaTeX rendering)
- [ ] Enhanced Hyperion with on-device ML (Core ML)

---

*OVERKILL © 2025 Vihaan Vaghela. Built as a demonstration of App Store–quality engineering discipline.*
