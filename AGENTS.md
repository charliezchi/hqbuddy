# Agent Instructions

## Git Workflow

- **DO NOT push to remote without explicit user confirmation.** Only commit to local; wait for user to say "push" or equivalent before running `git push`.

## Interaction Rules

- **DO NOT guess user intent.** Ask clarifying questions before acting when instructions are ambiguous, underspecified, or could be interpreted in multiple ways.

## Documentation

- **Keep README.md up to date.** Whenever functionality, CLI interface, or behavior changes, update the corresponding sections in README.md promptly.
- **Version single source of truth is `hqbuddy/__init__.py` 的 `__version__`.** Bump it on every behavior-changing batch, and keep README.md『## 当前版本』一致。`hooks/pre-commit`（版本化，`git config core.hooksPath hooks` 启用）会在两者不一致时拒绝提交；被拒时把 README 版本行改成 `__version__` 的值即可，不要用 `--no-verify` 绕过。
