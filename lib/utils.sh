#!/usr/bin/env bash
# ================================================================
# bun_buildpack — shared utilities
# ================================================================

LOG_PREFIX="[bun]"

log_info()   { echo "-----> ${LOG_PREFIX} $*"; }
log_detail() { echo "       $*"; }
log_warn()   { echo " !!    ${LOG_PREFIX} WARNING: $*"; }
log_error()  { echo " !!    ${LOG_PREFIX} ERROR: $*"; }

# ── Guard: python3 must be available for JSON parsing ──
require_python3() {
  command -v python3 >/dev/null 2>&1 || {
    log_error "python3 not found on staging image (required for JSON parsing)"
    log_error "Contact platform team or use a cflinuxfs4-compat stack"
    exit 1
  }
}

# ── Read fields from package.json using python3 (available on cflinuxfs4) ──
# Usage: read_package_field "/path/to/package.json" "dotted.key.path"
# Examples:
#   read_package_field pkg.json "name"              → package name
#   read_package_field pkg.json "engines.bun"       → engines.bun value
#   read_package_field pkg.json "scripts.start"     → start script
read_package_field() {
  local file="$1" field="$2"
  local result
  result=$(python3 -c "
import json, sys
try:
    data = json.load(open('${file}'))
    keys = '${field}'.split('.')
    val = data
    for k in keys:
        val = val[k]
    print(val)
except (KeyError, TypeError, FileNotFoundError, json.JSONDecodeError):
    pass
" 2>/dev/null || true)
  echo "$result"
}

# ── Get first dependency name from package.json ──
read_first_dependency() {
  local file="$1"
  local result
  result=$(python3 -c "
import json
try:
    data = json.load(open('${file}'))
    deps = data.get('dependencies', {})
    if deps:
        print(next(iter(deps)))
except (FileNotFoundError, json.JSONDecodeError, StopIteration):
    pass
" 2>/dev/null || true)
  echo "$result"
}

# ── Version defaults ──
BUN_DEFAULT_VERSION="1.2.9"

# ── Resolve a Bun version constraint to a downloadable version ──
#
# Deliberately stricter than the Node.js resolver. Bun's release cadence
# is fast and unpredictable — without an embedded version catalog, fuzzy
# resolution is unreliable.
#
# Supported formats:
#   exact:    "1.2.9"
#   prefixed: "^1.2.9", "~1.2.9", ">=1.2.9" (strip prefix, use base)
#   empty:    "" (returns BUN_DEFAULT_VERSION)
#
# NOT supported (returns error via RESOLVE_ERROR):
#   major only:    "1"
#   major.minor:   "1.2"
#   wildcards:     "1.x", "1.2.x"
#   ranges:        ">=1 <2", "1 || 2", "1 - 2"
#   star:          "*"
resolve_bun_version() {
  local requested="$1"
  RESOLVE_ERROR=""
  RESOLVED_VERSION=""

  if [ -z "$requested" ]; then
    RESOLVED_VERSION="$BUN_DEFAULT_VERSION"
    echo "$RESOLVED_VERSION"
    return
  fi

  # Reject unsupported range expressions: spaces, ||, hyphen ranges, lone *
  if echo "$requested" | grep -qE '(\s|[|]{2}|[0-9]+\s*-\s*[0-9]+|^\*$)'; then
    RESOLVE_ERROR="Unsupported engines.bun constraint: '${requested}'. Pin an exact version in engines.bun (e.g., \"1.2.9\") or use BUN_OVERRIDE_VERSION."
    return 1
  fi

  # Strip leading semver operators
  local cleaned
  cleaned=$(echo "$requested" | sed 's/^[>=^~]*//')

  if [ -z "$cleaned" ]; then
    RESOLVED_VERSION="$BUN_DEFAULT_VERSION"
    echo "$RESOLVED_VERSION"
    return
  fi

  # Reject wildcards (.x)
  if echo "$cleaned" | grep -qE '\.x'; then
    RESOLVE_ERROR="Unsupported engines.bun constraint: '${requested}'. Wildcards are not supported. Pin an exact version (e.g., \"1.2.9\") or use BUN_OVERRIDE_VERSION."
    return 1
  fi

  # Reject if cleaned value contains non-version characters
  if ! echo "$cleaned" | grep -qE '^[0-9]+(\.[0-9]+){0,2}$'; then
    RESOLVE_ERROR="Unsupported engines.bun constraint: '${requested}'. Could not extract a valid version number."
    return 1
  fi

  local dots
  dots=$(echo "$cleaned" | tr -cd '.' | wc -c)

  case "$dots" in
    0) # Major only, e.g. "1" — ambiguous without a version catalog
      RESOLVE_ERROR="Unsupported engines.bun constraint: '${requested}'. Major-only versions are ambiguous. Pin an exact version (e.g., \"1.2.9\") or use BUN_OVERRIDE_VERSION."
      return 1
      ;;
    1) # Major.minor, e.g. "1.2" — ambiguous without a version catalog
      RESOLVE_ERROR="Unsupported engines.bun constraint: '${requested}'. Major.minor versions are ambiguous. Pin an exact version (e.g., \"1.2.9\") or use BUN_OVERRIDE_VERSION."
      return 1
      ;;
    2) # Exact version, e.g. "1.2.9"
      RESOLVED_VERSION="$cleaned"
      echo "$RESOLVED_VERSION"
      ;;
    *)
      RESOLVE_ERROR="Unsupported engines.bun constraint: '${requested}'. Could not extract a valid version number."
      return 1
      ;;
  esac
}
