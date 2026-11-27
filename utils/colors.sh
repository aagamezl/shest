# Raw ANSI codes, always defined.
C_ANSI_RESET=$'\033[0m'
C_ANSI_BOLD=$'\033[1m'
C_ANSI_DIM=$'\033[2m'
C_ANSI_RED=$'\033[31m'
C_ANSI_GREEN=$'\033[32m'
C_ANSI_YELLOW=$'\033[33m'
C_ANSI_BLUE=$'\033[34m'
C_ANSI_CYAN=$'\033[36m'

# Colors for output written to stdout: empty unless stdout is a color tty
# (or SHEST_FORCE_COLOR is set, which shest does for parallel child processes).
if [[ (-t 1 || -n "${SHEST_FORCE_COLOR:-}") && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]; then
  C_RESET=$C_ANSI_RESET
  C_BOLD=$C_ANSI_BOLD
  C_DIM=$C_ANSI_DIM
  C_RED=$C_ANSI_RED
  C_GREEN=$C_ANSI_GREEN
  C_YELLOW=$C_ANSI_YELLOW
  C_BLUE=$C_ANSI_BLUE
  C_CYAN=$C_ANSI_CYAN
else
  C_RESET=""
  C_BOLD=""
  C_DIM=""
  C_RED=""
  C_GREEN=""
  C_YELLOW=""
  C_BLUE=""
  C_CYAN=""
fi
