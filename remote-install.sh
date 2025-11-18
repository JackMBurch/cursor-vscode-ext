#!/usr/bin/env bash
set -euo pipefail

# Remote install script for cursor-vscode-ext
# Can be run directly: curl -fsSL https://raw.githubusercontent.com/JackMBurch/cursor-vscode-ext/main/remote-install.sh | bash

REPO_URL="https://raw.githubusercontent.com/JackMBurch/cursor-vscode-ext/main"
INSTALL_DIR="${HOME}/.local/bin"
SCRIPT_NAME="cursor-vscode-ext"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

# Check for required commands
check_dependencies() {
    local missing=()

    if ! command -v curl &> /dev/null; then
        missing+=("curl")
    fi

    if ! command -v cursor &> /dev/null; then
        log_warn "Cursor command not found. Make sure Cursor is installed."
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing[*]}"
        log_error "Please install them and try again."
        exit 1
    fi
}

# Detect shell
detect_shell() {
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        echo "zsh"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

# Get shell config file
get_shell_config() {
    local shell_type="$1"
    case "$shell_type" in
        zsh)
            if [[ -f "${HOME}/.zshrc" ]]; then
                echo "${HOME}/.zshrc"
            elif [[ -f "${HOME}/.zprofile" ]]; then
                echo "${HOME}/.zprofile"
            else
                echo "${HOME}/.zshrc"
            fi
            ;;
        bash)
            if [[ -f "${HOME}/.bashrc" ]]; then
                echo "${HOME}/.bashrc"
            elif [[ -f "${HOME}/.bash_profile" ]]; then
                echo "${HOME}/.bash_profile"
            else
                echo "${HOME}/.bashrc"
            fi
            ;;
        *)
            echo "${HOME}/.profile"
            ;;
    esac
}

# Get zsh completions directory
get_zsh_completions_dir() {
    if [[ -d "${HOME}/.zsh/completions" ]]; then
        echo "${HOME}/.zsh/completions"
    elif [[ -d "${HOME}/.oh-my-zsh/completions" ]]; then
        echo "${HOME}/.oh-my-zsh/completions"
    elif [[ -d "${ZDOTDIR:-${HOME}}/.zsh/completions" ]]; then
        echo "${ZDOTDIR:-${HOME}}/.zsh/completions"
    else
        echo "${HOME}/.zsh/completions"
    fi
}

# Download script
download_script() {
    log_info "Downloading cursor-vscode-ext..."

    mkdir -p "$INSTALL_DIR"

    if ! curl -fsSL "${REPO_URL}/${SCRIPT_NAME}" -o "${INSTALL_DIR}/${SCRIPT_NAME}"; then
        log_error "Failed to download cursor-vscode-ext"
        exit 1
    fi

    chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}"
    log_success "Downloaded and made executable: ${INSTALL_DIR}/${SCRIPT_NAME}"
}

# Add to PATH
add_to_path() {
    local shell_type="$1"
    local config_file=$(get_shell_config "$shell_type")

    log_info "Adding to PATH in ${config_file}..."

    # Check if already added
    if grep -q "# cursor-vscode-ext PATH" "$config_file" 2>/dev/null; then
        log_warn "PATH entry already exists in ${config_file}"
        return 0
    fi

    # Create config file if it doesn't exist
    if [[ ! -f "$config_file" ]]; then
        touch "$config_file"
    fi

    # Add PATH entry
    cat >> "$config_file" << EOF

# cursor-vscode-ext PATH
export PATH="\${PATH}:${INSTALL_DIR}"
EOF

    log_success "Added to PATH in ${config_file}"

    # Also add to current session
    export PATH="${PATH}:${INSTALL_DIR}"
}

# Setup zsh autocomplete
setup_zsh_autocomplete() {
    local completions_dir=$(get_zsh_completions_dir)

    log_info "Setting up zsh autocomplete..."

    # Create completions directory if it doesn't exist
    mkdir -p "$completions_dir"

    # Create completion file
    local completion_file="${completions_dir}/_cursor-vscode-ext"

    cat > "$completion_file" << 'EOF'
#compdef cursor-vscode-ext

_cursor-vscode-ext() {
    local -a commands
    commands=(
        'install:Install a VS Code extension to Cursor'
        'uninstall:Uninstall a VS Code extension from Cursor'
    )

    _arguments \
        '1: :->command' \
        '*: :->args'

    case $state in
        command)
            _describe 'commands' commands
            ;;
        args)
            case $words[2] in
                install|uninstall)
                    _message "Enter extension ID (format: publisher.extension-name)"
                    ;;
            esac
            ;;
    esac
}

_cursor-vscode-ext "$@"
EOF

    log_success "Created completion file: ${completion_file}"

    # Add to fpath if not already there
    local shell_config=$(get_shell_config "zsh")
    if ! grep -q "fpath.*cursor-vscode-ext" "$shell_config" 2>/dev/null; then
        cat >> "$shell_config" << EOF

# cursor-vscode-ext zsh completions
fpath=(${completions_dir} \$fpath)
autoload -Uz compinit
compinit
EOF
        log_success "Added fpath configuration to ${shell_config}"
    fi
}

# Main installation
main() {
    echo "Installing cursor-vscode-ext..."
    echo ""

    # Check dependencies
    check_dependencies

    # Download script
    download_script

    # Detect shell
    local shell_type=$(detect_shell)
    log_info "Detected shell: ${shell_type}"

    # Add to PATH for current shell
    add_to_path "$shell_type"

    # Also add to zshrc if zsh is available and different from current shell
    if command -v zsh &> /dev/null && [[ "$shell_type" != "zsh" ]]; then
        local zsh_config=$(get_shell_config "zsh")
        if ! grep -q "# cursor-vscode-ext PATH" "$zsh_config" 2>/dev/null; then
            log_info "Also adding to PATH in ${zsh_config}..."
            cat >> "$zsh_config" << EOF

# cursor-vscode-ext PATH
export PATH="\${PATH}:${INSTALL_DIR}"
EOF
            log_success "Added to PATH in ${zsh_config}"
        fi
    fi

    # Setup zsh autocomplete if zsh is available
    if command -v zsh &> /dev/null; then
        setup_zsh_autocomplete
    fi

    echo ""
    log_success "Installation complete!"
    echo ""
    echo "To use cursor-vscode-ext, either:"
    echo "  1. Restart your terminal, or"
    echo "  2. Run: source $(get_shell_config "$shell_type")"
    echo ""
    echo "Then try: cursor-vscode-ext install vv13.markdown-auto-preview"
}

main "$@"

