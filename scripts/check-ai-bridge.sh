#!/usr/bin/env sh
set -eu

WRAPPER="/tmp/XcodeMCPWrapper/.venv/bin/python"

echo "Checking Xcode, ChatGPT/Codex, and Windsurf bridge commands..."

if [ -x "$WRAPPER" ]; then
    echo "Found Xcode MCP wrapper: $WRAPPER"
else
    echo "Missing Xcode MCP wrapper: $WRAPPER"
    echo "Start or reinstall the Xcode MCP wrapper before using the xcode bridge."
    exit 1
fi

if "$WRAPPER" -m mcpbridge_wrapper --help >/dev/null 2>&1; then
    echo "Xcode MCP wrapper module is callable."
else
    echo "Xcode MCP wrapper exists, but mcpbridge_wrapper did not respond to --help."
fi

if command -v xcodebuildmcp >/dev/null 2>&1; then
    echo "Found xcodebuildmcp: $(command -v xcodebuildmcp)"
else
    echo "Missing xcodebuildmcp. Install it if you want build-oriented MCP tools."
fi

echo "Bridge check complete."
