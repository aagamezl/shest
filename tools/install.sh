#!/bin/sh

VERSION="1.0.0"

FMT_RESET='\033[0m' # Color Off
FMT_BLUE='\033[34m'
FMT_BOLD='\033[1m'
FMT_CYAN='\033[0;36m'
FMT_GREEN='\033[0;32m'
FMT_RED='\033[0;31m'

FMT_RAINBOW="\
\033[38;5;196m \
\033[38;5;202m \
\033[38;5;226m \
\033[38;5;082m \
\033[38;5;021m \
\033[38;5;093m \
\033[38;5;163m"

# Make sure important variables exist if not already defined
#
# $USER is defined by login(1) which is not always executed (e.g. containers)
# POSIX: https://pubs.opengroup.org/onlinepubs/009695299/utilities/id.html
USER=${USER:-$(id -u -n)}
# $HOME is defined at the time of login, but it could be unset. If it is unset,
# a tilde by itself (~) will not be expanded to the current user's home directory.
# POSIX: https://pubs.opengroup.org/onlinepubs/009696899/basedefs/xbd_chap08.html#tag_08_03
HOME="${HOME:-$(getent passwd $USER 2>/dev/null | cut -d: -f6)}"
# macOS does not have getent, but this works even if $HOME is unset
HOME="${HOME:-$(eval echo ~$USER)}"

# Define the target path
SCRIPT_NAME="shest.sh"
TARGET_PATH="/home/$USER/$SCRIPT_NAME"
GITHUB_URL="https://raw.githubusercontent.com/aagamezl/shest/master/$SCRIPT_NAME"

echo $GITHUB_URL

# The [ -t 1 ] check only works when the function is not called from
# a subshell (like in `$(...)` or `(...)`, so this hack redefines the
# function at the top level to always return false when stdout is not
# a tty.
is_tty() {
  [ -t 1 ]
}

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
  if [ -n "$FORCE_HYPERLINK" ]; then
    [ "$FORCE_HYPERLINK" != 0 ]
    return $?
  fi

  # If stdout is not a tty, it doesn't support hyperlinks
  is_tty || return 1

  # DomTerm terminal emulator (domterm.org)
  if [ -n "$DOMTERM" ]; then
    return 0
  fi

  # VTE-based terminals above v0.50 (Gnome Terminal, Guake, ROXTerm, etc)
  if [ -n "$VTE_VERSION" ]; then
    [ $VTE_VERSION -ge 5000 ]
    return $?
  fi

  # If $TERM_PROGRAM is set, these terminals support hyperlinks
  case "$TERM_PROGRAM" in
  Hyper | iTerm.app | terminology | WezTerm | vscode) return 0 ;;
  esac

  # These termcap entries support hyperlinks
  case "$TERM" in
  xterm-kitty | alacritty | alacritty-direct) return 0 ;;
  esac

  # xfce4-terminal supports hyperlinks
  if [ "$COLORTERM" = "xfce4-terminal" ]; then
    return 0
  fi

  # Windows Terminal also supports hyperlinks
  if [ -n "$WT_SESSION" ]; then
    return 0
  fi

  return 1
}

fmt_link() {
  # $1: text, $2: url, $3: fallback mode
  if supports_hyperlinks; then
    printf '\033]8;;%s\033\\%s\033]8;;\033\\\n' "$2" "$1"
    return
  fi

  case "$3" in
  --text) printf '%s\n' "$1" ;;
  --url | *) fmt_underline "$2" ;;
  esac
}

fmt_underline() {
  is_tty && printf '\033[4m%s\033[24m\n' "$*" || printf '%s\n' "$*"
}

# shellcheck disable=SC2016 # backtick in single-quote
fmt_code() {
  is_tty && printf '`\033[2m%s\033[22m`\n' "$*" || printf '`%s`\n' "$*"
}

fmt_error() {
  echo "${FMT_BOLD}${FMT_RED}Error: $*${FMT_RESET}" >&2
}

print_success() {
  # shellcheck disable=SC2086
  set -- $FMT_RAINBOW # Split FMT_RAINBOW into positional parameters

  # RED=$1 ORANGE=$2 YELLOW=$3 GREEN=$4 BLUE=$5 INDIGO=$6 VIOLET=$7

  echo "$1          _               _   "
  echo "$2         | |             | |  "
  echo "$3      ___| |__   ___  ___| |_ "
  echo "$4     / __| '_ \ / _ \/ __| __|"
  echo "$5     \__ \ | | |  __/\__ \ |_ "
  echo "$7     |___/_| |_|\___||___/\__|"
  echo

  echo "$FMT_GREEN s h e s t $FMT_RESET is now installed and ready to use!"
  echo
  echo "• Follow us on X: $(fmt_link @aagamezl https://x.com/aagamezl)"
  echo "• Join our Dev community: $(fmt_link "Dev.to" https://dev.to/aagamezl)"
  echo
}

install_script() {
  # Download the script and save it to /home/$USER
  curl -fsSL "$GITHUB_URL" -o "$TARGET_PATH"

  if [ $? -eq 0 ]; then
    print_success

    exit 0
  else
    fmt_error "Failed to install $SCRIPT_NAME. Please check your permissions."

    exit 1
  fi
}

# Check if the script already exists
if [ -f "$TARGET_PATH" ]; then
  # Extract the semantic version number
  INSTALLED_VERSION=$(grep -oP 'VERSION="\K[0-9]+\.[0-9]+\.[0-9]+' "$TARGET_PATH")

  if [ "$INSTALLED_VERSION" = "$VERSION" ]; then
    echo "The most recent version $INSTALLED_VERSION is already installed at ${FMT_YELLOW}$TARGET_PATH${FMT_RESET}."
  else
    echo "${FMT_CYAN}A new version of ${FMT_RESET}${FMT_YELLOW}$SCRIPT_NAME${FMT_RESET} ${FMT_CYAN}($VERSION -> $INSTALLED_VERSION) exists${FMT_RESET}"

    printf "Do you want to upgrade? (Y/N): "
    read confirm
    case "$confirm" in
    [yY] | [yY][eE][sS]) : ;;
    *) exit 1 ;;
    esac

    install_script
  fi
else
  install_script
fi
