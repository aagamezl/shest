# shest configuration. Plain bash, sourced before the command line is parsed,
# so command-line options always win. Every setting is optional.
#
# Path patterns are literal substrings of the file path (like Jest's
# testPathIgnorePatterns), not globs.

# Where to look when no path is given on the command line. Directories and
# globs are accepted; "**" matches any depth.
TEST_MATCH=("examples")

# Test files whose path contains any of these are skipped.
TEST_PATH_IGNORE_PATTERNS=("/build/" "/dist/" "/node_modules/")

# Files that never show up in the coverage report (test files and shest
# itself are always excluded).
COVERAGE_PATH_IGNORE_PATTERNS=("/vendor/")

# Collect coverage on every run, and fail when it is below this percentage
# (an integer). Setting a threshold turns coverage on.
COVERAGE=true
# COVERAGE_THRESHOLD=80

# Stop after the first failing file.
# BAIL=true

# Print how long each test took.
# TIMING=true

# default, tap or junit; OUTPUT_FILE writes the report to a file instead of stdout.
# REPORTER=junit
# OUTPUT_FILE=report.xml

# Only run tests whose name matches this regex.
# NAME_FILTER=''
