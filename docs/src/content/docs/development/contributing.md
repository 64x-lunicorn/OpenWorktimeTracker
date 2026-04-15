---
title: Contributing
description: How to contribute to OpenWorktimeTracker.
---

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Set up the development environment (see [Build from Source](/development/build/))
4. Create a feature branch from `main`

```bash
git checkout -b feat/my-feature
```

## Code Style

- **Swift 5.9+** -- Use modern Swift features (`@Observable`, `if`/`switch` expressions)
- **SwiftLint** -- All code must pass linting (see `.swiftlint.yml`)
- **No external dependencies** beyond Sparkle
- **`@Observable`** for state management (never `ObservableObject`)
- **DesignTokens** for all colors and typography (no hard-coded values)
- **No emojis** in code, comments, or documentation

## Architecture Rules

All changes should follow the existing architecture:

| Directory | Purpose |
|-----------|---------|
| `Core/Models/` | Codable data structures |
| `Core/Services/` | Business logic (`@Observable` where needed) |
| `Views/` | SwiftUI views |
| `Views/Components/` | Reusable UI components |
| `Design/` | Design tokens only |

## Writing Tests

- Write tests for any new business logic
- Focus on edge cases (exactly at thresholds, boundary conditions)
- Tests go in `OpenWorktimeTrackerTests/`
- Run tests locally before submitting: `make test`

## Pull Request Process

1. Create a feature branch from `main`
2. Make your changes
3. Run `make test` and `make lint` locally
4. Open a PR with a clear description
5. Wait for CI to pass
6. Address review feedback

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add weekly summary view
fix: correct break calculation for exactly 6h
docs: update README with new screenshots
test: add edge cases for WorkdayDetector
refactor: extract timer logic from WorkdayManager
```

## License

By contributing, you agree that your contributions will be licensed under the [AGPL-3.0 License](https://github.com/64x-lunicorn/OpenWorktimeTracker/blob/main/LICENSE).
