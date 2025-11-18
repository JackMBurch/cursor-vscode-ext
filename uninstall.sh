#!/usr/bin/env bash
set -euo pipefail

# Uninstall script for cursor-vscode-ext
# Removes the script, PATH entries, and zsh autocomplete

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

# Find script location
find_script_location() {
    local script_path

    # Check common installation locations
    if command -v "$SCRIPT_NAME" &> /dev/null; then
        script_path=$(command -v "$SCRIPT_NAME")
        echo "$(dirname "$script_path")"
        return 0
    fi

    # Check ~/.local/bin (remote install default)
    if [[ -f "${HOME}/.local/bin/${SCRIPT_NAME}" ]]; then
        echo "${HOME}/.local/bin"
        return 0
    fi

    # Check if we're in the repo directory
    if [[ -f "${PWD}/${SCRIPT_NAME}" ]]; then
        echo "$PWD"
        return 0
    fi

    return 1
}

# Remove script file
remove_script() {
    local install_dir="$1"
    local script_file="${install_dir}/${SCRIPT_NAME}"

    if [[ -f "$script_file" ]]; then
        log_info "Removing script: ${script_file}"
        rm -f "$script_file"
        log_success "Removed script file"

        # Remove directory if empty (and it's ~/.local/bin)
        if [[ "$install_dir" == "${HOME}/.local/bin" ]] && [[ -d "$install_dir" ]]; then
            if [[ -z "$(ls -A "$install_dir" 2>/dev/null)" ]]; then
                log_info "Removing empty directory: ${install_dir}"
                rmdir "$install_dir" 2>/dev/null || true
            fi
        fi
        return 0
    else
        log_warn "Script file not found: ${script_file}"
        return 1
    fi
}

# Remove PATH entries from shell config
remove_path_entries() {
    local shell_type="$1"
    local config_file=$(get_shell_config "$shell_type")

    if [[ ! -f "$config_file" ]]; then
        return 0
    fi

    log_info "Removing PATH entries from ${config_file}..."

    # Remove lines containing "# cursor-vscode-ext PATH" and the export line
    if grep -q "# cursor-vscode-ext PATH" "$config_file" 2>/dev/null; then
        # Use sed to remove the block (comment line + export line + blank line before if exists)
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS sed
            sed -i '' '/^# cursor-vscode-ext PATH$/,/^export PATH=.*cursor-vscode-ext/d' "$config_file"
        else
            # Linux sed
            sed -i '/^# cursor-vscode-ext PATH$/,/^export PATH=.*cursor-vscode-ext/d' "$config_file"
        fi

        # Remove trailing blank line if it exists
        if [[ -f "$config_file" ]]; then
            sed -i '$ { /^$/d; }' "$config_file" 2>/dev/null || true
        fi

        log_success "Removed PATH entries from ${config_file}"
        return 0
    else
        log_warn "No PATH entries found in ${config_file}"
        return 1
    fi
}

# Remove zsh completion file
remove_zsh_completion() {
    local completions_dir=$(get_zsh_completions_dir)
    local completion_file="${completions_dir}/_cursor-vscode-ext"

    if [[ -f "$completion_file" ]]; then
        log_info "Removing zsh completion file: ${completion_file}"
        rm -f "$completion_file"
        log_success "Removed completion file"

        # Remove directory if empty
        if [[ -d "$completions_dir" ]] && [[ -z "$(ls -A "$completions_dir" 2>/dev/null)" ]]; then
            log_info "Removing empty completions directory: ${completions_dir}"
            rmdir "$completions_dir" 2>/dev/null || true
        fi
        return 0
    else
        log_warn "Completion file not found: ${completion_file}"
        return 1
    fi
}

# Remove fpath configuration from zshrc
remove_fpath_config() {
    local zsh_config=$(get_shell_config "zsh")

    if [[ ! -f "$zsh_config" ]]; then
        return 0
    fi

    log_info "Removing fpath configuration from ${zsh_config}..."

    # Remove lines containing "fpath.*cursor-vscode-ext" and related compinit lines
    if grep -q "fpath.*cursor-vscode-ext" "$zsh_config" 2>/dev/null; then
        # Remove the fpath block (comment + fpath line + autoload/compinit lines if they're together)
        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS sed
            sed -i '' '/^# cursor-vscode-ext zsh completions$/,/^compinit$/d' "$zsh_config"
        else
            # Linux sed
            sed -i '/^# cursor-vscode-ext zsh completions$/,/^compinit$/d' "$zsh_config"
        fi

        # Remove trailing blank line if it exists
        if [[ -f "$zsh_config" ]]; then
            sed -i '$ { /^$/d; }' "$zsh_config" 2>/dev/null || true
        fi

        log_success "Removed fpath configuration from ${zsh_config}"
        return 0
    else
        log_warn "No fpath configuration found in ${zsh_config}"
        return 1
    fi
}

# Main uninstall function
main() {
    echo "Uninstalling cursor-vscode-ext..."
    echo ""

    # Find script location
    local install_dir
    if install_dir=$(find_script_location); then
        log_info "Found installation directory: ${install_dir}"
    else
        log_warn "Could not find cursor-vscode-ext installation"
        log_info "Attempting to remove configuration files anyway..."
        install_dir=""
    fi

    # Remove script file
    if [[ -n "$install_dir" ]]; then
        remove_script "$install_dir"
    fi

    # Detect shell
    local shell_type=$(detect_shell)
    log_info "Detected shell: ${shell_type}"

    # Remove PATH entries from current shell config
    remove_path_entries "$shell_type"

    # Also remove from zshrc if different from current shell
    if command -v zsh &> /dev/null && [[ "$shell_type" != "zsh" ]]; then
        remove_path_entries "zsh"
    fi

    # Remove zsh completion
    if command -v zsh &> /dev/null; then
        remove_zsh_completion
        remove_fpath_config
    fi

    echo ""
    log_success "Uninstallation complete!"
    echo ""
    echo "To complete the uninstallation:"
    echo "  1. Restart your terminal, or"
    echo "  2. Run: source $(get_shell_config "$shell_type")"
    echo ""
    echo "The cursor-vscode-ext command will no longer be available."
}

main "$@"

