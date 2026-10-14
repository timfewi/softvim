# Project policy

- Keep credentials, personal data and runtime state outside Git.
- Preserve existing user changes. Write documentation and CLI text in English.
- Run `project-check fast` after meaningful changes and `project-check full`
  before handoff. Checks are declared in `.project-checks.json` and never run on
  their own.
- Missing tools or offline dependencies are environment blockers, not failures.
  Enter the pinned toolchain with `nix develop path:.` (or reload direnv).
  `just lint --json` and `just verify --json` forward options to project-check.
- Task-scoped staging is authorized. After review and required checks, commit
  the task changes and push to the current branch's existing upstream. Preserve
  unrelated work.
- Deployment, activation, installation, releases, visibility changes and history
  rewrites require separate authorization.
