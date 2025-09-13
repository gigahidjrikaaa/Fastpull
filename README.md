<!-- LOGO (optional) -->
<p align="center">
  <!-- <a href="https://github.com/gigahidjrikaaa/Fastpull">
    <img src="path/to/your/logo.png" alt="Logo" width="80" height="80">
  </a> -->
</p>

<h1 align="center">Fastpull</h1>

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
- **Simple Management**: Easy commands to list, check status, and destroy runners.

--- 

## 20-Second Demo

This is a storyboard for a terminal recording that shows the end-to-end flow.

1.  **Install `fastpull` with a single curl command.**
    ```sh
    curl -sSL https://raw.githubusercontent.com/gigahidjrikaaa/Fastpull/main/scripts/curl-install.sh | bash

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

## How It Works (Diagram)

```
You (git push)
    |
    v
GitHub (repo)
    |
    | triggers workflow on push
    v
Self-hosted Runner on your VM  <--- installed by: sudo fastpull setup
    |
    | checks out your repo
    | rsyncs files to /opt/apps/<slug>
    v
Docker Compose (or systemd/custom)
    |
    v
Your app is rebuilt/restarted and is live
```

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

### New To This? Follow These Steps

Copy/paste the commands below on your VM. Wherever you see something in ALL_CAPS, replace it with your values.

1) Get a GitHub Actions registration token
- Repo scope: GitHub > Your repo > Settings > Actions > Runners > New self-hosted runner > Copy the token
- Org scope: GitHub > Your org > Settings > Actions > Runners > New runner > Copy the token

2) Install the CLI on the VM
```bash
curl -sSL https://raw.githubusercontent.com/gigahidjrikaaa/Fastpull/main/scripts/curl-install.sh | bash
```

3) Run setup (interactive)
```bash
sudo fastpull setup
```
Example answers you can use at the prompts:
- Scope: repo
- URL: https://github.com/YOUR_USER/YOUR_REPO
- App name: my-app (fastpull will make this a slug like `my-app`)
- Deployment mode: docker
- Token: paste the token you copied from GitHub

4) Add the workflow to your repo
- After setup, fastpull prints the path to a sample workflow like:
  `/opt/apps/my-app/SAMPLE_deploy.yml`
- Copy its contents into your project at `.github/workflows/deploy.yml`.
- Replace `APP_SLUG` with your slug (e.g., `my-app`).

5) Push code to deploy
```bash
git add -A && git commit -m "deploy" && git push
```
- Your runner picks up the job and deploys your app (for Docker: `docker compose up -d --build`).

6) Check runner and logs
```bash
fastpull list
fastpull status my-app
```

If you get stuck, see the Troubleshooting section below.

### One-Step Setup Inside Your Repo

If you’ve already cloned your app repo onto the VM, run setup from inside it:

```bash
cd /path/to/your/repo
sudo fastpull setup
```

What it does:
- Detects your GitHub repo from `git remote origin`
- Asks how to trigger deployments (on push, on a schedule, or both)
- Creates `.github/workflows/deploy.yml` in your repo (you can choose to auto-commit)
- Configures the runner on the VM using your repo URL

Tip: Provide a PAT via `FASTPULL_GH_PAT` (or `GITHUB_TOKEN`) so fastpull can auto‑generate the short‑lived runner registration token for you.

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

### Sample Workflow (Docker Compose)

Copy this into `.github/workflows/deploy.yml` and replace `APP_SLUG` with your slug (for example, `my-app`). The labels in `runs-on` must match the labels you set during `fastpull setup`.

```yaml
# .github/workflows/deploy.yml
name: Deploy to VM

on:
  push:
    branches:
      - main # Or your deployment branch

jobs:
  deploy:
    name: Deploy
    # IMPORTANT: Replace these labels with the ones you configured during setup.
    runs-on: [self-hosted, linux, x64, APP_SLUG] # e.g., my-app

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Deploy application
        run: |
          set -e
          # This path is configured during 'fastpull setup'
          APP_DIR="/opt/apps/APP_SLUG"

          echo "--> Syncing application files to ${APP_DIR}"
          # Use rsync to efficiently update the application directory
          rsync -av --delete --exclude='.git/' ./ "${APP_DIR}/"

          cd "${APP_DIR}"

          echo "--> Pulling latest images"
          docker compose pull || true

          echo "--> Building and starting containers"
          # --remove-orphans cleans up containers for services that no longer exist
          docker compose up -d --build --remove-orphans

          echo "--> Deployment complete!"
```

## Commands

| Command                | Description                                                  |
| ---------------------- | ------------------------------------------------------------ |
| `fastpull setup`       | Interactively set up a new self-hosted runner.               |
| `fastpull list`        | List all runners managed by fastpull.                        |
| `fastpull status <slug>` | Show the status of a specific runner.                        |
| `fastpull upgrade [<slug>]` | Upgrade one or all runners to the latest runner version.    |
| `fastpull uninstall <slug>`| Uninstall a runner service (keeps app data).                 |
| `fastpull destroy <slug>`| Aggressively remove a runner and all its files.              |
| `fastpull doctor`      | Run diagnostics to check system compatibility.               |
| `fastpull help`        | Show the help message.                                       |
| `fastpull version`     | Show the version of fastpull.                                |

See `docs/ROADMAP.md` for planned improvements.

Tip: Use `fastpull --help` for top-level help, or `fastpull <command> --help` for command-specific usage.

No color output (for copy/paste or logs):
- Add `--no-color` after `fastpull` or set `FASTPULL_COLOR=never`.
- Example: `fastpull --no-color help`

## Where Things Go (after setup)

- Runners: `/opt/gha-runners/<slug>` (runner files and service scripts)
- App files: `/opt/apps/<slug>` (what your workflow deploys to)
- Service: a systemd unit named like `actions.runner.<something with your slug>.service`

## Uninstall / Cleanup

- Remove a runner but keep app data:
  ```bash
  sudo fastpull uninstall <slug>
  ```
- Remove everything (runner + files):
  ```bash
  sudo fastpull destroy <slug>
  ```

## Environment Variables

Fastpull supports non-interactive setup and customization via environment variables:

- `GDR_SCOPE`: repo or org. Default: `repo`.
- `GDR_URL`: Repository or organization URL (e.g., `https://github.com/owner/repo`).
- `GDR_APP_NAME`: App display name used to derive the slug. Default: hostname.
- `GDR_SLUG`: Override the derived slug. Default: slugified `GDR_APP_NAME`.
- `GDR_RUNNER_LABELS`: Comma-separated labels (e.g., `self-hosted,linux,x64,my-app`).
- `GDR_RUNNER_BASE`: Base dir for runners. Default: `/opt/gha-runners`.
- `GDR_APP_BASE`: Base dir for application files. Default: `/opt/apps`.
- `GDR_DEPLOY_MODE`: `docker`, `systemd`, or `custom`. Default: `docker`.
- `GDR_SYSTEMD_SERVICE`: Service name to restart (systemd mode). Default: `<slug>.service`.
- `GDR_TOKEN`: GitHub Actions runner registration token.
- `GDR_INSTALL_DOCKER`: `yes`/`no` to auto-install Docker if missing. Default: `yes`.
- `FASTPULL_NONINTERACTIVE`: `yes` to suppress prompts and use defaults/env.
- `FASTPULL_EPHEMERAL`: `yes` to request ephemeral runner mode if supported.
- `FASTPULL_COLOR`: `auto` (default) or `never` to disable colors.
- `FASTPULL_VERSION_OVERRIDE`: Override runner version (e.g., `2.300.0`).
- `FASTPULL_RUNNER_SHA256`: SHA256 to verify the downloaded runner archive.

PAT-based token generation (optional):
- `FASTPULL_GH_PAT`: A GitHub Personal Access Token used to automatically create a short‑lived runner registration token via the GitHub API.
- `GITHUB_TOKEN`: Also recognized as a source for the PAT if `FASTPULL_GH_PAT` is not set.
- `FASTPULL_USE_PAT`: `yes`/`no` to enable using the PAT automatically. Default: `yes` if a PAT is present, otherwise `no`.

PAT permissions: the PAT must be allowed to create self‑hosted runner registration tokens.
- Fine‑grained token: grant “Self‑hosted runners: Read and write” on the repository (and on the organization for org‑level).
- Classic token: repo access for private repos (or public_repo for public), and organization scope that allows Actions runner management for org‑level.

These are demonstrated in `docs/cloud-init/*.yml` for various cloud providers.

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

Common pitfalls
- Labels don’t match: Ensure the labels in `runs-on: [...]` include the slug label you set during setup (e.g., `my-app`).
- Missing deps: The VM needs `curl`, `jq`, and `tar`. Run `sudo apt-get update && sudo apt-get install -y curl jq tar`.
- No journal logs: `fastpull status <slug>` may need `sudo` to read logs; it will try automatically.
- Docker perms: If Docker was installed, a re-login or reboot might be required for the runner user to join the `docker` group.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit a pull request, run tests, and lint your code.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
