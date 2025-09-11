<!-- LOGO (optional) -->
<p align="center">
  <!-- <a href="https://github.com/gigahidjrikaaa/Fastpull">
    <img src="path/to/your/logo.png" alt="Logo" width="80" height="80">
  </a> -->
</p>

<h1 align="center">Fastpull 🚀</h1>

<p align="center">
  <strong>Fast, zero-dependency push-to-deploy for plain VMs via GitHub Actions self-hosted runners.</strong>
  <br />
  <br />
  <a href="https://github.com/gigahidjrikaaa/Fastpull/issues/new?assignees=&labels=bug&template=bug_report.md&title=">Report a Bug</a>
  ·
  <a href="https://github.com/gigahidjrikaaa/Fastpull/issues/new?assignees=&labels=enhancement&template=feature_request.md&title=">Request a Feature</a>
  ·
  <a href="https://github.com/gigahidjrikaaa/Fastpull/blob/main/CHANGELOG.md">View Changelog</a>
</p>

<p align="center">
  <!-- Badges -->
  <a href="https://github.com/gigahidjrikaaa/Fastpull/actions/workflows/ci.yml">
    <img src="https://github.com/gigahidjrikaaa/Fastpull/actions/workflows/ci.yml/badge.svg" alt="CI Status">
  </a>
  <a href="https://github.com/gigahidjrikaaa/Fastpull/releases/latest">
    <img src="https://img.shields.io/github/v/release/gigahidjrikaaa/Fastpull" alt="Latest Release">
  </a>
  <a href="https://github.com/gigahidjrikaaa/Fastpull/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/gigahidjrikaaa/Fastpull" alt="License">
  </a>
  <a href="https://github.com/gigahidjrikaaa/Fastpull">
    <img src="https://img.shields.io/github/repo-size/gigahidjrikaaa/Fastpull" alt="Repo Size">
  </a>
  <a href="https://www.gnu.org/software/bash/">
    <img src="https://img.shields.io/badge/Built%20with-Shell%20Script-1f425f.svg" alt="Built with Shell Script">
  </a>
</p>

---

Fastpull is a single-file Bash CLI that automates the setup and management of GitHub Actions self-hosted runners on your Debian or Ubuntu VMs. It's designed to be the simplest way to enable a secure "push-to-deploy" workflow for your applications without complex orchestration tools.

- **Zero Runtime Dependencies**: Pure Bash script. No need for Node, Python, or Ruby.
- **Secure by Default**: Uses short-lived registration tokens, creates minimal sudoers permissions only when needed, and never logs secrets.
- **Idempotent Setup**: Rerunning `fastpull setup` is safe and predictable.
- **Flexible Deployments**: Natively supports Docker Compose, systemd services, or your own custom deployment scripts.
- **Simple Management**: Easy commands to list, check status, upgrade, and destroy runners.

--- 

## 20-Second Demo

This is a storyboard for a terminal recording that shows the end-to-end flow.

1.  **Install `fastpull` with a single curl command.**
    ```sh
    curl -sSL https://.../install.sh | bash
    ```
2.  **Run the interactive setup.**
    ```bash
    sudo fastpull setup
    # Answer prompts for repo URL, deploy mode (Docker), etc.
    ```
3.  **`fastpull` downloads the runner, configures it, and starts the service.**
4.  **Copy the generated sample workflow into your project.**
    ```bash
    cat /opt/apps/my-app/SAMPLE_deploy.yml
    # (Copy content to .github/workflows/deploy.yml)
    ```
5.  **`git push` your code.**
6.  **The runner picks up the job, pulls the code, and runs `docker compose up -d --build`.** Your app is live!

*(A script to generate this GIF using `vhs` is available at `scripts/record-demo.sh`)*

--- 

## Quickstart

### Prerequisites

- A VM running **Ubuntu (20.04+)** or **Debian (10+)**.
- `sudo` or root access.
- Outbound internet access to `github.com`.

### Installation

Install the `fastpull` CLI to `/usr/local/bin/fastpull` with one command:

```bash
curl -sSL https://raw.githubusercontent.com/gigahidjrikaaa/Fastpull/main/scripts/curl-install.sh | bash
```
*(Remember to replace `gigahidjrikaaa/Fastpull` with your fork's path if you're not using the main repo.)*

### Setup Your First Runner

1.  **Generate a registration token** in your GitHub repository or organization settings:
    - **For a repository**: Go to `Settings` > `Actions` > `Runners` > `New self-hosted runner`.
    - **For an organization**: Go to `Settings` > `Actions` > `Runners` > `New runner`.
    - Copy the token (it looks like `A1B2C...`). You only need the token, not the other commands.

2.  **Run the interactive setup** on your VM:
    ```bash
    sudo fastpull setup
    ```

3.  **Follow the prompts**. You'll be asked for:
    - **Scope**: `repo` or `org`.
    - **URL**: The URL of your repository or organization.
    - **Deployment Mode**: `docker`, `systemd`, or `custom`.
    - **Token**: The registration token you just generated.

`fastpull` will handle the rest: downloading the runner, configuring it as a service, and setting up necessary permissions.

4.  **Add the workflow to your repository**. After setup, `fastpull` will print the path to a sample workflow file (e.g., `/opt/apps/my-app/SAMPLE_deploy.yml`). Copy this file into your project at `.github/workflows/deploy.yml`, customize it if needed, and commit it.

5.  **Push your changes**, and watch your deployment happen automatically!

## Commands

| Command                | Description                                                  |
| ---------------------- | ------------------------------------------------------------ |
| `fastpull setup`       | Interactively set up a new self-hosted runner.               |
| `fastpull list`        | List all runners managed by fastpull.                        |
| `fastpull status <slug>` | Show the status of a specific runner.                        |
| `fastpull uninstall <slug>`| Uninstall a runner service (keeps app data).                 |
| `fastpull destroy <slug>`| Aggressively remove a runner and all its files.              |
| `fastpull doctor`      | Run diagnostics to check system compatibility.               |
| `fastpull help`        | Show the help message.                                       |

## Security

- **Runner Tokens**: `fastpull` uses `read -s` to accept the GitHub registration token, so it is never displayed on screen or stored in your shell history. The token is used once for registration and is not stored by `fastpull`.
- **Sudoers**: When using `systemd` mode, `fastpull` creates a very specific sudoers file (e.g., `/etc/sudoers.d/gha-runner-my-app`) that only allows the runner's user to restart a single, specified service. This is the principle of least privilege in action.
- **Runner Scope**: Always create runners with the narrowest scope possible. If a runner is for a single repository, create it at the repository level, not the organization level. Use labels to ensure jobs only run on the intended machines.

## Troubleshooting

| Error                                       | Fix                                                                                                                            |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `dependency 'jq' is not installed`          | Run `sudo apt-get update && sudo apt-get install -y jq`.                                                                       |
| `Runner configuration failed`               | Your registration token may be incorrect or expired. Generate a new one and try again.                                         |
| `docker: command not found` (in deploy job) | Ensure Docker is installed on the VM. `fastpull setup` offers to do this, or you can run `curl -fsSL https://get.docker.com | sh`. |
| Job is stuck on "Waiting for a runner"      | Check that the labels in your workflow file (`runs-on: [...]`) exactly match the labels you configured for the runner.           |

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit a pull request, run tests, and lint your code.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.