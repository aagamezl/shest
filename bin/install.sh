#!/bin/sh
#
# shest installer
#
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/aagamezl/shest/master/bin/install.sh)"
#   curl -fsSL https://raw.githubusercontent.com/aagamezl/shest/master/bin/install.sh | sh -s -- --yes
#
# Installs shest into ~/.shest and links it as ~/.local/bin/shest.
#
# Options:
#   -y, --yes        do not ask for confirmation when upgrading or uninstalling
#       --uninstall  remove shest
#   -h, --help       show this help
#
# Environment:
#   SHEST_INSTALL_DIR  where shest is installed      (default: ~/.shest)
#   SHEST_BIN_DIR      where the `shest` link goes   (default: ~/.local/bin)
#   SHEST_REF          branch or tag to download     (default: master)
#   SHEST_SOURCE_DIR   install from a local checkout instead of downloading

set -eu

REPO="aagamezl/shest"
REF="${SHEST_REF:-master}"

# $HOME is defined at login, but it could be unset (e.g. containers).
USER=${USER:-$(id -u -n)}
HOME="${HOME:-$(getent passwd "$USER" 2>/dev/null | cut -d: -f6)}"
# macOS does not have getent, but this works even if $HOME is unset
HOME="${HOME:-$(eval echo ~"$USER")}"

INSTALL_DIR="${SHEST_INSTALL_DIR:-$HOME/.shest}"
BIN_DIR="${SHEST_BIN_DIR:-$HOME/.local/bin}"
SCRIPT_NAME="shest.sh"
COMMAND_NAME="shest"

ASSUME_YES=0
UNINSTALL=0
WORK_DIR=""

# The [ -t 1 ] check only works when the function is not called from
# a subshell (like in `$(...)` or `(...)`, so this hack redefines the
# function at the top level to always return false when stdout is not
# a tty.
is_tty() {
  [ -t 1 ]
}

# Colors are real escape sequences (not literal "\033") so plain echo works
# in every POSIX shell. They stay empty when stdout is not a terminal.
if is_tty && [ -z "${NO_COLOR:-}" ]; then
  FMT_RESET=$(printf '\033[0m')
  FMT_BOLD=$(printf '\033[1m')
  FMT_RED=$(printf '\033[0;31m')
  FMT_GREEN=$(printf '\033[0;32m')
  FMT_YELLOW=$(printf '\033[0;33m')
  FMT_CYAN=$(printf '\033[0;36m')
  RAINBOW_1=$(printf '\033[38;5;196m')
  RAINBOW_2=$(printf '\033[38;5;202m')
  RAINBOW_3=$(printf '\033[38;5;226m')
  RAINBOW_4=$(printf '\033[38;5;082m')
  RAINBOW_5=$(printf '\033[38;5;021m')
  RAINBOW_6=$(printf '\033[38;5;163m')
else
  FMT_RESET="" FMT_BOLD="" FMT_RED="" FMT_GREEN="" FMT_YELLOW="" FMT_CYAN=""
  RAINBOW_1="" RAINBOW_2="" RAINBOW_3="" RAINBOW_4="" RAINBOW_5="" RAINBOW_6=""
fi

# This function uses the logic from supports-hyperlinks[1][2], which is
# made by Kat Marchán (@zkat) and licensed under the Apache License 2.0.
# [1] https://github.com/zkat/supports-hyperlinks
# [2] https://crates.io/crates/supports-hyperlinks
#
# Copyright (c) 2021 Kat Marchán
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
supports_hyperlinks() {
  # $FORCE_HYPERLINK must be set and be non-zero (this acts as a logic bypass)
  if [ -n "${FORCE_HYPERLINK:-}" ]; then
    [ "$FORCE_HYPERLINK" != 0 ]
    return $?
  fi

  # If stdout is not a tty, it doesn't support hyperlinks
  is_tty || return 1

  # DomTerm terminal emulator (domterm.org)
  if [ -n "${DOMTERM:-}" ]; then
    return 0
  fi

  # VTE-based terminals above v0.50 (Gnome Terminal, Guake, ROXTerm, etc)
  if [ -n "${VTE_VERSION:-}" ]; then
    [ "$VTE_VERSION" -ge 5000 ]
    return $?
  fi

  # If $TERM_PROGRAM is set, these terminals support hyperlinks
  case "${TERM_PROGRAM:-}" in
    Hyper | iTerm.app | terminology | WezTerm | vscode) return 0 ;;
  esac

  # These termcap entries support hyperlinks
  case "${TERM:-}" in
    xterm-kitty | alacritty | alacritty-direct) return 0 ;;
  esac

  # xfce4-terminal supports hyperlinks
  if [ "${COLORTERM:-}" = "xfce4-terminal" ]; then
    return 0
  fi

  # Windows Terminal also supports hyperlinks
  if [ -n "${WT_SESSION:-}" ]; then
    return 0
  fi

  return 1
}

fmt_underline() {
  if is_tty; then
    printf '\033[4m%s\033[24m\n' "$*"
  else
    printf '%s\n' "$*"
  fi
}

fmt_link() {
  # $1: text, $2: url, $3: fallback mode
  if supports_hyperlinks; then
    printf '\033]8;;%s\033\\%s\033]8;;\033\\\n' "$2" "$1"
    return
  fi

  case "${3:-}" in
    --text) printf '%s\n' "$1" ;;
    --url | *) fmt_underline "$2" ;;
  esac
}

fmt_error() {
  echo "${FMT_BOLD}${FMT_RED}Error: $*${FMT_RESET}" >&2
}

usage() {
  cat <<'USAGE'
Usage: install.sh [options]

Options:
  -y, --yes        do not ask for confirmation when upgrading or uninstalling
      --uninstall  remove shest
  -h, --help       show this help

Environment:
  SHEST_INSTALL_DIR  where shest is installed      (default: ~/.shest)
  SHEST_BIN_DIR      where the `shest` link goes   (default: ~/.local/bin)
  SHEST_REF          branch or tag to download     (default: master)
  SHEST_SOURCE_DIR   install from a local checkout instead of downloading
USAGE
}

cleanup() {
  if [ -n "$WORK_DIR" ] && [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR"
  fi
}

print_success() {
  echo "${RAINBOW_1}          _               _   "
  echo "${RAINBOW_2}         | |             | |  "
  echo "${RAINBOW_3}      ___| |__   ___  ___| |_ "
  echo "${RAINBOW_4}     / __| '_ \\ / _ \\/ __| __|"
  echo "${RAINBOW_5}     \\__ \\ | | |  __/\\__ \\ |_ "
  echo "${RAINBOW_6}     |___/_| |_|\\___||___/\\__|${FMT_RESET}"
  echo

  echo "${FMT_GREEN}s h e s t${FMT_RESET} $1 is now installed and ready to use!"
  echo
  echo "Run ${FMT_BOLD}shest --help${FMT_RESET} to get started."
  echo
  echo "• Follow us on X: $(fmt_link @aagamezl https://x.com/aagamezl)"
  echo "• Join our Dev community: $(fmt_link "Dev.to" https://dev.to/aagamezl)"
  echo
}

# Print the SHEST_VERSION declared in a shest.sh file (empty if not found).
read_version() {
  sed -n 's/^readonly SHEST_VERSION="\(.*\)"$/\1/p' "$1" 2>/dev/null | head -n 1
}

# Ask a yes/no question. Reads from the terminal so it also works through `curl | sh`.
confirm() {
  if [ "$ASSUME_YES" -eq 1 ]; then
    return 0
  fi

  printf '%s (y/N): ' "$1"
  if ! { read -r answer </dev/tty; } 2>/dev/null; then
    echo
    fmt_error "Cannot ask for confirmation without a terminal. Re-run with --yes."
    return 1
  fi
  case "$answer" in
    [yY] | [yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

# Make SOURCE_DIR point at a directory containing shest.sh and utils/.
fetch_source() {
  if [ -n "${SHEST_SOURCE_DIR:-}" ]; then
    SOURCE_DIR="$SHEST_SOURCE_DIR"
    return
  fi

  if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
    fmt_error "curl and tar are required to install $COMMAND_NAME."
    exit 1
  fi

  WORK_DIR=$(mktemp -d)
  SOURCE_DIR="$WORK_DIR/source"
  mkdir -p "$SOURCE_DIR"

  if ! curl -fsSL "https://github.com/$REPO/archive/$REF.tar.gz" | tar -xz -C "$SOURCE_DIR" --strip-components=1; then
    fmt_error "Failed to download $COMMAND_NAME ($REF). Check your network connection."
    exit 1
  fi
}

install_files() {
  mkdir -p "$INSTALL_DIR" "$BIN_DIR"

  rm -rf "$INSTALL_DIR/utils"
  cp "$SOURCE_DIR/$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"
  cp -R "$SOURCE_DIR/utils" "$INSTALL_DIR/utils"
  chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

  ln -sf "$INSTALL_DIR/$SCRIPT_NAME" "$BIN_DIR/$COMMAND_NAME"
}

warn_if_not_in_path() {
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
      echo "${FMT_YELLOW}$BIN_DIR is not in your PATH.${FMT_RESET} Add it to your shell profile:"
      echo
      echo "  export PATH=\"$BIN_DIR:\$PATH\""
      echo
      ;;
  esac
}

install_shest() {
  fetch_source

  if [ ! -f "$SOURCE_DIR/$SCRIPT_NAME" ] || [ ! -d "$SOURCE_DIR/utils" ]; then
    fmt_error "The downloaded source does not contain $SCRIPT_NAME and utils/."
    exit 1
  fi

  new_version=$(read_version "$SOURCE_DIR/$SCRIPT_NAME")
  installed_version=""
  if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    installed_version=$(read_version "$INSTALL_DIR/$SCRIPT_NAME")
  fi

  if [ -n "$installed_version" ] && [ "$installed_version" = "$new_version" ] && [ -L "$BIN_DIR/$COMMAND_NAME" ]; then
    echo "The most recent version $installed_version is already installed at ${FMT_YELLOW}$INSTALL_DIR${FMT_RESET}."
    exit 0
  fi

  if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    echo "${FMT_CYAN}A different version of ${FMT_RESET}$COMMAND_NAME${FMT_CYAN} is installed (${installed_version:-unknown} -> $new_version)${FMT_RESET}"
    confirm "Do you want to upgrade?" || exit 1
  fi

  if ! install_files; then
    fmt_error "Failed to install $COMMAND_NAME. Please check your permissions."
    exit 1
  fi

  print_success "$new_version"
  warn_if_not_in_path
}

uninstall_shest() {
  if [ ! -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    echo "$COMMAND_NAME is not installed at $INSTALL_DIR."
    exit 0
  fi

  confirm "Remove $COMMAND_NAME from $INSTALL_DIR and $BIN_DIR/$COMMAND_NAME?" || exit 1

  rm -f "$BIN_DIR/$COMMAND_NAME"
  rm -rf "$INSTALL_DIR"
  echo "$COMMAND_NAME was uninstalled."
}

trap cleanup EXIT

while [ $# -gt 0 ]; do
  case "$1" in
    -y | --yes) ASSUME_YES=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      fmt_error "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

if [ "$UNINSTALL" -eq 1 ]; then
  uninstall_shest
else
  install_shest
fi
