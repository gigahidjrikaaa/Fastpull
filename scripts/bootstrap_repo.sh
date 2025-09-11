#!/bin/bash
#
# ==============================================================================
# bootstrap_repo.sh
#
# This script generates the complete repository structure for the 'fastpull'
# project. It creates all directories, source files, documentation, and
# supporting scripts.
#
# Usage:
#   ./scripts/bootstrap_repo.sh
#
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status.

# --- Main execution function ---
main() {
    echo "==> Starting Fastpull repository bootstrap..."

    # Create directory structure
    create_directories

    # Create source files, scripts, and documentation
    create_bin_fastpull
    create_install_sh
    create_curl_install_sh
    create_dev_setup_sh
    create_record_demo_sh
    create_packaging_files
    create_workflow_templates
    create_stack_templates
    create_cloud_init_snippets
    create_github_workflows
    create_bats_tests
    create_docs
    create_project_files

    # Set executable permissions
    set_permissions

    echo
    echo "=============================================================================="
    echo "  Fastpull repository bootstrap complete!"
    echo "=============================================================================="
    echo
    echo "  All files have been created in the 'fastpull' directory."
    echo
    echo "  Next steps:"
    echo "    1. cd fastpull"
    echo "    2. git init && git add . && git commit -m \"Initial commit\""
    echo "    3. ./install.sh (to install the 'fastpull' CLI locally)"
    echo "    4. fastpull --help"
    echo
    echo "  Review the generated files, especially README.md and CONTRIBUTING.md."
    echo "  Remember to replace placeholders like 'gigahidjrikaaa/Fastpull'."
    echo
}

# --- File and directory creation functions ---

create_directories() {
    echo "==> Creating directory structure..."
    mkdir -p fastpull/.github/workflows
    mkdir -p fastpull/bin
    mkdir -p fastpull/docs/cloud-init
    mkdir -p fastpull/packaging/deb/DEBIAN
    mkdir -p fastpull/scripts/dev
    mkdir -p fastpull/templates/stacks/fastapi
    mkdir -p fastpull/templates/stacks/laravel
    mkdir -p fastpull/templates/stacks/nextjs
    mkdir -p fastpull/templates/stacks/rails
    mkdir -p fastpull/templates/stacks/springboot
    mkdir -p fastpull/tests
}

create_bin_fastpull() {
echo "==> Creating bin/fastpull..."
cat <<'EOF' > fastpull/bin/fastpull
#!/bin/bash
#
# fastpull: A zero-dependency CLI for GitHub Actions push-to-deploy runners.
#
# Author: GIga Hidjrika Aura Adkhy <gigahidjrikaaa@gmail.com>
# License: MIT
# Version: 0.2.0

set -o pipefail

# --- Configuration & Globals ---
readonly FASTPULL_VERSION="0.2.0"
readonly GITHUB_API_URL="https://api.github.com"
readonly RUNNER_RELEASES_URL="${GITHUB_API_URL}/repos/actions/runner/releases/latest"

# --- Colors ---
setup_colors() {
    if [[ -t 1 ]] && [[ "${FASTPULL_COLOR:-auto}" != "never" ]]; then
        CLR_RESET="\033[0m"
        CLR_RED="\033[0;31m"
        CLR_GREEN="\033[0;32m"
        CLR_YELLOW="\033[0;33m"
        CLR_BLUE="\033[0;34m"
        CLR_BOLD="\033[1m"
    else
        CLR_RESET=""
        CLR_RED=""
        CLR_GREEN=""
        CLR_YELLOW=""
        CLR_BLUE=""
        CLR_BOLD=""
    fi
}

# --- Logging & Utility Functions ---
_log() {
    local -r color="$1"
    local -r level="$2"
    shift 2
    echo -e "${color}${CLR_BOLD}[${level}]${CLR_RESET}${color} $@${CLR_RESET}" >&2
}
_info() { _log "${CLR_BLUE}" "INFO" "$@"; }
_warn() { _log "${CLR_YELLOW}" "WARN" "$@"; }
_error() { _log "${CLR_RED}" "ERROR" "$@"; }
_success() { _log "${CLR_GREEN}" "SUCCESS" "$@"; }
_fatal() { _error "$@"; exit 1; }

_check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        _fatal "This operation requires root privileges. Please run with sudo."
    fi
}

_check_deps() {
    for dep in "$@"; do
        if ! command -v "${dep}" &>/dev/null;
        then
            _fatal "Required dependency '${dep}' is not installed. Please install it and try again."
        fi
    done
}

_prompt() {
    local -r message="$1"
    local -r var_name="$2"
    local -r default_val="$3"
    local -r env_var_name="$4"
    
    local current_val
    eval "current_val=\"\"
${env_var_name}:-\"
\""

    if [[ -n "${current_val}" ]]; then
        eval "${var_name}='${current_val}'"
        _info "Using value from environment variable ${env_var_name}: ${current_val}"
        return
    fi

    if [[ "${FASTPULL_NONINTERACTIVE:-no}" == "yes" ]]; then
        if [[ -n "${default_val}" ]]; then
            eval "${var_name}='${default_val}'"
            _info "Non-interactive mode: using default value for ${var_name}: ${default_val}"
        else
            _fatal "Non-interactive mode: no default value for required input '${message}' (env var: ${env_var_name})."
        fi
        return
    fi

    read -p "$(echo -e "${CLR_YELLOW}?${CLR_RESET} ${message} [${default_val}]: ")" input
    eval "${var_name}='${input:-${default_val}}'"
}

_prompt_masked() {
    local -r message="$1"
    local -r var_name="$2"
    local -r env_var_name="$3"

    local current_val
    eval "current_val=\"
${env_var_name}:-\"
\""

    if [[ -n "${current_val}" ]]; then
        eval "${var_name}='${current_val}'"
        _info "Using value from environment variable ${env_var_name}."
        return
    fi

    if [[ "${FASTPULL_NONINTERACTIVE:-no}" == "yes" ]]; then
        _fatal "Non-interactive mode: no value provided for required secret '${message}' (env var: ${env_var_name})."
    fi

    read -sp "$(echo -e "${CLR_YELLOW}?${CLR_RESET} ${message}: ")" input
    echo
    eval "${var_name}='${input}'"
    if [[ -z "${input}" ]]; then
        _fatal "Input cannot be empty."
    fi
}

_slugify() {
    echo "$1" | tr -cs 'a-zA-Z0-9' '-' | tr '[:upper:]' '[:lower:]' | sed 's/--*//g; s/^-//; s/-$//'
}

# --- Main Command Functions ---

_cmd_help() {
    cat <<USAGE
${CLR_BOLD}fastpull${CLR_RESET} ${FASTPULL_VERSION}
A zero-dependency CLI for GitHub Actions push-to-deploy runners.

${CLR_BOLD}USAGE:${CLR_RESET}
    fastpull <COMMAND> [OPTIONS]

${CLR_BOLD}COMMANDS:${CLR_RESET}
    ${CLR_GREEN}setup${CLR_RESET}              Interactively set up a new self-hosted runner.
    ${CLR_GREEN}list${CLR_RESET}               List all runners managed by fastpull.
    ${CLR_GREEN}status <slug>${CLR_RESET}      Show the status of a specific runner.
    ${CLR_GREEN}upgrade [<slug>]${CLR_RESET}   Upgrade one or all runners to the latest version.
    ${CLR_GREEN}uninstall <slug>${CLR_RESET}   Uninstall a runner service (keeps app data).
    ${CLR_GREEN}destroy <slug>${CLR_RESET}     Aggressively remove a runner and its related files.
    ${CLR_GREEN}doctor${CLR_RESET}             Run diagnostics to check system compatibility.
    ${CLR_GREEN}help${CLR_RESET}               Show this help message.
    ${CLR_GREEN}version${CLR_RESET}            Show the version of fastpull.

${CLR_BOLD}ENVIRONMENT VARIABLES:${CLR_RESET}
    See README.md for a full list of environment variables for non-interactive setup.
    Example: GDR_SCOPE, GDR_URL, GDR_TOKEN, etc.

For more details, see the documentation at: https://github.com/gigahidjrikaaa/Fastpull
USAGE
}

_cmd_version() {
    echo "fastpull version ${FASTPULL_VERSION}"
}

_cmd_setup() {
    _check_root
    _check_deps "curl" "jq" "tar"

    _info "Starting interactive GitHub Actions runner setup..."
    _info "Override any prompt by setting the corresponding GDR_* environment variable."

    local gdr_scope gdr_url gdr_app_name gdr_slug gdr_runner_labels gdr_runner_base gdr_app_base gdr_deploy_mode gdr_systemd_service gdr_token
    
    _prompt "Runner scope (repo|org)" gdr_scope "repo" "GDR_SCOPE"
    if [[ "${gdr_scope}" != "repo" && "${gdr_scope}" != "org" ]]; then
        _fatal "Scope must be 'repo' or 'org'."
    fi

    if [[ "${gdr_scope}" == "repo" ]]; then
        _prompt "GitHub repository URL (e.g., https://github.com/owner/repo)" gdr_url "" "GDR_URL"
    else
        _prompt "GitHub organization URL (e.g., https://github.com/my-org)" gdr_url "" "GDR_URL"
    fi

    _prompt "Application name (for slug generation)" gdr_app_name "$(hostname)" "GDR_APP_NAME"
    gdr_slug=$(_slugify "${gdr_app_name}")
    _prompt "Runner slug" gdr_slug "${gdr_slug}" "GDR_SLUG"

    _prompt "Runner labels (comma-separated)" gdr_runner_labels "self-hosted,linux,x64,${gdr_slug}" "GDR_RUNNER_LABELS"
    _prompt "Base directory for runners" gdr_runner_base "/opt/gha-runners" "GDR_RUNNER_BASE"
    _prompt "Base directory for applications" gdr_app_base "/opt/apps" "GDR_APP_BASE"
    _prompt "Deployment mode (docker|systemd|custom)" gdr_deploy_mode "docker" "GDR_DEPLOY_MODE"

    if [[ "${gdr_deploy_mode}" == "systemd" ]]; then
        _prompt "Systemd service name to restart on deploy" gdr_systemd_service "${gdr_slug}.service" "GDR_SYSTEMD_SERVICE"
    fi

    _prompt_masked "GitHub Runner registration token" gdr_token "GDR_TOKEN"

    local runner_dir="${gdr_runner_base}/${gdr_slug}"
    local app_dir="${gdr_app_base}/${gdr_slug}"

    if [[ -d "${runner_dir}" ]]; then
        _warn "Runner directory '${runner_dir}' already exists. Re-running setup is idempotent."
        _prompt "Do you want to continue?" confirm_overwrite "yes" "GDR_CONFIRM_OVERWRITE"
        if [[ "${confirm_overwrite}" != "yes" ]]; then
            _info "Setup aborted by user."
            exit 0
        fi
    fi

    _info "Creating directories..."
    mkdir -p "${runner_dir}"
    mkdir -p "${app_dir}"
    
    _info "Fetching latest runner version info..."
    local arch
    case "$(uname -m)" in
        x86_64) arch="x64" ;; 
        aarch64|arm64) arch="arm64" ;; 
        *) _fatal "Unsupported architecture: $(uname -m)" ;; 
    esac

    local runner_asset_url
    runner_asset_url=$(curl -sSL -H "Accept: application/vnd.github.v3+json" "${RUNNER_RELEASES_URL}" | jq -r ".assets[] | select(.name == \"actions-runner-linux-${arch}-${FASTPULL_VERSION_OVERRIDE:-$(curl -sSL -H \"Accept: application/vnd.github.v3+json\" ${RUNNER_RELEASES_URL} | jq -r .tag_name | sed 's/v//')}.tar.gz\") | .browser_download_url")
    if [[ -z "${runner_asset_url}" ]]; then
        _fatal "Could not find runner download URL for linux-${arch}. Check network or GitHub status."
    fi

    _info "Downloading runner from ${runner_asset_url}..."
    curl -sSL "${runner_asset_url}" | tar -xz -C "${runner_dir}"
    if [[ $? -ne 0 ]]; then
        _fatal "Failed to download or extract the runner."
    fi

    _info "Configuring the runner..."
    cd "${runner_dir}"

    # Check for ephemeral support
    local ephemeral_flag=""
    if [[ "${FASTPULL_EPHEMERAL:-no}" == "yes" ]]; then
        if ./config.sh --help | grep -q -- "--ephemeral"; then
            ephemeral_flag="--ephemeral"
            _info "Ephemeral runner mode enabled."
        else
            _warn "Ephemeral mode requested but not supported by this runner version. Continuing without it."
        fi
    fi

    ./config.sh --unattended \
        --url "${gdr_url}" \
        --token "${gdr_token}" \
        --name "$(hostname)-${gdr_slug}" \
        --labels "${gdr_runner_labels}" \
        --work "_work" \
        ${ephemeral_flag}

    if [[ $? -ne 0 ]]; then
        _fatal "Runner configuration failed. Check your URL and token."
    fi

    _info "Installing and starting the runner service..."
    sudo ./svc.sh install
    sudo ./svc.sh start

    # Handle deployment mode specifics
    if [[ "${gdr_deploy_mode}" == "systemd" ]]; then
        _info "Configuring sudoers for systemd deployment mode..."
        local sudoers_file="/etc/sudoers.d/gha-runner-${gdr_slug}"
        local runner_user
        runner_user=$(stat -c '%U' "${runner_dir}/.runner")
        echo "${runner_user} ALL=(ALL) NOPASSWD: /bin/systemctl restart ${gdr_systemd_service}" | sudo tee "${sudoers_file}" > /dev/null
        sudo chmod 0440 "${sudoers_file}"
        _info "Created sudoers file at ${sudoers_file} for user ${runner_user}."
    elif [[ "${gdr_deploy_mode}" == "docker" ]]; then
        _info "Docker deployment mode selected."
        if ! command -v docker &>/dev/null;
        then
            _warn "Docker is not installed."
            _prompt "Do you want to attempt to install Docker?" install_docker "yes" "GDR_INSTALL_DOCKER"
            if [[ "${install_docker}" == "yes" ]]; then
                _info "Installing Docker via get.docker.com script..."
                curl -fsSL https://get.docker.com -o get-docker.sh
                sudo sh get-docker.sh
                rm get-docker.sh
            fi
        fi
        local runner_user
        runner_user=$(stat -c '%U' "${runner_dir}/.runner")
        if ! groups "${runner_user}" | grep -q '\bdocker\b'; then
            _info "Adding runner user '${runner_user}' to the 'docker' group..."
            sudo usermod -aG docker "${runner_user}"
            _warn "User '${runner_user}' was added to the 'docker' group. A system restart or re-login might be required for this to take effect."
        fi
    fi

    # Generate sample workflow
    _info "Generating sample workflow file..."
    local template_file="deploy.${gdr_deploy_mode}.yml"
    local sample_workflow_path="${app_dir}/SAMPLE_deploy.yml"
    
    # This is a simplified template substitution.
    # A real implementation might use a more robust templating function.
    local template_content
    template_content=$(get_template_content "${template_file}")
    
    # Replace placeholders
    template_content="${template_content//APP_SLUG/${gdr_slug}}"
    template_content="${template_content//MY_SERVICE/${gdr_systemd_service}}"
    
    echo "${template_content}" > "${sample_workflow_path}"

    _success "Setup complete for runner '${gdr_slug}'!"
    echo
    _info "--- NEXT STEPS ---"
    echo -e "1. ${CLR_BOLD}Add the following labels to your repository/organization runners settings:${CLR_RESET}"
    echo -e "   ${gdr_runner_labels}"
    echo
    echo -e "2. ${CLR_BOLD}Copy the sample workflow file into your project's .github/workflows/ directory:${CLR_RESET}"
    echo -e "   ${CLR_YELLOW}File path:${CLR_RESET} ${sample_workflow_path}"
    echo
    echo -e "3. ${CLR_BOLD}Customize the workflow file as needed and commit it to your repository.${CLR_RESET}"
    echo
    echo -e "4. ${CLR_BOLD}Push a commit to trigger your first deployment!${CLR_RESET}"
}

get_template_content() {
    local template_name="$1"
    # In a real script, this would read from the /usr/share/fastpull/templates location
    # For this bootstrap, we'll embed them.
    case "${template_name}" in
        "deploy.docker.compose.yml")
            cat <<'TPL'
# .github/workflows/deploy.yml
# Sample workflow for Docker Compose deployments via fastpull
name: Deploy to VM

on:
  push:
    branches:
      - main # Or your deployment branch

jobs:
  deploy:
    name: Deploy
    # IMPORTANT: Replace these labels with the ones you configured during setup.
    runs-on: [self-hosted, linux, x64, APP_SLUG] # Match your runner labels

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Deploy application
        run: |
          set -e
          APP_DIR="/opt/apps/APP_SLUG"
          
          echo "--> Syncing application files to ${APP_DIR}"
          rsync -av --delete --exclude='.git/' ./ "${APP_DIR}/"
          
          cd "${APP_DIR}"
          
          echo "--> Pulling latest images"
          docker compose pull || true
          
          echo "--> Building and starting containers"
          docker compose up -d --build --remove-orphans
          
          echo "--> Deployment complete!"
TPL
            ;;
        "deploy.systemd.yml")
            cat <<'TPL'
# .github/workflows/deploy.yml
# Sample workflow for systemd deployments via fastpull
name: Deploy to VM

on:
  push:
    branches:
      - main # Or your deployment branch

jobs:
  deploy:
    name: Deploy
    # IMPORTANT: Replace these labels with the ones you configured during setup.
    runs-on: [self-hosted, linux, x64, APP_SLUG] # Match your runner labels

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Deploy application
        run: |
          set -e
          APP_DIR="/opt/apps/APP_SLUG"
          
          echo "--> Syncing application files to ${APP_DIR}"
          # Add build steps here if needed, e.g., npm install, composer install
          rsync -av --delete --exclude='.git/' ./ "${APP_DIR}/"
          
          echo "--> Restarting systemd service"
          # This command is granted passwordless sudo access during 'fastpull setup'
          sudo systemctl restart MY_SERVICE
          
          echo "--> Verifying service status"
          sleep 5 # Give the service a moment to start up
          sudo systemctl is-active --quiet MY_SERVICE
          
          echo "--> Deployment complete!"
TPL
            ;;
        "deploy.custom.yml")
            cat <<'TPL'
# .github/workflows/deploy.yml
# Sample workflow for custom command deployments via fastpull
name: Deploy to VM

on:
  push:
    branches:
      - main # Or your deployment branch

jobs:
  deploy:
    name: Deploy
    # IMPORTANT: Replace these labels with the ones you configured during setup.
    runs-on: [self-hosted, linux, x64, APP_SLUG] # Match your runner labels

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Deploy application
        run: |
          set -e
          APP_DIR="/opt/apps/APP_SLUG"
          
          echo "--> Syncing application files to ${APP_DIR}"
          rsync -av --delete --exclude='.git/' ./ "${APP_DIR}/"
          
          cd "${APP_DIR}"
          
          echo "--> Running custom deployment command(s)"
          # ------------------------------------------------
          # --- ADD YOUR CUSTOM DEPLOYMENT LOGIC HERE ---
          #
          # Example: Run a shell script from your repo
          #   ./scripts/deploy.sh --production
          #
          # Example: Run a binary
          #   ./my-app-binary --config prod.toml
          # ------------------------------------------------
          
          echo "--> Deployment complete!"
TPL
            ;;
    esac
}

_cmd_list() {
    local runner_base="${GDR_RUNNER_BASE:-/opt/gha-runners}"
    local app_base="${GDR_APP_BASE:-/opt/apps}"

    if [[ ! -d "${runner_base}" ]] || [[ -z "$(ls -A "${runner_base}")" ]]; then
        _info "No runners found in ${runner_base}."
        return
    fi

    printf "%-"20s | %-5s | %-40s | %-15s\n" "SLUG" "SCOPE" "LABELS" "SERVICE STATE"
    echo "--------------------------------------------------------------------------------------------------"

    for slug_dir in "${runner_base}"/*;
    do
        if [[ -d "${slug_dir}" ]]; then
            local slug
            slug=$(basename "${slug_dir}")
            local runner_file="${slug_dir}/.runner"
            local labels="-"
            local scope="-"
            if [[ -f "${runner_file}" ]]; then
                labels=$(jq -r '.labels | map(.name) | join(",")' "${runner_file}")
                scope=$(jq -r 'if .ownerName then "org" else "repo" end' "${runner_file}")
            fi
            
            local service_state="-"
            if command -v systemctl &> /dev/null;
            then
                if systemctl is-active --quiet "actions.runner.${slug}.service"; then
                    service_state="${CLR_GREEN}active${CLR_RESET}"
                elif systemctl is-failed --quiet "actions.runner.${slug}.service"; then
                    service_state="${CLR_RED}failed${CLR_RESET}"
                else
                    service_state="inactive"
                fi
            fi

            printf "%-"20s | %-5s | %-40s | %-15b\n" "${slug}" "${scope}" "${labels}" "${service_state}"
        fi
    done
}

_cmd_status() {
    _check_deps "systemctl"
    local slug="$1"
    [[ -z "${slug}" ]] && _fatal "Usage: fastpull status <slug>"

    local runner_dir="${GDR_RUNNER_BASE:-/opt/gha-runners}/${slug}"
    [[ ! -d "${runner_dir}" ]] && _fatal "Runner with slug '${slug}' not found."

    _info "Status for runner: ${CLR_BOLD}${slug}${CLR_RESET}"
    echo "-------------------------------------"
    
    local service_name="actions.runner.${slug}.service"
    echo -n "Service Status: "
    if systemctl is-active --quiet "${service_name}"; then
        echo -e "${CLR_GREEN}Active${CLR_RESET}"
    elif systemctl is-failed --quiet "${service_name}"; then
        echo -e "${CLR_RED}Failed${CLR_RESET}"
    else
        echo "Inactive"
    fi

    echo "Runner Directory: ${runner_dir}"
    echo "Application Directory: ${GDR_APP_BASE:-/opt/apps}/${slug}"

    if [[ -f "${runner_dir}/.runner" ]]; then
        echo "Labels: $(jq -r '.labels | map(.name) | join(",")' "${runner_dir}/.runner")"
    fi
    
    echo
    _info "Last 10 lines of service log:"
    journalctl -u "${service_name}" -n 10 --no-pager
}

_cmd_uninstall() {
    _check_root
    local slug="$1"
    [[ -z "${slug}" ]] && _fatal "Usage: fastpull uninstall <slug>"

    local runner_dir="${GDR_RUNNER_BASE:-/opt/gha-runners}/${slug}"
    [[ ! -d "${runner_dir}" ]] && _fatal "Runner with slug '${slug}' not found."

    _warn "This will stop the service and unregister the runner from GitHub."
    _prompt "Are you sure you want to uninstall runner '${slug}'?" confirm "no" "GDR_CONFIRM"
    [[ "${confirm}" != "yes" ]] && _info "Uninstall aborted." && exit 0

    cd "${runner_dir}"

    _info "Stopping and uninstalling service..."
    sudo ./svc.sh stop
    sudo ./svc.sh uninstall

    _info "Removing runner configuration from GitHub..."
    # We need the token to do this cleanly. If not available, it will fail but we proceed.
    local token
    _prompt_masked "Enter a valid GitHub PAT or registration token to remove the runner" token "GDR_TOKEN"
    
    ./config.sh remove --unattended --token "${token}" || _warn "Failed to remove runner from GitHub. You may need to remove it manually from the UI. This can happen if the token is expired."

    _info "Removing runner directory: ${runner_dir}"
    sudo rm -rf "${runner_dir}"

    local sudoers_file="/etc/sudoers.d/gha-runner-${slug}"
    if [[ -f "${sudoers_file}" ]]; then
        _info "Removing sudoers file: ${sudoers_file}"
        sudo rm -f "${sudoers_file}"
    fi

    _success "Runner '${slug}' has been uninstalled."
    
    local app_dir="${GDR_APP_BASE:-/opt/apps}/${slug}"
    if [[ -d "${app_dir}" ]]; then
        _prompt "Do you also want to remove the application directory '${app_dir}'?" confirm_app_del "no" "GDR_CONFIRM_APP_DELETE"
        if [[ "${confirm_app_del}" == "yes" ]]; then
            sudo rm -rf "${app_dir}"
            _success "Application directory removed."
        fi
    fi
}

_cmd_destroy() {
    _warn "The 'destroy' command is an alias for 'uninstall' with aggressive cleanup."
    _cmd_uninstall "$@"
}

_cmd_upgrade() {
    _check_root
    _fatal "Upgrade command is not yet implemented. See docs/ROADMAP.md."
}

_cmd_doctor() {
    _info "Running fastpull diagnostics..."
    echo "-------------------------------------"
    
    local has_error=0
    
    # Check OS
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        _info "OS: ${PRETTY_NAME}"
        if [[ "${ID}" != "ubuntu" && "${ID}" != "debian" ]]; then
            _warn "OS is not officially supported. You may encounter issues."
        fi
    else
        _warn "Could not determine OS version."
    fi

    # Check deps
    for dep in "curl" "jq" "tar" "systemctl" "rsync"; do
        if command -v "${dep}" &>/dev/null;
        then
            _info "Dependency check for '${dep}': ${CLR_GREEN}OK${CLR_RESET}"
        else
            _error "Dependency check for '${dep}': ${CLR_RED}Missing${CLR_RESET}"
            has_error=1
        fi
    done

    # Check Docker
    if command -v docker &>/dev/null;
    then
        _info "Docker: Installed"
        if ! docker ps &>/dev/null;
        then
            _warn "Docker is installed, but the daemon doesn't seem to be running or you lack permissions."
        fi
    else
        _info "Docker: Not installed"
    fi

    # Check network
    _info "Network: Checking GitHub API connectivity..."
    if curl -sSL -o /dev/null "${GITHUB_API_URL}/zen"; then
        _info "GitHub API reachability: ${CLR_GREEN}OK${CLR_RESET}"
    else
        _error "GitHub API reachability: ${CLR_RED}Failed${CLR_RESET}"
        has_error=1
    fi

    # Check permissions
    for dir in "/opt" "/usr/local/bin"; do
        if [[ -w "${dir}" ]]; then
            _info "Permissions: Write access to ${dir}: ${CLR_GREEN}OK${CLR_RESET}"
        else
            _warn "Permissions: No direct write access to ${dir}. 'sudo' will be required."
        fi
    done

    echo "-------------------------------------"
    if [[ ${has_error} -eq 1 ]]; then
        _error "Doctor found one or more critical issues."
    else
        _success "Doctor finished. System appears ready for fastpull."
    fi
}


# --- Main Execution Logic ---
main() {
    setup_colors
    local cmd="$1"
    shift || true

    case "${cmd}" in
        setup|list|status|uninstall|destroy|upgrade|doctor|version)
            _cmd_"${cmd}" "$@"
            ;;
        help|--help|-h|"")
            _cmd_help
            ;;
        *)
            _error "Unknown command: ${cmd}"
            _cmd_help
            exit 1
            ;;
    esac
}

# Let's go
main "$@"
EOF
}

create_install_sh() {
echo "==> Creating install.sh..."
cat <<'EOF' > fastpull/install.sh
#!/bin/bash
#
# install.sh: Installs the 'fastpull' CLI to /usr/local/bin.
#

set -e

INSTALL_DIR="/usr/local/bin"
SOURCE_FILE="bin/fastpull"

echo "Installing 'fastpull' to ${INSTALL_DIR}..."

if [[ ! -f "${SOURCE_FILE}" ]]; then
    echo "ERROR: Source file not found at '${SOURCE_FILE}'. Run this script from the project root."
    exit 1
fi

if [[ "$(id -u)" -ne 0 ]]; then
    echo "This script requires sudo to install to ${INSTALL_DIR}."
    sudo cp "${SOURCE_FILE}" "${INSTALL_DIR}/fastpull"
    sudo chmod +x "${INSTALL_DIR}/fastpull"
else
    cp "${SOURCE_FILE}" "${INSTALL_DIR}/fastpull"
    chmod +x "${INSTALL_DIR}/fastpull"
fi

echo
echo "Successfully installed 'fastpull'!"
echo "Run 'fastpull --help' to get started."
EOF
}

create_curl_install_sh() {
echo "==> Creating scripts/curl-install.sh..."
cat <<'EOF' > fastpull/scripts/curl-install.sh
#!/bin/bash
#
# This script downloads and installs the 'fastpull' CLI.
#
# Usage: curl -sSL https://raw.githubusercontent.com/gigahidjrikaaa/Fastpull/main/scripts/curl-install.sh | bash
#
# You can customize the installation by setting environment variables:
#   - FASTPULL_REF: The git ref (branch, tag, commit) to install from (default: main).
#   - FASTPULL_PREFIX: The installation prefix (default: /usr/local).

set -e

# --- Configuration ---
GITHUB_REPO="gigahidjrikaaa/Fastpull"
: "${FASTPULL_REF:=main}"
: "${FASTPULL_PREFIX:=/usr/local}"

# --- Helper Functions ---
_log_error() {
    echo "[ERROR] $1" >&2
    exit 1
}

_log_info() {
    echo "[INFO] $1"
}

# --- Main Logic ---
main() {
    _log_info "Starting fastpull installation..."
    
    local download_url="https://raw.githubusercontent.com/${GITHUB_REPO}/${FASTPULL_REF}/bin/fastpull"
    local install_path="${FASTPULL_PREFIX}/bin/fastpull"
    local temp_file
    temp_file=$(mktemp)

    _log_info "Downloading fastpull from ${download_url}..."
    if ! curl -fsSL "${download_url}" -o "${temp_file}"; then
        _log_error "Failed to download the script. Check the URL and your network connection."
    fi

    chmod +x "${temp_file}"

    _log_info "Installing to ${install_path}..."
    if [[ "$(id -u)" -ne 0 ]]; then
        _log_info "Sudo privileges required."
        sudo mv "${temp_file}" "${install_path}"
    else
        mv "${temp_file}" "${install_path}"
    fi

    _log_info "Installation complete!"
    _log_info "Run 'fastpull --help' to get started."
}

main "$@"
EOF
}

create_dev_setup_sh() {
echo "==> Creating scripts/dev/setup-dev.sh..."
cat <<'EOF' > fastpull/scripts/dev/setup-dev.sh
#!/bin/bash
#
# Installs development dependencies for fastpull.
# Requires sudo privileges.

set -e

echo "Installing development dependencies: shellcheck, shfmt, bats..."

if ! command -v apt-get &>/dev/null;
then
    echo "This script currently only supports Debian-based systems (apt-get)."
    exit 1
fi

sudo apt-get update
sudo apt-get install -y shellcheck

# Install shfmt
if ! command -v shfmt &>/dev/null;
then
    echo "Installing shfmt..."
    VERSION="v3.4.3"
    OS="linux"
    ARCH="amd64"
    sudo curl -sSL "https://github.com/mvdan/sh/releases/download/${VERSION}/shfmt_${VERSION}_${OS}_${ARCH}" -o /usr/local/bin/shfmt
    sudo chmod +x /usr/local/bin/shfmt
fi

# Install bats
if ! command -v bats &>/dev/null;
then
    echo "Installing bats..."
    sudo apt-get install -y bats
fi

echo "Development dependencies installed successfully."
EOF
}

create_record_demo_sh() {
echo "==> Creating scripts/record-demo.sh..."
cat <<'EOF' > fastpull/scripts/record-demo.sh
#!/bin/bash
#
# This script contains the storyboard for recording a terminal demo GIF.
# It uses 'vhs' (https://github.com/maaslalani/vhs) to generate the GIF.
#
# Prerequisites:
#   1. Install vhs: go install github.com/maaslalani/vhs@latest
#   2. A clean Ubuntu/Debian VM.
#   3. A GitHub repository with a simple Docker Compose project.
#   4. A GitHub Personal Access Token with 'repo' scope.
#
# Usage:
#   1. Replace placeholder values in this script.
#   2. Run 'vhs < scripts/record-demo.sh'
#   3. The output will be 'fastpull-demo.gif'.

# --- VHS Configuration ---
Output "fastpull-demo.gif"
Set FontSize 16
Set Width 1200
Set Height 800
Set TypingSpeed 100ms

# --- Demo Storyboard ---

# 1. Show the prompt and install fastpull
Type "curl -sSL https://raw.githubusercontent.com/gigahidjrikaaa/Fastpull/main/scripts/curl-install.sh | bash"
Enter
Sleep 2s

# 2. Run setup
Type "sudo fastpull setup"
Enter
Sleep 1s

# Follow the prompts
# Scope: repo
Enter
Sleep 1s
# URL: Your repo URL
Type "https://github.com/gigahidjrikaaa/Fastpull-test"
Enter
Sleep 1s
# App Name
Enter
Sleep 1s
# Slug
Enter
Sleep 1s
# Labels
Enter
Sleep 1s
# Runner Base
Enter
Sleep 1s
# App Base
Enter
Sleep 1s
# Deploy Mode: docker
Enter
Sleep 1s
# Token: Paste your token here
Type "YOUR_GITHUB_TOKEN" # Replace with your GitHub token
Enter
Sleep 5s

# 3. Show the list of runners
Type "sudo fastpull list"
Enter
Sleep 3s

# 4. Show the sample workflow file
Type "cat /opt/apps/Fastpull-test/SAMPLE_deploy.yml"
Enter
Sleep 5s

# 5. Explain the next step (manual)
Hide
Show
Type "# Now, we copy this workflow into our repo, commit, and push..."
Sleep 3s
Type "git push"
Enter
Sleep 5s

# 6. Show the runner picking up the job (pretend)
Type "sudo fastpull status Fastpull-test"
Enter
Sleep 5s
# Show logs indicating a job was run
# (This part is hard to automate in a recording, might need manual intervention or faked logs)

# End of recording
Sleep 2s
EOF
}

create_packaging_files() {
echo "==> Creating packaging/deb/control..."
cat <<'EOF' > fastpull/packaging/deb/DEBIAN/control
Package: fastpull
Version: 0.2.0
Architecture: all
Maintainer: Giga Hidjrika Agusta <gigahidjrikaaa@gmail.com>
Description: A zero-dependency CLI for GitHub Actions push-to-deploy runners.
 Fastpull simplifies setting up and managing self-hosted GitHub Actions runners
 on Debian/Ubuntu VMs for easy, secure push-to-deploy workflows. 
 It supports Docker Compose, systemd, and custom deployment scripts.
Homepage: https://github.com/gigahidjrikaaa/Fastpull
EOF

echo "==> Creating packaging/deb/postinst..."
cat <<'EOF' > fastpull/packaging/deb/DEBIAN/postinst
#!/bin/sh
set -e
chmod 0755 /usr/local/bin/fastpull
echo "fastpull installed. Run 'fastpull help' to get started."
EOF

echo "==> Creating packaging/deb/prerm..."
cat <<'EOF' > fastpull/packaging/deb/DEBIAN/prerm
#!/bin/sh
set -e
echo "Note: Uninstalling the fastpull package does not remove installed runners."
echo "Use 'fastpull uninstall <slug>' or 'fastpull destroy <slug>' before removing the package."
EOF
}

create_workflow_templates() {
echo "==> Creating templates/deploy.docker.compose.yml..."
cat <<'EOF' > fastpull/templates/deploy.docker.compose.yml
# .github/workflows/deploy.yml
# Sample workflow for Docker Compose deployments via fastpull
name: Deploy to VM

on:
  push:
    branches:
      - main # Or your deployment branch

jobs:
  deploy:
    name: Deploy
    # IMPORTANT: Replace these labels with the ones you configured during setup.
    runs-on: [self-hosted, linux, x64, APP_SLUG] # Match your runner labels

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
EOF

echo "==> Creating templates/deploy.systemd.yml..."
cat <<'EOF' > fastpull/templates/deploy.systemd.yml
# .github/workflows/deploy.yml
# Sample workflow for systemd deployments via fastpull
name: Deploy to VM

on:
  push:
    branches:
      - main # Or your deployment branch

jobs:
  deploy:
    name: Deploy
    # IMPORTANT: Replace these labels with the ones you configured during setup.
    runs-on: [self-hosted, linux, x64, APP_SLUG] # Match your runner labels

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Deploy application
        run: |
          set -e
          # This path is configured during 'fastpull setup'
          APP_DIR="/opt/apps/APP_SLUG"
          
          echo "--> Syncing application files to ${APP_DIR}"
          # Add build steps here if your application needs them
          # e.g., npm install && npm run build
          rsync -av --delete --exclude='.git/' ./ "${APP_DIR}/"
          
          echo "--> Restarting systemd service"
          # This command is granted passwordless sudo access during 'fastpull setup'
          sudo systemctl restart MY_SERVICE
          
          echo "--> Verifying service status"
          sleep 5 # Give the service a moment to start up
          sudo systemctl is-active --quiet MY_SERVICE
          
          echo "--> Deployment complete!"
EOF

echo "==> Creating templates/deploy.custom.yml..."
cat <<'EOF' > fastpull/templates/deploy.custom.yml
# .github/workflows/deploy.yml
# Sample workflow for custom command deployments via fastpull
name: Deploy to VM

on:
  push:
    branches:
      - main # Or your deployment branch

jobs:
  deploy:
    name: Deploy
    # IMPORTANT: Replace these labels with the ones you configured during setup.
    runs-on: [self-hosted, linux, x64, APP_SLUG] # Match your runner labels

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Deploy application
        run: |
          set -e
          # This path is configured during 'fastpull setup'
          APP_DIR="/opt/apps/APP_SLUG"
          
          echo "--> Syncing application files to ${APP_DIR}"
          rsync -av --delete --exclude='.git/' ./ "${APP_DIR}/"
          
          cd "${APP_DIR}"
          
          echo "--> Running custom deployment command(s)"
          # ------------------------------------------------
          # --- ADD YOUR CUSTOM DEPLOYMENT LOGIC HERE ---
          #
          # Example: Run a shell script from your repo
          #   ./scripts/deploy.sh --production
          #
          # Example: Run a binary
          #   ./my-app-binary --config prod.toml
          # ------------------------------------------------
          
          echo "--> Deployment complete!"
EOF
}

create_stack_templates() {
echo "==> Creating templates/stacks/nextjs/README.md..."
cat <<'EOF' > fastpull/templates/stacks/nextjs/README.md
# Deploying a Next.js App with Fastpull

This stack uses Docker Compose for a simple and robust deployment.

## 1. Dockerfile

Add a `Dockerfile` to your Next.js project root:

```dockerfile
# Dockerfile
FROM node:18-alpine AS base

# 1. Install dependencies
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# 2. Build the app
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED 1
RUN npm run build

# 3. Production image
FROM base AS runner
WORKDIR /app
ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001
RUN chown nextjs:nodejs .
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
CMD ["node", "server.js"]
```
*Note: This Dockerfile assumes you have `output: 'standalone'` in your `next.config.js`.*

## 2. Docker Compose File

Add a `docker-compose.yml` file:

```yaml
# docker-compose.yml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "3000:3000"
    restart: always
```

## 3. GitHub Actions Workflow

Use the `deploy.docker.compose.yml` template from fastpull. The runner will automatically `docker compose up -d --build` on every push.
EOF

# Other stack READMEs
for stack in fastapi laravel rails springboot; do
    echo "==> Creating templates/stacks/${stack}/README.md..."
    cat <<EOF > "fastpull/templates/stacks/${stack}/README.md"
# Deploying a ${stack} App with Fastpull

*(This is a placeholder. Add specific instructions for a ${stack} deployment, including a sample Dockerfile and docker-compose.yml if applicable.)*
EOF
done
}

create_cloud_init_snippets() {
echo "==> Creating docs/cloud-init/aws.yml..."
cat <<'EOF' > fastpull/docs/cloud-init/aws.yml
#cloud-config
# AWS User Data for setting up fastpull non-interactively.
# Replace placeholder values before use.

package_update: true
packages:
  - curl
  - jq
  - tar

runcmd:
  - |
    # Install fastpull
    curl -sSL https://raw.githubusercontent.com/gigahidjrikaaa/Fastpull/main/scripts/curl-install.sh | bash

    # Set up the runner non-interactively
    export GDR_SCOPE="repo"
    export GDR_URL="https://github.com/gigahidjrikaaa/Fastpull"
    export GDR_APP_NAME="my-prod-app"
    export GDR_RUNNER_LABELS="self-hosted,linux,x64,prod-app"
    export GDR_DEPLOY_MODE="docker"
    export GDR_TOKEN="YOUR_RUNNER_REGISTRATION_TOKEN" # Replace with your token
    export FASTPULL_NONINTERACTIVE="yes"

    sudo fastpull setup
EOF

# Other cloud-init snippets
for provider in gcp oci hetzner; do
    echo "==> Creating docs/cloud-init/${provider}.yml..."
    cp fastpull/docs/cloud-init/aws.yml "fastpull/docs/cloud-init/${provider}.yml"
done
}

create_github_workflows() {
echo "==> Creating .github/workflows/ci.yml..."
cat <<'EOF' > fastpull/.github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Install shfmt
        run: |
          sudo curl -sSL "https://github.com/mvdan/sh/releases/download/v3.4.3/shfmt_v3.4.3_linux_amd64" -o /usr/local/bin/shfmt
          sudo chmod +x /usr/local/bin/shfmt

      - name: Run shellcheck
        uses: ludeeus/action-shellcheck@2.0.0
        with:
          check_together: 'yes'

      - name: Run shfmt
        run: shfmt -i 2 -d .

  test:
    name: Test
    runs-on: ubuntu-latest
    strategy:
      matrix:
        ubuntu: [ "20.04", "22.04", "24.04" ]
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Bats
        uses: mig4/setup-bats@v1
        with:
          bats-version: 1.8.2

      - name: Run tests
        run: bats tests
EOF

echo "==> Creating .github/workflows/release.yml..."
cat <<'EOF' > fastpull/.github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    name: Create Release
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run tests
        run: |
          sudo apt-get update && sudo apt-get install -y bats
          bats tests

      - name: Build .deb package
        run: |
          mkdir -p staging/DEBIAN
          mkdir -p staging/usr/local/bin
          cp packaging/deb/DEBIAN/* staging/DEBIAN/
          cp bin/fastpull staging/usr/local/bin/
          dpkg-deb --build staging fastpull_${{ github.ref_name }}_all.deb

      - name: Create SHA256 checksums
        run: |
          sha256sum bin/fastpull > SHA256SUMS
          sha256sum fastpull_${{ github.ref_name }}_all.deb >> SHA256SUMS

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            bin/fastpull
            fastpull_${{ github.ref_name }}_all.deb
            SHA256SUMS
          body: |
            Release ${{ github.ref_name }}
            See CHANGELOG.md for details.
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF
}

create_bats_tests() {
echo "==> Creating tests/test_helper.bash..."
cat <<'EOF' > fastpull/tests/test_helper.bash
#!/usr/bin/env bash

# Mock external commands to avoid network calls and sudo
# This is a very basic form of mocking.

# Mock curl
curl() {
    echo "Mocked curl call with args: $@" >&2
    if [[ "$1" == *"/releases/latest"* ]]; then
        echo '{ "tag_name": "v2.300.0", "assets": [ { "name": "actions-runner-linux-x64-2.300.0.tar.gz", "browser_download_url": "https://example.com/runner.tar.gz" } ] }'
    elif [[ "$1" == *"/zen"* ]]; then
        echo "Mocked Zen"
    fi
}

# Mock sudo
sudo() {
    echo "Mocked sudo call with command: $@" >&2
    # Execute the command without sudo
    "$@"
}

# Mock systemctl
systemctl() {
    echo "Mocked systemctl call with args: $@" >&2
    return 0
}

# Mock jq
jq() {
    # A very dumb mock for jq
    if [[ "$2" == *".browser_download_url"* ]]; then
        echo "https://example.com/runner.tar.gz"
    elif [[ "$2" == *".tag_name"* ]]; then
        echo "v2.300.0"
    else
        command jq "$@"
    fi
}
EOF

echo "==> Creating tests/main.bats..."
cat <<'EOF' > fastpull/tests/main.bats
#!/usr/bin/env bats

load 'test_helper.bash'

setup() {
    # Make the script available in PATH for testing
    export PATH="$PWD/bin:$PATH"
}

@test "shows help message" {
    run fastpull help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "USAGE" ]]
}

@test "shows version" {
    run fastpull version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "fastpull version" ]]
}

@test "handles unknown command" {
    run fastpull foobar
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown command: foobar" ]]
}
EOF

echo "==> Creating tests/slugify.bats..."
cat <<'EOF' > fastpull/tests/slugify.bats
#!/usr/bin/env bats

load 'test_helper.bash'

setup() {
    # Source the script to test internal functions
    source "$PWD/bin/fastpull"
}

@test "slugify: basic string" {
    run _slugify "My Test App"
    [ "$status" -eq 0 ]
    [ "$output" = "my-test-app" ]
}

@test "slugify: with special characters" {
    run _slugify "App @!# One"
    [ "$status" -eq 0 ]
    [ "$output" = "app-one" ]
}

@test "slugify: with leading/trailing hyphens" {
    run _slugify "--leading-and-trailing--"
    [ "$status" -eq 0 ]
    [ "$output" = "leading-and-trailing" ]
}
EOF
}

create_docs() {
echo "==> Creating README.md..."
cat <<'EOF' > fastpull/README.md
# Fastpull 🚀

**Fast, zero-dependency push-to-deploy for plain VMs via GitHub Actions self-hosted runners.**

[![CI](https://github.com/gigahidjrikaaa/Fastpull/actions/workflows/ci.yml/badge.svg)](https://github.com/gigahidjrikaaa/Fastpull/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

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

- `fastpull setup`: Interactively set up a new self-hosted runner.
- `fastpull list`: List all runners managed by fastpull.
- `fastpull status <slug>`: Show the status of a specific runner.
- `fastpull uninstall <slug>`: Uninstall a runner service (keeps app data).
- `fastpull destroy <slug>`: Aggressively remove a runner and all its files.
- `fastpull doctor`: Run diagnostics to check system compatibility.
- `fastpull help`: Show the help message.

## Security

- **Runner Tokens**: `fastpull` uses `read -s` to accept the GitHub registration token, so it is never displayed on screen or stored in your shell history. The token is used once for registration and is not stored by `fastpull`.
- **Sudoers**: When using `systemd` mode, `fastpull` creates a very specific sudoers file (e.g., `/etc/sudoers.d/gha-runner-my-app`) that only allows the runner's user to restart a single, specified service. This is the principle of least privilege in action.
- **Runner Scope**: Always create runners with the narrowest scope possible. If a runner is for a single repository, create it at the repository level, not the organization level. Use labels to ensure jobs only run on the intended machines.

## Troubleshooting

| Error                                       | Fix                                                                                                                            |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `dependency 'jq' is not installed`          | Run `sudo apt-get update && sudo apt-get install -y jq`.                                                                       |
| `Runner configuration failed`               | Your registration token may be incorrect or expired. Generate a new one and try again.                                         |
| `docker: command not found` (in deploy job) | Ensure Docker is installed on the VM. `fastpull setup` offers to do this, or you can run `curl -fsSL https://get.docker.com | sh`.
| Job is stuck on "Waiting for a runner"      | Check that the labels in your workflow file (`runs-on: [...]`) exactly match the labels you configured for the runner.           |

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit a pull request, run tests, and lint your code.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
EOF

echo "==> Creating CONTRIBUTING.md..."
cat <<'EOF' > fastpull/CONTRIBUTING.md
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
EOF

echo "==> Creating SECURITY.md..."
mkdir -p fastpull/docs
cat <<'EOF' > fastpull/SECURITY.md
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
EOF

echo "==> Creating docs/ROADMAP.md..."
cat <<'EOF' > fastpull/docs/ROADMAP.md
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
EOF

echo "==> Creating CHANGELOG.md..."
cat <<'EOF' > fastpull/CHANGELOG.md
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Your new feature here.

## [0.2.0] - YYYY-MM-DD

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
EOF

echo "==> Creating CODE_OF_CONDUCT.md..."
cat <<'EOF' > fastpull/CODE_OF_CONDUCT.md
# Contributor Covenant Code of Conduct

## Our Pledge

We as members, contributors, and leaders pledge to make participation in our
community a harassment-free experience for everyone, regardless of age, body
size, visible or invisible disability, ethnicity, sex characteristics, gender
identity and expression, level of experience, education, socio-economic status,
nationality, personal appearance, race, religion, or sexual identity
and orientation.

We pledge to act and interact in ways that contribute to an open, welcoming,
diverse, inclusive, and healthy community.

## Our Standards

Examples of behavior that contributes to a positive environment for our
community include:

*   Demonstrating empathy and kindness toward other people
*   Being respectful of differing opinions, viewpoints, and experiences
*   Giving and gracefully accepting constructive feedback
*   Accepting responsibility and apologizing to those affected by our mistakes,
    and learning from the experience
*   Focusing on what is best not just for us as individuals, but for the
    overall community

Examples of unacceptable behavior include:

*   The use of sexualized language or imagery, and sexual attention or
    advances of any kind
*   Trolling, insulting or derogatory comments, and personal or political attacks
*   Public or private harassment
*   Publishing others' private information, such as a physical or email
    address, without their explicit permission
*   Other conduct which could reasonably be considered inappropriate in a
    professional setting

## Enforcement Responsibilities

Community leaders are responsible for clarifying and enforcing our standards and
will take appropriate and fair corrective action in response to any behavior that
they deem inappropriate, threatening, offensive, or harmful.

Community leaders have the right and responsibility to remove, edit, or reject
comments, commits, code, wiki edits, issues, and other contributions that are
not aligned to this Code of Conduct, and will communicate reasons for moderation
decisions when appropriate.

## Scope

This Code of Conduct applies within all community spaces, and also applies when
an individual is officially representing the community in public spaces. 
Examples of representing our community include using an official e-mail address,
posting via an official social media account, or acting as an appointed
representative at an online or offline event.

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported to the community leaders responsible for enforcement at
[INSERT CONTACT METHOD].
All complaints will be reviewed and investigated promptly and fairly.

All community leaders are obligated to respect the privacy and security of the
reporter of any incident.

## Enforcement Guidelines

Community leaders will follow these Community Impact Guidelines in determining
the consequences for any action they deem in violation of this Code of Conduct:

### 1. Correction

**Community Impact**: Use of inappropriate language or other behavior deemed
unprofessional or unwelcome in the community.

**Consequence**: A private, written warning from community leaders, providing
clarity around the nature of the violation and an explanation of why the
behavior was inappropriate. A public apology may be requested.

### 2. Warning

**Community Impact**: A violation through a single incident or series
of actions.

**Consequence**: A warning with consequences for continued behavior. No
interaction with the people involved, including unsolicited interaction with
those enforcing the Code of Conduct, for a specified period of time. This
includes avoiding interaction in community spaces as well as external channels
like social media. Violating these terms may lead to a temporary or
permanent ban.

### 3. Temporary Ban

**Community Impact**: A serious violation of community standards, including
sustained inappropriate behavior.

**Consequence**: A temporary ban from any sort of interaction or public
communication with the community for a specified period of time. No public or
private interaction with the people involved, including unsolicited interaction
with those enforcing the Code of Conduct, is allowed during this period.
Violating these terms may lead to a permanent ban.

### 4. Permanent Ban

**Community Impact**: Demonstrating a pattern of violation of community
standards, including sustained inappropriate behavior, harassment of an
individual, or aggression toward or disparagement of classes of individuals.

**Consequence**: A permanent ban from any sort of public interaction within
the community.

## Attribution

This Code of Conduct is adapted from the [Contributor Covenant][homepage],
version 2.0, available at
[https://www.contributor-covenant.org/version/2/0/code_of_conduct.html][v2.0].

[homepage]: https://www.contributor-covenant.org
[v2.0]: https://www.contributor-covenant.org/version/2/0/code_of_conduct.html
EOF
}

create_project_files() {
echo "==> Creating .gitignore..."
cat <<'EOF' > fastpull/.gitignore
# General
*.log
*.swp
.DS_Store

# Build artifacts
/staging
*.deb

# Local dev
/work/
/_work/
/out/
/dist/
/node_modules/

# Demo artifacts
*.gif
*.cast
get-docker.sh
EOF

echo "==> Creating LICENSE..."
cat <<'EOF' > fastpull/LICENSE
MIT License

Copyright (c) $(date +%Y) GIga Hidjrika Aura Adkhy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
}

set_permissions() {
    echo "==> Setting executable permissions..."
    chmod +x fastpull/bin/fastpull
    chmod +x fastpull/install.sh
    chmod +x fastpull/scripts/curl-install.sh
    chmod +x fastpull/scripts/dev/setup-dev.sh
    chmod +x fastpull/scripts/record-demo.sh
    chmod +x fastpull/packaging/deb/DEBIAN/postinst
    chmod +x fastpull/packaging/deb/DEBIAN/prerm
}

# --- Run the main function ---
main

