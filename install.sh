#!/usr/bin/env bash
set -euo pipefail

# Install script for cursor-vscode-ext
# Adds the command to PATH and sets up zsh autocomplete

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="cursor-vscode-ext"
SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_NAME}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# Make script executable
make_executable() {
    log_info "Making script executable..."
    chmod +x "$SCRIPT_PATH"
    log_success "Script is now executable"
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
export PATH="\${PATH}:${SCRIPT_DIR}"
EOF

    log_success "Added to PATH in ${config_file}"

    # Also add to current session
    export PATH="${PATH}:${SCRIPT_DIR}"
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
                install)
                    # For install command, we could fetch available extensions
                    # but that would require API calls. For now, just complete
                    # common extension ID patterns
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

    # Make script executable
    make_executable

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
export PATH="\${PATH}:${SCRIPT_DIR}"
EOF
            log_success "Added to PATH in ${zsh_config}"
        fi
    fi

    # Setup zsh autocomplete if zsh is available (regardless of current shell)
    if command -v zsh &> /dev/null; then
        setup_zsh_autocomplete
    else
        log_warn "Zsh not found, skipping zsh autocomplete setup"
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

