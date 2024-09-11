# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2024-09-10
### Added
- Implemented a snapshot viewer LiveView.
  - Integrated [PDF.js](https://github.com/mozilla/pdf.js) for viewing archived PDFs.
- Implemented REST API for adding snapshots, later to be used with an Apple Shortcut workflow.

### Changed
- Rewrote the snapshot list view to use infinite scrolling
- Migrated archiver supervised GenServers to [Oban](https://github.com/oban-bg/oban).
- Updated CSS styling for better readability.

## [0.2.0] - 2024-07-21
### Added
- snapshot search using OpenAI's `text-embedding-3-small` model.

## [0.1.0] - 2024-07-21

### Added
- Basic CRUD actions for creating snapshots
- Dedicated Tasks for capturing PDF, HTML, and screenshots for a new snapshot.
- Dockerfile for fly.io


[unreleased]: https://github.com/errantsky/phoenix_vault/compare/v0.3.0...HEAD
[0.1.0]: https://github.com/errantsky/phoenix_vault/releases/tag/0.1.0
[0.2.0]: https://github.com/errantsky/phoenix_vault/releases/tag/0.2.0
[0.3.0]: https://github.com/errantsky/phoenix_vault/releases/tag/0.2.0
