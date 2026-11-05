# Agent Instructions

## Git Workflow

- **DO NOT push to remote without explicit user confirmation.** Only commit to local; wait for user to say "push" or equivalent before running `git push`.

## Interaction Rules

- **DO NOT guess user intent.** Ask clarifying questions before acting when instructions are ambiguous, underspecified, or could be interpreted in multiple ways.

## Documentation

- **Keep README.md up to date.** Whenever functionality, CLI interface, or behavior changes, update the corresponding sections in README.md promptly.
- **Version single source of truth is `hqbuddy/__init__.py` 的 `__version__`.** Bump it on every behavior-changing batch, and keep README.md『## 当前版本』一致。`hooks/pre-commit`（版本化，`git config core.hooksPath hooks` 启用）会在两者不一致时拒绝提交；被拒时把 README 版本行改成 `__version__` 的值即可，不要用 `--no-verify` 绕过。

## CLI 输出约定

- **机器 grep 的锚点前缀恒为英文，正文中文**：`Error:` / `Warning:` / `Usage:` / `[FAIL]` / `[WARN]` / `[ ok ]` / `[OK]` / `[FPGA]` / `[skip]` 等固定锚点不翻译；锚点之后的说明文字用中文。这是 agent 解析与中文用户阅读的公共约定，新增/修改错误消息时遵守。
