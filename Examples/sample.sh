#!/usr/bin/env bash
#
# Prism shell sample.
# Exercises: comments, single/double/backtick strings, all $-variable forms,
# command substitution, control-flow keywords, function definitions, numbers,
# operators, and arithmetic expansion.

set -euo pipefail

# --- Constants -------------------------------------------------------------

readonly APP_NAME="Prism"
readonly VERSION='1.0.0'
readonly MAX_BYTES=$((5 * 1024 * 1024))
readonly TIMEOUT_SECONDS=30
readonly HEX_MASK=0xDEADBEEF

# --- Variables -------------------------------------------------------------

verbose=true
log_dir="${LOG_DIR:-/tmp/prism-logs}"
host=$(hostname)
date_str=`date "+%Y-%m-%d"`        # backtick command substitution
positional="$1${2:-default}"        # ${var:-fallback}

# --- Functions -------------------------------------------------------------

function log() {
    local level="$1"; shift
    local message="$*"
    if [[ "$verbose" == "true" ]]; then
        printf '[%s] %-5s %s\n' "$date_str" "$level" "$message"
    fi
}

build_project() {
    log INFO "Generating project for $APP_NAME v$VERSION"
    if ! command -v xcodegen >/dev/null 2>&1; then
        log ERROR "xcodegen not installed; run: brew install xcodegen"
        return 1
    fi
    xcodegen generate
}

# --- Control flow ---------------------------------------------------------

for lang in json python swift markdown yaml shell html css; do
    case "$lang" in
        json|yaml)
            log DEBUG "config language: $lang"
            ;;
        swift|python|shell)
            log DEBUG "scripting language: $lang"
            ;;
        markdown|html|css)
            log DEBUG "markup language: $lang"
            ;;
        *)
            log WARN "unknown language: $lang"
            ;;
    esac
done

i=0
while [ $i -lt 5 ]; do
    log INFO "iteration #$i"
    i=$((i + 1))
done

# Special parameters
log DEBUG "PID=$$, last status=$?, script=$0, args=$#"

# Heredoc-ish double-quoted string demo
greeting="Hello from $APP_NAME on $host (mask=$HEX_MASK)"
log INFO "$greeting"

build_project || {
    log ERROR "build failed"
    exit 1
}

log INFO "done in ${SECONDS}s"
