# AGENTS

This repository follows a default template for top-notch iOS engineering.
These instructions apply to all files unless overridden by a nested `AGENTS.md`.

## General Principles
- Code must be written in Swift using modern iOS development practices.
- Aim for clear, concise code with comments where necessary.
- Keep functions small and focused on a single responsibility.
- Practise safe, modern Swift 6 concurrency.
- Target iOS 18, but make use of iOS 26's new APIs and Liquid Glass where beneficial.
- Do not run `swift test` or `swift build` – they will always fail.
- After completing a task, run xcodebuild like this so I see it in my Simulator.
`xcodebuild build -workspace Morsel.xcworkspace -scheme iOS -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
- If the build fails, iterate until it is fixed, do not stop working until we have a working build.

## Code Style
- Indentation uses **two spaces**. No tabs.
- Keep line length under **120 characters** when possible.
- Prefer structs and value types where appropriate.
- Group related extensions together using `// MARK:` comments.
- Place private methods and variables in a `private` extension on the enclosing type whenever possible.

## Commit Messages
- Write informative commit messages in present tense (e.g., "Add loading state to StatsView").
- Include a short description followed by an optional blank line and more details.

## Pull Requests
- Summarize any user-facing or developer-facing changes.
- Mention testing performed, even if minimal.
- Run any available linters. If none are present, at least build the project to ensure there are no syntax errors.
- Your runners won't work with xcodebuild so you can't run that locally – only via CI workflows on Github Actions.