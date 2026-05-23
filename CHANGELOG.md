# Changelog

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
