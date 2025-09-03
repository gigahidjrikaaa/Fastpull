# Contributing to Fastpull

First off, thank you for considering contributing! Your help is appreciated.

## How to Contribute

### Reporting Bugs

- Use the GitHub issue tracker to report bugs.
- Please include the output of `fastpull doctor` and `fastpull version`.
- Describe the steps to reproduce the issue.

### Suggesting Enhancements

- Use the GitHub issue tracker to suggest new features.
- Explain the use case and why the enhancement would be valuable.

### Pull Requests

1.  Fork the repository and create your branch from `main`.
2.  Make your changes. Adhere to the coding style.
3.  Ensure your code is well-commented, especially in complex areas.
4.  Update the `README.md` or other documentation if your changes affect it.
5.  Add your change to the `CHANGELOG.md` under the "Unreleased" section.

## Development Setup

You'll need `shellcheck`, `shfmt`, and `bats` for linting and testing.

You can install them on a Debian-based system with:
```bash
sudo ./scripts/dev/setup-dev.sh
```

### Linting

We use `shellcheck` for static analysis and `shfmt` for formatting.

```bash
# Run shellcheck
shellcheck bin/fastpull

# Check formatting with shfmt
shfmt -i 2 -d .
```
The CI will fail if there are linting errors.

### Testing

We use `bats` for testing.

```bash
# Run all tests
bats tests
```

## Commit Message Convention

Please follow a conventional commit message format.

- `feat`: A new feature.
- `fix`: A bug fix.
- `docs`: Documentation only changes.
- `style`: Changes that do not affect the meaning of the code (white-space, formatting, etc).
- `refactor`: A code change that neither fixes a bug nor adds a feature.
- `test`: Adding missing tests or correcting existing tests.
- `chore`: Changes to the build process or auxiliary tools.

Example: `feat: add --json output to list command`
