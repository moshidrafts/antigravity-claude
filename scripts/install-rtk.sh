#!/usr/bin/env bash
set -e

echo "======================================================="
echo "    Installing RTK (Rust Token Killer) for Claude      "
echo "======================================================="

CLAUDE_DIR="$HOME/.claude"
BIN_DIR="$CLAUDE_DIR/bin"
mkdir -p "$BIN_DIR"

OS="$(uname -s)"
ARCH="$(uname -m)"

ASSET_PATTERN=""
if [ "$OS" = "Darwin" ]; then
    if [ "$ARCH" = "arm64" ]; then
        ASSET_PATTERN="aarch64-apple-darwin.tar.gz"
    else
        ASSET_PATTERN="x86_64-apple-darwin.tar.gz"
    fi
elif [ "$OS" = "Linux" ]; then
    if [ "$ARCH" = "aarch64" ]; then
        ASSET_PATTERN="aarch64-unknown-linux-gnu.tar.gz"
    else
        ASSET_PATTERN="x86_64-unknown-linux-musl.tar.gz"
    fi
fi

if [ -z "$ASSET_PATTERN" ]; then
    echo "Unsupported OS/Arch: $OS $ARCH"
    exit 1
fi

echo "[1/3] Querying latest RTK release from GitHub..."
RELEASE_JSON=$(curl -s -H "User-Agent: Antigravity-Claude-Installer" https://api.github.com/repos/rtk-ai/rtk/releases/latest)
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep "browser_download_url" | grep "$ASSET_PATTERN" | head -n 1 | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Could not find asset matching $ASSET_PATTERN"
    exit 1
fi

TMP_TAR="/tmp/rtk-latest.tar.gz"
echo "[2/3] Downloading: $DOWNLOAD_URL..."
curl -L -s "$DOWNLOAD_URL" -o "$TMP_TAR"

tar -xzf "$TMP_TAR" -C "$BIN_DIR"
chmod +x "$BIN_DIR/rtk"
rm -f "$TMP_TAR"

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    export PATH="$BIN_DIR:$PATH"
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$HOME/.zshrc"
fi

echo "[3/3] Initializing RTK hooks..."
"$BIN_DIR/rtk" init -g

echo ""
echo "[SUCCESS] RTK is ready! Run 'rtk gain' in your terminal to inspect token savings."
