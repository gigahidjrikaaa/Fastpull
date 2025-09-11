# Security Policy

The security of Fastpull is a top priority. We appreciate your efforts to responsibly disclose your findings.

## Reporting a Vulnerability

If you discover a security vulnerability, please report it to us by creating a **confidential security advisory** on GitHub.

**Please do not report security vulnerabilities through public GitHub issues.**

To create a confidential advisory:
1.  Navigate to the "Security" tab of the repository.
2.  Click on "Report a vulnerability".
3.  Provide a detailed description of the vulnerability and steps to reproduce it.

We will do our best to respond to your report within 48 hours.

## Security Best Practices

- **Runner Tokens**: The GitHub Actions runner registration tokens are short-lived and used only once. `fastpull` never stores them on disk.
- **Least Privilege**: `fastpull` is designed to run with the minimum privileges necessary. For `systemd` deployments, it creates a specific `sudoers` file that only grants permission to restart a single service.
- **Runner Scope**: Always configure your runners in the narrowest possible scope. If a runner is for a single repository, do not configure it at the organization level.
- **Public Repositories**: **Do not use self-hosted runners on public repositories.** Malicious code in a pull request could execute on your runner and compromise your machine.
