#!/usr/bin/env bash
set -euo pipefail

# ================================

# Neovim Installation Script

# Builds and installs latest stable (or specified) Neovim from source.

# ================================

VERSION=${VERSION:-stable}
INSTALL_PREFIX=${INSTALL_PREFIX:-/usr/local}
BUILD_DIR=${BUILD_DIR:-/tmp}
NVIM_SRC_DIR="${BUILD_DIR}/neovim-${VERSION}"

echo "================================="
echo " Installing Neovim (${VERSION}) "
echo "================================="

# Must run as root

if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script must be run as root (use sudo or run in a root container)."
  exit 1
fi

# Determine OS

if [ -f /etc/os-release ]; then
  . /etc/os-release
else
  echo "❌ Cannot determine OS type (missing /etc/os-release)."
  exit 1
fi

# Install build dependencies

install_debian_dependencies() {
  echo "Installing build dependencies for Debian/Ubuntu..."
  apt-get update -y
  apt-get install -y ninja-build gettext cmake unzip curl build-essential git
  apt-get clean
  rm -rf /var/lib/apt/lists/*
}

case "${ID_LIKE:-$ID}" in
*debian*)
  install_debian_dependencies
  ;;
*)
  echo "❌ Unsupported Linux distribution: ${ID}"
  exit 1
  ;;
esac

# Normalize version tag

if [ "$VERSION" != "stable" ] && [ "$VERSION" != "nightly" ]; then
  TAG="v${VERSION}"
else
  TAG="${VERSION}"
fi

echo "Fetching Neovim source for tag '${TAG}'..."

cd "${BUILD_DIR}"
curl -sL "[https://github.com/neovim/neovim/archive/refs/tags/${TAG}.tar.gz](https://github.com/neovim/neovim/archive/refs/tags/${TAG}.tar.gz)" | tar xz

echo "Building Neovim..."
cd "neovim-${TAG}"

make CMAKE_BUILD_TYPE=Release
make CMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}/nvim" install

# Symlink for convenience

ln -sf "${INSTALL_PREFIX}/nvim/bin/nvim" /usr/local/bin/nvim

# Clean up

cd /
rm -rf "${BUILD_DIR}/neovim-${TAG}"

echo "✅ Neovim installation complete!"
echo "Installed binary: $(command -v nvim)"
echo "Version: $(nvim --version | head -n 1)"
