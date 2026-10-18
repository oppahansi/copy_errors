# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-10-18

### Added

- **Copy Errors**, **Copy Warnings** and **Copy All** buttons in the toolbar of the debugger's
  Errors tab. They copy the errors, the warnings, or both, each with its source, C++ error and stack
  trace, to the clipboard as plain text.
- Each copied entry starts with `E` (error) or `W` (warning), like the editor's own
  **Copy Error** menu entry.
- The buttons in every debugger session, including sessions added later (several running instances).
- A warning in the Output panel, instead of a crash, when the editor's layout isn't recognised.

[Unreleased]: https://github.com/oppahansi/copy_errors/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/oppahansi/copy_errors/releases/tag/v1.0.0
