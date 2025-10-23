#!/bin/sh
set -e

REPO="hellohello/sop-mcp-client"
INSTALL_DIR="${HOME}/.local/bin"
SCRIPT_NAME="rails-mcp-adapter.rb"

error() {
    echo "Error: $1" >&2
    exit 1
}

echo "Installing Rails MCP Adapter..."

# Check for Ruby
if ! command -v ruby >/dev/null 2>&1; then
    error "Ruby is required but not installed. Please install Ruby 3.0+"
fi

RUBY_VERSION=$(ruby -v | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "Found Ruby ${RUBY_VERSION}"

# Create install directory
mkdir -p "$INSTALL_DIR"

# Download the client script
echo "Downloading client script..."
curl -fsSL "https://raw.githubusercontent.com/${REPO}/main/bin/${SCRIPT_NAME}" \
    -o "${INSTALL_DIR}/${SCRIPT_NAME}"

# Make executable
chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}"

# Verify installation
if [ -x "${INSTALL_DIR}/${SCRIPT_NAME}" ]; then
    echo "✨ Successfully installed Rails MCP Adapter to ${INSTALL_DIR}/${SCRIPT_NAME}"
    echo
    echo "Configuration Required:"
    echo "  RAILS_API_URL - Your Render app URL (e.g., https://your-app.onrender.com)"
    echo "  RAILS_API_KEY - API key for authentication"
    echo
    echo "Optional:"
    echo "  DEBUG=1 - Enable debug logging"
    echo
    if ! echo "$PATH" | grep -q "${INSTALL_DIR}"; then
        echo "NOTE: Add ${INSTALL_DIR} to your PATH:"
        echo "  export PATH=\$PATH:${INSTALL_DIR}"
        echo
    fi
else
    error "Installation failed"
fi