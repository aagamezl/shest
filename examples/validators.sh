# shellcheck shell=bash

is_number() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

is_email() {
  [[ "$1" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[a-z]{2,}$ ]]
}

is_hex_color() {
  [[ "$1" =~ ^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$ ]]
}

is_port() {
  if ! is_number "$1"; then
    return 1
  fi

  if (($1 < 1 || $1 > 65535)); then
    return 1
  fi

  return 0
}
