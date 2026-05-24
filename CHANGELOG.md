# Changelog

## [0.1.1] - 2026-05-24

### Added

- Upgraded `verify.ps1` into a project-level audit entry for Feishu adapter optimization.
- Added `-Full` audit mode to run the Hermes Feishu-related pytest suite before packaging or upload.
- Added checks for native image routing, local path leakage, duplicated download notices, Markdown `post` conversion, tool progress count, gateway lifecycle notices, Feishu home channel, and runtime footer state.
- Added README, validation, status, tests, and manifest notes for the new audit gate.
- Added `docs/acceptance-matrix.md` to separate adapter optimization, display enhancement, and localization responsibilities.
- Added `docs/preflight.md` so capability map, risk matrix, and acceptance fixtures are defined before future code changes.
- Added self-check and lessons-learned requirements to prevent "fixed and done" handoffs.
- Added `examples/manual-feishu-cases.md` for real Feishu-side manual acceptance scenarios.
- Added `tests/feishu_acceptance_harness.py` as an independent fixture-based behavior check, so verification is not only source-marker self-review.
- Added a `/retry` media-history behavior fixture to prevent fake attachment retry success.
- Added an audio/video resource fixture so Feishu media resources are not only covered by source markers.
- Split unverified cross-platform continuity claims into the new local `hermes-continuity` research draft.
- Added a reverse-audit gate for Feishu `post` update payload shape so `message.update` does not fall back to plain text because of missing `title` or empty `text` elements.

### Verified

- `tests/feishu_acceptance_harness.py`: 6 passed, 0 failed.
- `verify.ps1`: 36 passed, 0 failed on the current local Hermes installation.
- `verify.ps1 -Full`: 37 passed, 0 failed.
- Hermes Feishu-related pytest suite: 276 passed, 4 warnings.

## [0.1.0] - 2026-05-23

### Added

- Added local project structure.
- Added `manifest.json`.
- Added `install.ps1` for source backup, verification, and rollback.
- Added `verify.ps1` for current Hermes adapter optimization markers.
- Added source file list for future patch extraction.
- Added `patches/source.replacements.json` and source replacement application.
- Added install, upgrade, troubleshooting, validation, and status docs.

### Verified

- `verify.ps1`: 9 passed, 0 failed on the current local Hermes installation.
- `install.ps1`: created source/config backup, checked/applied source replacements, and passed verification.
