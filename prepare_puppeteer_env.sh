#!/bin/bash

set -euo pipefail

# Skip Puppeteer's Chromium download; we'll supply our own browser
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Install Puppeteer
npm install puppeteer

# Common dependencies (fonts, libxss1, wget/gnupg)
apt-get update
apt-get install -y wget gnupg ca-certificates \
    fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 --no-install-recommends

# Detect architecture
ARCH=$(uname -m)

chrome_path=""

if [[ "$ARCH" == "x86_64" ]]; then
    # Install Google Chrome Stable (only available for amd64)
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
    sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list'
    apt-get update
    apt-get install -y google-chrome-stable --no-install-recommends
    chrome_path=$(which google-chrome-stable || true)
elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    # Official Google Chrome isn't provided for arm64 Linux; fall back to Chromium from distro
    # Depending on the base image/distribution the package name might be chromium or chromium-browser
    apt-get install -y chromium-browser || apt-get install -y chromium || true
    chrome_path=$(which chromium-browser || which chromium || true)
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Clean up apt cache to save space
rm -rf /var/lib/apt/lists/*

# Verify installation and copy the executable locally
if [[ -n "$chrome_path" && -x "$chrome_path" ]]; then
    # Copy instead of move to avoid breaking system-wide usage
    cp "$chrome_path" .
    basename=$(basename "$chrome_path")
    echo "$basename copied to current directory."
else
    echo "Error: browser executable not found for architecture $ARCH."
    exit 1
fi

# Optional: remind user to set Puppeteer to use this binary, e.g., via PUPPETEER_EXECUTABLE_PATH
echo "If using Puppeteer, set PUPPETEER_EXECUTABLE_PATH to './$basename' in your launch options."
