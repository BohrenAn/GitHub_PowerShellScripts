# Global Copilot Instructions

These instructions apply across all projects and repositories.

## Shell and Terminal

- This is a Windows system.
- Use PowerShell for shell and terminal operations.
- Do not use Bash unless the task or script is explicitly POSIX/bash-specific.

## PowerShell Style

Apply these rules whenever creating or modifying PowerShell `.ps1` or `.psm1` files.

Use FunctionName that clearly describes its purpose.

Add Synopses and Examples for functions whenever possible.
Use PascalCase for function names.

### Formatting

- Use 2 spaces for indentation.
- Keep every line at or under 120 characters.
- Never use the backtick (`) as a line-continuation character.

### Line Continuation

When a statement would exceed 120 characters, use one of these techniques:

- Splatting.
- A pipeline with `|` at the end of the line.
- Natural PowerShell continuation inside parentheses, arrays, hashtables, or other open constructs.
- String concatenation.
- `@(...) -join ' '` for long messages.

Never use a backtick for line continuation.

## Git Workflow When Editing Files

When editing a file that is tracked in a Git repository:

1. Before editing, check `git status` for the specific file.
2. Verify that the file is not already in an unexpected modified state.
3. Do not overwrite or discard existing uncommitted work.
4. Make the requested edit.
5. Stage only the file that was edited using `git add <file>`.
6. Do not use broad staging commands such as `git add -A` or `git add .`.
7. Draft a concise and relevant commit message describing the change.
8. Present the staged change and proposed commit message to the user.
9. Ask whether the user wants to commit the change.

Never create a Git commit automatically. Only commit when the user explicitly requests or approves it.