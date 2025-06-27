# Changelog

All notable changes to this repository will be documented in this file.

<!-- The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). -->

## [Unreleased]

### Added

- Complete rewrite as PowerShell module
- Pipeline processing support
- Advanced error handling
- Progress tracking
- Comprehensive logging
- Automated dependency installation script (`Build/Install-Dependencies.ps1`)
- Comprehensive Pester tests for all functions
- Detailed usage examples in `Examples/Basic-Usage.ps1`
- Contribution guidelines in `CONTRIBUTING.md`

### Changed

- Improved parameter validation
- Better prerequisite checking
- Enhanced subtitle optimization
- Replaced `UseOldWhisper` switch with `WhisperImplementation` parameter for clearer distinction between Whisper versions
- Updated `README.md` with a Feature Matrix and `API-Reference.md` with detailed parameter documentation

### Fixed

- Thread count calculation
- File path handling
- Memory management

[Unreleased]: https://github.com/kjanat/svg-converter-action/compare/v1.0.7...HEAD
[Initial commit]: https://github.com/kjanat/WhisperSubtitle/commit/13e7434

<!--
markdownlint-configure-file {
  "no-duplicate-heading": false
}
-->
