#!/usr/bin/env bash
set -euo pipefail

# Zag Installer
# Installs zag multi-agent worktree system to ~/bin

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/bin"

echo "Zag Installer v1.0.0"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v git &> /dev/null; then
    echo "Error: git not found. Install git 2.5+ first."
    exit 1
fi

if ! command -v zellij &> /dev/null; then
    echo "Error: zellij not found. Install from https://zellij.dev"
    exit 1
fi

if ! command -v claude &> /dev/null; then
    echo "Warning: claude command not found. Install Claude Code CLI to use zag."
    echo "         https://github.com/anthropics/claude-code"
fi

echo "✓ Prerequisites OK"
echo ""

# Create install directory
mkdir -p "$INSTALL_DIR"

# Install scripts
echo "Installing scripts to $INSTALL_DIR..."
cp "$SCRIPT_DIR/zag" "$INSTALL_DIR/zag"
cp "$SCRIPT_DIR/zag-reset" "$INSTALL_DIR/zag-reset"
cp "$SCRIPT_DIR/.zag-shell-init.sh" "${HOME}/.zag-shell-init.sh"

# Make executable
chmod +x "$INSTALL_DIR/zag" "$INSTALL_DIR/zag-reset" "${HOME}/.zag-shell-init.sh"

echo "✓ Scripts installed"
echo ""

# Check PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "Warning: $INSTALL_DIR is not in your PATH"
    echo ""
    echo "Add it to your shell config:"
    echo ""
    if [[ "$SHELL" == */zsh ]]; then
        echo "  echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.zshrc"
        echo "  source ~/.zshrc"
    else
        echo "  echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.bashrc"
        echo "  source ~/.bashrc"
    fi
    echo ""
else
    echo "✓ $INSTALL_DIR is in your PATH"
    echo ""
fi

echo "Installation complete!"
echo ""
echo "Usage:"
echo "  cd your-project"
echo "  zag              # Launch 4 agents"
echo "  zag-reset        # Clean up worktree"
echo ""
echo "Documentation: $SCRIPT_DIR/README.md"
