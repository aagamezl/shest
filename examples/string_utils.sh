# shellcheck shell=bash

to_upper() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

repeat_string() {
  local text="$1"
  local times="$2"
  local result=""
  local i

  for ((i = 0; i < times; i++)); do
    result+="$text"
  done

  echo "$result"
}

is_blank() {
  [[ -z "${1// /}" ]]
}
