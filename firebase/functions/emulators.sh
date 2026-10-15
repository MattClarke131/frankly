#!/usr/bin/env bash
set -euo pipefail

# Read FIREBASE_PROJECT_ID from client/.env (not committed) so the emulator project
# matches what the client uses. Fails fast with an error if the file or variable is missing.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_ENV="$SCRIPT_DIR/../../client/.env"
if [[ ! -f "$CLIENT_ENV" ]]; then
  echo "ERROR: client/.env not found at $CLIENT_ENV" >&2
  echo "Copy client/.env.local.example to client/.env and set FIREBASE_PROJECT_ID." >&2
  exit 1
fi
PROJECT_ID=$(grep -m1 '^FIREBASE_PROJECT_ID=' "$CLIENT_ENV" | sed "s/^FIREBASE_PROJECT_ID=//;s/['\"]//g" || true)
if [[ -z "$PROJECT_ID" ]]; then
  echo "ERROR: FIREBASE_PROJECT_ID is not set in $CLIENT_ENV" >&2
  exit 1
fi

if [[ "${SKIP_DART_BUILD:-}" != "1" ]]; then
  dart run build_runner build --output=build
fi

inspect_flag=()
if [[ "${FRANKLY_DEBUG_FUNCTIONS:-0}" == "1" ]]; then
  inspect_flag=(--inspect-functions)
fi

# Export GOOGLE_APPLICATION_CREDENTIALS if a local service account key exists
# and the variable is not already set. Enables file.getSignedUrl() in the emulator.
SERVICE_ACCOUNT_KEY="$SCRIPT_DIR/service-account-key.json"
if [[ -f "$SERVICE_ACCOUNT_KEY" && -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
  export GOOGLE_APPLICATION_CREDENTIALS="$SERVICE_ACCOUNT_KEY"
fi

# Start the Firebase emulators with the specified services and project ID. If the inspect flag is set, it will be included in the command.
# Import from FRANKLY_IMPORT_DIR (default: ./data if present) and, if FRANKLY_EXPORT_DIR
# is set, save emulator data there on exit. See emulators-data-env.sh.
# shellcheck source=emulators-data-env.sh
source "$SCRIPT_DIR/emulators-data-env.sh"
validate_data_env "$SCRIPT_DIR/data" || exit 1

if [[ -z "$IMPORT_DIR" ]]; then
  echo "No data to import, starting with empty emulators."
else
  echo "Importing emulator data from $IMPORT_DIR"
fi
if [[ -n "$EXPORT_DIR" ]]; then
  echo "Emulator data will be exported to $EXPORT_DIR on exit"
fi

# Start with the FUNCTIONS_EMULATOR environment variable so functions know they are running in the emulator.
export FUNCTIONS_EMULATOR=true

exec firebase emulators:start \
  --only firestore,functions,auth,pubsub,database \
  --project "$PROJECT_ID" \
  ${inspect_flag:+"${inspect_flag[@]}"} \
  ${IMPORT_DIR:+"--import=$IMPORT_DIR"} \
  ${EXPORT_DIR:+"--export-on-exit=$EXPORT_DIR"}