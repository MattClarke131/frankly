#!/usr/bin/env bash
# Sourced by run-dev.sh and emulators.sh. Not meant to be executed directly.
#
# Validates FRANKLY_IMPORT_DIR and FRANKLY_EXPORT_DIR and sets:
#   IMPORT_DIR  Absolute path to import on startup, or "" for no import.
#   EXPORT_DIR  Absolute path to export to on exit, or "" for no export.
#
# Relative paths resolve against the directory the command was run from
# (INIT_CWD under npm, otherwise the current directory).
# Returns non-zero with a message if a variable is set but invalid.

_frankly_resolve_path() {
  local path="$1"
  if [[ "$path" != /* ]]; then
    path="${INIT_CWD:-$PWD}/$path"
  fi
  printf '%s\n' "$path"
}

_frankly_data_env_fail() {
  echo "ERROR: $*" >&2
  return 1
}

validate_data_env() {
  local default_import_dir="$1"

  IMPORT_DIR=""
  EXPORT_DIR=""

  if [[ -n "${FRANKLY_IMPORT_DIR+x}" ]]; then
    if [[ -z "$FRANKLY_IMPORT_DIR" ]]; then
      _frankly_data_env_fail "FRANKLY_IMPORT_DIR is set but empty. Unset it or point it at an emulator export directory." || return 1
    fi
    IMPORT_DIR="$(_frankly_resolve_path "$FRANKLY_IMPORT_DIR")"
    if [[ ! -d "$IMPORT_DIR" ]]; then
      _frankly_data_env_fail "FRANKLY_IMPORT_DIR is not a directory: $IMPORT_DIR" || return 1
    fi
    if [[ ! -f "$IMPORT_DIR/firebase-export-metadata.json" ]]; then
      _frankly_data_env_fail "FRANKLY_IMPORT_DIR is not an emulator export (missing firebase-export-metadata.json): $IMPORT_DIR" || return 1
    fi
  elif [[ -d "$default_import_dir" ]]; then
    IMPORT_DIR="$default_import_dir"
  fi

  if [[ -n "${FRANKLY_EXPORT_DIR+x}" ]]; then
    if [[ -z "$FRANKLY_EXPORT_DIR" ]]; then
      _frankly_data_env_fail "FRANKLY_EXPORT_DIR is set but empty. Unset it or point it at a directory to save emulator data to." || return 1
    fi
    EXPORT_DIR="$(_frankly_resolve_path "$FRANKLY_EXPORT_DIR")"
    if [[ -e "$EXPORT_DIR" && ! -d "$EXPORT_DIR" ]]; then
      _frankly_data_env_fail "FRANKLY_EXPORT_DIR exists but is not a directory: $EXPORT_DIR" || return 1
    fi
  fi
}
