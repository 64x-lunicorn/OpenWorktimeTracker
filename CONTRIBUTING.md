# Contributing to OpenWorktimeTracker

## Development Setup

### Prerequisites
- macOS 14.0+ (Sonoma)
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- [SwiftLint](https://github.com/realm/SwiftLint): `brew install swiftlint`

### Getting Started

```bash
git clone https://github.com/64x-lunicorn/OpenWorktimeTracker.git
cd OpenWorktimeTracker
xcodegen generate       # Generate .xcodeproj from project.yml
open OpenWorktimeTracker.xcodeproj
```

Or build from command line:
```bash
make build    # Build release
make test     # Run tests
make lint     # Run SwiftLint
```

## Code Style

- **Swift 5.9+** — Use modern Swift features (`@Observable`, `if/switch` expressions)
- **SwiftLint** — All code must pass linting (see `.swiftlint.yml`)
- **No external dependencies** beyond Sparkle
- **`@Observable`** for state management (not `ObservableObject`)
- **DesignTokens** for all colors and typography (no hard-coded values)

## Architecture

All changes should follow the existing architecture:
- **Models** in `Core/Models/` — Codable data structures
- **Services** in `Core/Services/` — Business logic (`@Observable` where needed)
- **Views** in `Views/` — SwiftUI views
- **Design** in `Design/` — Design tokens only

## Pull Request Process

1. Create a feature branch from `main`
2. Write tests for new logic (especially `BreakCalculator`, `WorkdayDetector`)
3. Run `make test` and `make lint` locally
4. Open a PR with a clear description
5. Wait for CI to pass

## Commit Messages

Use conventional commits:
- `feat: add weekly summary view`
- `fix: correct break calculation for exactly 6h`
- `docs: update README with new screenshots`
- `test: add edge cases for WorkdayDetector`
