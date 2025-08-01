# AGENTS

This repository follows a default template for top-notch iOS engineering. These instructions apply to all files unless overridden by a nested `AGENTS.md`.

## General Principles
- Code must be written in Swift using modern iOS development practices.
- Aim for clear, concise code with comments where necessary.
- Keep functions small and focused on a single responsibility.
- Use `@MainActor` when performing UI-related tasks.
- Target **iOS 26** and make use of its APIs where beneficial.

## Code Style
- Indentation uses **two spaces**. No tabs.
- Keep line length under **120 characters** when possible.
- Prefer structs and value types where appropriate.
- Group related extensions together using `// MARK:` comments.

## Commit Messages
- Write informative commit messages in present tense (e.g., "Add loading state to StatsView").
- Include a short description followed by an optional blank line and more details.

## Pull Requests
- Summarize any user-facing or developer-facing changes.
- Mention testing performed, even if minimal.
- Run any available linters. If none are present, at least build the project to ensure there are no syntax errors.


