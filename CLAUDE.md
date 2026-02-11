# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
make generate        # Regenerate Xcode project from project.yml (run after adding/removing files)
make build           # Build for simulator (Debug)
make release         # Build for device (Release)
make run             # Build and run on default simulator (iPhone 16 Pro)
make device DEVICE=Daedalus  # Build and install on named device
make lint            # SwiftLint (report only)
make lint-fix        # SwiftLint with autocorrect
make format          # SwiftFormat (applies changes)
make quality         # Run lint + format-check together
make clean           # Clean build artifacts
```

**After adding or removing Swift files, always run `make generate` before building.** The project uses xcodegen (`project.yml`) to generate `Gridcrack.xcodeproj`.

## Project Configuration

- **Platform:** iOS 16+ (deployment target in project.yml)
- **Swift:** 5.9
- **No external dependencies** — pure SwiftUI + UIKit bridging
- **No test suite** currently

## Lint & Format Rules

SwiftLint limits: 120-char lines, 400-line files, 300-line types, 50-line functions, 6 params max. The `.swiftformat` config disables `wrapMultilineStatementBraces` to avoid conflicts with SwiftLint's `opening_brace` rule.

## Architecture

### Pattern: ObservableObject / @Published (NOT @Observable)

iOS 16 target means `@Observable` (iOS 17+) cannot be used. All view models and services use `ObservableObject` with `@Published` properties, injected via `@StateObject`, `@ObservedObject`, or `@EnvironmentObject`.

### Game Modes

Two modes share core infrastructure through protocols and shared engines:

- **Standard Mode** — `GameViewModel` → single puzzle with difficulty tiers
- **Grid Rush Mode** — `GridRushViewModel` → timed endless puzzles

Both conform to `GamePlayable` protocol, enabling `MatrixGridView<VM: GamePlayable>` to render either mode's grid.

### Shared Logic (enum-based utilities)

- `GameEngine` — sequence progress tracking, feasibility checks, feedback coordination
- `PuzzleGeneratorCore` — solution path placement, cell filling, sequence design, validation
- `PathFinder` — recursive backtracking feasibility analysis using `inout SearchContext` struct

These are `@MainActor` enums with static methods (no instantiation) because they call `SoundManager`/`HapticsManager` which are `@MainActor`.

### Navigation & Transitions

`ContentView` hosts a `ZStack` with `BackgroundView`, `NavigationStack`, and `TransitionOverlay`. Two environment objects flow through the entire tree:

- `BackgroundStateManager` — controls which animated background renders
- `TransitionManager` — hex dissolve transition state machine (`idle → covering → covered → revealing → idle`)

Navigation uses `navigationDestination(isPresented:)` (not `item:` which requires iOS 17+). The `TransitionManager.transition(action:)` method wraps navigation state changes: it covers the screen with a hex dissolve, executes the navigation closure with UIKit animations disabled, then reveals. Custom swipe-back via `UIScreenEdgePanGestureRecognizer` triggers the same dissolve.

### Theme System

`BreachTheme.swift` contains `BreachColors`, `BreachTypography`, `BreachSpacing`, `BreachRadius` enums plus view modifiers (`breachBevel()`, `breachGlass()`, `clearNavigationBackground()`, `enableSwipeBack()`). `BreachComponents.swift` has reusable UI components (`BreachPanel`, `BreachButton`, `BreachSectionHeader`, `GlowingText`).

### Singletons

`GameSettings.shared` (UserDefaults persistence), `SoundManager.shared`, `HapticsManager.shared`, `TutorialManager.shared` — all `@MainActor`.

## Known Pitfalls

- `navigationDestination(item:)` requires iOS 17+ — use `isPresented:` variant
- When splitting functions to meet the 50-line limit, watch for `multiline_arguments`, `multiline_parameters`, and `function_parameter_count` SwiftLint rules
- Use a struct to group parameters when a function would exceed the 6-param limit
- SwiftFormat's `wrapMultilineStatementBraces` is disabled because it conflicts with SwiftLint's `opening_brace`
- `fatalError()` must include a message string (SwiftLint `fatal_error_message` opt-in rule)
