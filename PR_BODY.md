Summary
- Update CI workflow files and documentation; remove committed Ninja build outputs to keep the repository clean and reproducible.

Changes
- Workflows: updated
  - .github/workflows/build.yml
  - .github/workflows/new static.yml
  - .github/workflows/summary.yml
- Docs: updated
  - BUILD_FIXES.md
  - INSTALL_DOCKER.md
- Build artifacts: removed
  - Deleted various generated files under build-ninja/ including executable and intermediate CMake/Ninja artifacts.

Impact
- CI: workflow edits will be applied on next runs.
- Local builds: unaffected; only generated artifacts were removed from version control.
- Repository hygiene: reduces noise and potential conflicts from generated files.

Context
- Resolved local Git commit editor error caused by VS Code Git extension pipe hook by unsetting GIT_EDITOR in terminal sessions and ensuring core.editor uses "code --wait".

Checklist
- [x] No source files removed unintentionally
- [x] CI config validates (YAML syntax)
- [x] Docs build locally (if applicable)
- [x] No secrets or tokens present in workflow changes
