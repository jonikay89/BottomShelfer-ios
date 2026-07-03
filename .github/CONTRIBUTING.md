# Contributing to BottomShelfer

Thanks for considering contributing.

## Reporting bugs

Open an issue with:
- iOS / Xcode version
- Steps to reproduce
- Expected vs actual behavior

## Feature requests

Open an issue describing the use case and how it fits the library's scope.

## Pull requests

1. Fork the repo and create a branch from `main`.
2. Make your changes — follow the existing code style and conventions.
3. Add or update tests if applicable.
4. Build and verify with:

```bash
cd SampleApp
xcodebuild -project SampleApp.xcodeproj -scheme SampleApp -destination 'platform=iOS Simulator,name=iPhone 16' build
```

5. Open a PR against `main` with a clear description.

## Code style

- No commented-out code
- No emoji in source
- Follow existing naming patterns (`BottomShelfer` prefix for public types)
- Use `@MainActor` where required by UIKit
- Keep the minimum iOS deployment target at 13.0

## License

By contributing, you agree that your code will be licensed under the same [MIT License](LICENSE).
