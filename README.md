# cursor-vscode-ext

A pure bash script to install VS Code extensions directly to Cursor IDE.

## Features

- **Zero dependencies** - Pure bash, only requires `curl`, `gunzip`, and `cursor`
- **Fast installation** - Downloads and installs extensions from VS Code marketplace
- **Auto-decompression** - Handles gzipped VSIX files automatically
- **Simple CLI** - Easy-to-use command interface
- **Zsh autocomplete** - Full autocomplete support for zsh users

## Installation

### Quick Install (Recommended)

Install directly from GitHub with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/JackMBurch/cursor-vscode-ext/main/remote-install.sh | bash
```

This will:

- Download `cursor-vscode-ext` to `~/.local/bin`
- Make it executable
- Add it to your PATH (both bash and zsh)
- Set up zsh autocomplete (if zsh is available)

After installation, reload your shell:

```bash
source ~/.zshrc  # or ~/.bashrc
```

### Manual Install

If you prefer to install manually:

1. Clone the repository:

   ```bash
   cd ~/repos
   git clone https://github.com/JackMBurch/cursor-vscode-ext.git
   cd cursor-vscode-ext
   ```

2. Run the install script:

   ```bash
   ./install.sh
   ```

3. Reload your shell:

   ```bash
   source ~/.zshrc  # or ~/.bashrc
   ```

## Uninstallation

To uninstall cursor-vscode-ext:

1. Run the uninstall script:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/JackMBurch/cursor-vscode-ext/main/uninstall.sh | bash
   ```

   Or if you have the repository cloned locally:

   ```bash
   cd ~/repos/cursor-vscode-ext
   ./uninstall.sh
   ```

2. Reload your shell:

   ```bash
   source ~/.zshrc  # or ~/.bashrc
   ```

The uninstall script will:

- Remove the `cursor-vscode-ext` script file
- Remove PATH entries from your shell configuration files
- Remove zsh autocomplete files and configuration
- Clean up empty directories

## Usage

### Install an extension

```bash
cursor-vscode-ext install <publisher.extension-name>
```

**Examples:**

```bash
cursor-vscode-ext install vv13.markdown-auto-preview
cursor-vscode-ext install ozaki.markdown-github-dark
cursor-vscode-ext install bierner.markdown-emoji
cursor-vscode-ext install AykutSarac.jsoncrack-vscode
```

### Uninstall an extension

```bash
cursor-vscode-ext uninstall <publisher.extension-name>
```

**Examples:**

```bash
cursor-vscode-ext uninstall vv13.markdown-auto-preview
cursor-vscode-ext uninstall ozaki.markdown-github-dark
cursor-vscode-ext uninstall bierner.markdown-emoji
```

### Show help

```bash
cursor-vscode-ext --help
```

### Show version

```bash
cursor-vscode-ext --version
```

## How it works

1. Parses the extension ID (format: `publisher.extension-name`)
2. Downloads the VSIX file from VS Code marketplace API
3. Decompresses if the file is gzipped
4. Installs using `cursor --install-extension`
5. Cleans up temporary files

## Requirements

- **Cursor IDE** - Must be installed and `cursor` command available in PATH
- **curl** - For downloading extensions
- **gunzip** - For decompressing gzipped VSIX files
- **bash** - Shell interpreter

## Extension ID Format

Extensions must be specified in the format: `publisher.extension-name`

You can find the extension ID on the VS Code marketplace page URL:

- URL: `https://marketplace.visualstudio.com/items?itemName=publisher.extension-name`
- Extension ID: `publisher.extension-name`

## Troubleshooting

### Command not found

If `cursor-vscode-ext` is not found after installation:

1. Make sure you've reloaded your shell: `source ~/.zshrc`
2. Check if the script directory is in PATH: `echo $PATH | grep cursor-vscode-ext`
3. Verify the install script ran successfully

### Cursor command not found

Make sure Cursor is installed and the `cursor` command is available:

```bash
which cursor
```

If not found, you may need to:

1. Install Cursor command line tools
2. Add Cursor to your PATH manually

### Installation fails

- Check your internet connection
- Verify the extension ID is correct
- Ensure you have write permissions in the temp directory
- Check that Cursor is running and accessible

## License

MIT

## Contributing

Contributions welcome! Please feel free to submit a Pull Request.
