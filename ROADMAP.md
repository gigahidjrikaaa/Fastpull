# Fastpull Roadmap

This document outlines potential future features and improvements for Fastpull.

## Core Features

- **Go Rewrite (`fastpull-go`)**: A complete rewrite in Go to produce a truly static binary, removing all shell and utility dependencies (`jq`, `curl`, etc.). This would improve robustness and portability.
- **JSON Output (`--json`)**: Add a `--json` flag to commands like `list` and `status` for easier integration with other tools and scripts.
- **Metrics Opt-in**: Add an optional Prometheus metrics endpoint to the runner service to expose job counts, durations, and statuses.
- **Offline/Air-gapped Bundle**: Create a command to bundle the `fastpull` script, the runner tarball, and any other assets into a single archive for installation on machines without internet access.

## Enhancements

- **`upgrade` command implementation**: Fully implement the `fastpull upgrade [<slug>]` command to safely update runner binaries.
- **Cloud-init Expansion**: Add more detailed and tested cloud-init snippets for various cloud providers.
- **More Stack Templates**: Add more boilerplate templates for popular frameworks (e.g., Django, Express, etc.).
- **Improved `doctor` command**: Add more checks to the `doctor` command, such as checking for clock skew and disk space.
