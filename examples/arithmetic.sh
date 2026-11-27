sum() {
  echo $(($1 + $2))
}

divide() {
  if [[ $2 -eq 0 ]]; then
    echo "cannot divide by zero" >&2
    return 1
  fi

  echo $(($1 / $2))
}

unused_helper() {
  echo "never called"
}
