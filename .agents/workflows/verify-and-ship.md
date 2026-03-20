---
description: Precise verification of build, project generation, and linting standards before task completion.
---
// turbo-all
1. Regenerate the Xcode project to ensure all source file changes are synced.
```bash
xcodegen generate
```
2. Run a clean build for the watchOS simulator architecture to catch compiler errors early.
```bash
xcodebuild clean build -scheme IronFive -destination 'platform=watchOS Simulator,name=Apple Watch Series 11 (46mm)' CODE_SIGNING_ALLOWED=NO 2>&1 | xcbeautify
```
3. Run the comprehensive pre-commit suite (SwiftLint, whitespace, etc.).
```bash
pre-commit run --all-files
```
4. Review AGENTS.md to ensure "One Glance" and "No-Scroll" architecture rules were followed.
5. Update walkthrough.md and mark the task as complete.
