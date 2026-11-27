# shellcheck shell=bash

max() {
  if (($1 > $2)); then
    echo "$1"
  else
    echo "$2"
  fi
}

min() {
  if (($1 < $2)); then
    echo "$1"
  else
    echo "$2"
  fi
}

abs() {
  if (($1 < 0)); then
    echo $((-$1))
  else
    echo "$1"
  fi
}

factorial() {
  local n="$1"
  local result=1

  while ((n > 1)); do
    result=$((result * n))
    n=$((n - 1))
  done

  echo "$result"
}
