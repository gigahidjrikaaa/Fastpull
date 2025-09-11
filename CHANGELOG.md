# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- TBD

## [0.2.1] - 2025-09-11

### Added
- Minimal safe `upgrade` command with backup, checksum (optional), and service restart.
- Environment variable reference in README.
- Issue templates for bugs and feature requests.

### Changed
- Robust runner version resolution and single API call pattern.
- Integrity verification for runner archive via `FASTPULL_RUNNER_SHA256`.
- `list` formatting and service detection improved; added `jq` dep check.
- `status` logs: try sudo on failure.
# Changelog
- Author metadata and docs polish.

## [0.2.0] - 2025-09-11

### Added
- Initial release of `fastpull`.
- `setup` command for interactive runner installation.
- `list`, `status`, `uninstall`, `destroy`, `doctor` commands.
- Support for `docker`, `systemd`, and `custom` deployment modes.
- Non-interactive setup via environment variables.
- `.deb` packaging for easy installation.
- CI/CD pipeline for linting, testing, and releasing.
- Documentation (`README`, `CONTRIBUTING`, `SECURITY`, `ROADMAP`).
- Workflow templates for deployments.
