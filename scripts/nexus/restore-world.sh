#!/usr/bin/env bash
# Fail-closed restore of the current NEXUS world-state release.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

readonly STORAGE_REPO="${STORAGE_REPO:-cleoleobel/nexus-storage}"
readonly RESTORE_ENABLED="${RESTORE_WORLD:-yes}"
readonly DOWNLOAD_DIR="world_download"
readonly STAGING_DIR="world_staging_restore"
readonly PREVIOUS_WORLD="world.restore-previous"
readonly DIAG_DIR="session_diagnostics"

mkdir -p "$DIAG_DIR"
printf '%s\n' "UNVERIFIED" > "$DIAG_DIR/status_restore_sha.txt"

cleanup_staging() {
    rm -rf "$DOWNLOAD_DIR" "$STAGING_DIR"
}
trap cleanup_staging EXIT

echo "=================================================="
echo "   NEXUS FAIL-CLOSED WORLD RESTORE"
echo "=================================================="

if [ "$RESTORE_ENABLED" = "no" ]; then
    echo "[WORLD] Restore explicitly disabled; existing local state will be used."
    printf '%s\n' "SKIPPED" > "$DIAG_DIR/status_restore_sha.txt"
    exit 0
fi
if [ "$RESTORE_ENABLED" != "yes" ]; then
    echo "[WORLD ERROR] RESTORE_WORLD must be exactly 'yes' or 'no'; got '$RESTORE_ENABLED'."
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_restore_sha.txt"
    exit 1
fi

for required_command in gh jq sha256sum tar; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        echo "[WORLD ERROR] Required command is missing: $required_command"
        printf '%s\n' "FAIL" > "$DIAG_DIR/status_restore_sha.txt"
        exit 1
    fi
done

if [ -z "${NEXUS_STORAGE_TOKEN:-}" ]; then
    echo "[WORLD ERROR] NEXUS_STORAGE_TOKEN is required for restore."
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_restore_sha.txt"
    exit 1
fi
export GH_TOKEN="$NEXUS_STORAGE_TOKEN"

rm -rf "$DOWNLOAD_DIR" "$STAGING_DIR"
mkdir -p "$DOWNLOAD_DIR" "$STAGING_DIR"

echo "[WORLD] Downloading current-manifest.json from $STORAGE_REPO."
if ! gh release download world-state --repo "$STORAGE_REPO" \
    --pattern "current-manifest.json" --dir "$DOWNLOAD_DIR" --clobber; then
    echo "[WORLD FATAL] Restore was requested but the current manifest could not be downloaded."
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_restore_sha.txt"
    exit 1
fi

MANIFEST_FILE="$DOWNLOAD_DIR/current-manifest.json"
if ! jq -e 'type == "object" and (.asset | type == "string") and (.sha256 | type == "string")' \
    "$MANIFEST_FILE" >/dev/null; then
    echo "[WORLD FATAL] current-manifest.json is malformed."
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_restore_sha.txt"
    exit 1
fi

TARGET_ASSET="$(jq -r '.asset' "$MANIFEST_FILE")"
EXPECTED_SHA="$(jq -r '.sha256 | ascii_downcase' "$MANIFEST_FILE")"

if [[ ! "$TARGET_ASSET" =~ ^world-run-[A-Za-z0-9._-]+-[a-fA-F0-9]{64}\.tar\.gz$ ]]; then
    echo "[WORLD FATAL] Manifest asset name is outside the allowed format: $TARGET_ASSET"
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_restore_sha.txt"
    exit 1
fi
if [[ ! "$EXPECTED_SHA" =~ ^[a-f0-9]{64}$ ]]; then
    echo "[WORLD FATAL] Manifest SHA-256 is invalid."
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_restore_sha.txt"
    exit 1
fi

echo "[WORLD] Downloading immutable snapshot $TARGET_ASSET."
gh release download world-state --repo "$STORAGE_REPO" \
    --pattern "$TARGET_ASSET" --dir "$DOWNLOAD_DIR" --clobber

ARCHIVE="$DOWNLOAD_DIR/$TARGET_ASSET"
LOCAL_SHA="$(sha256sum "$ARCHIVE" | awk '{print $1}')"
if [ "$LOCAL_SHA" != "$EXPECTED_SHA" ]; then
    echo "[WORLD FATAL] Snapshot SHA-256 mismatch."
    echo "Expected: $EXPECTED_SHA"
    echo "Actual:   $LOCAL_SHA"
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_restore_sha.txt"
    exit 1
fi

# Reject path traversal, unexpected payloads, symlinks and hardlinks before
# extraction. State snapshots contain only the world and player access files.
while IFS= read -r archive_entry; do
    archive_entry="${archive_entry#./}"
    case "$archive_entry" in
        ""|".") continue ;;
        /*|../*|*/../*|*/..|*\\*)
            echo "[WORLD FATAL] Unsafe archive path: $archive_entry"
            printf '%s\n' "FAIL" > "$DIAG_DIR/status_restore_sha.txt"
            exit 1
            ;;
        world|world/|world/*|whitelist.json|ops.json|banned-ips.json|banned-players.json|usercache.json) ;;
        *)
            echo "[WORLD FATAL] Unexpected snapshot entry: $archive_entry"
            printf '%s\n' "FAIL" > "$DIAG_DIR/status_restore_sha.txt"
            exit 1
            ;;
    esac
done < <(tar -tzf "$ARCHIVE")

UNSAFE_TYPE="$(tar -tvzf "$ARCHIVE" | awk 'substr($1,1,1) != "-" && substr($1,1,1) != "d" { print; exit }')"
if [ -n "$UNSAFE_TYPE" ]; then
    echo "[WORLD FATAL] Snapshot contains a link or unsupported archive type:"
    echo "$UNSAFE_TYPE"
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_restore_sha.txt"
    exit 1
fi

tar --no-same-owner --no-same-permissions -xzf "$ARCHIVE" -C "$STAGING_DIR"
if [ ! -f "$STAGING_DIR/world/level.dat" ]; then
    echo "[WORLD FATAL] Verified snapshot does not contain world/level.dat."
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_restore_sha.txt"
    exit 1
fi

rm -rf "$PREVIOUS_WORLD"
if [ -d world ]; then
    mv world "$PREVIOUS_WORLD"
fi

if ! mv "$STAGING_DIR/world" world; then
    echo "[WORLD FATAL] Could not promote the staged world; rolling back."
    if [ -d "$PREVIOUS_WORLD" ] && [ ! -d world ]; then
        mv "$PREVIOUS_WORLD" world
    fi
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_restore_sha.txt"
    exit 1
fi

for state_file in whitelist.json ops.json banned-ips.json banned-players.json usercache.json; do
    if [ -f "$STAGING_DIR/$state_file" ]; then
        mv -f "$STAGING_DIR/$state_file" "$state_file"
    fi
done

rm -rf "$PREVIOUS_WORLD"
sync
printf '%s\n' "PASS" > "$DIAG_DIR/status_restore_sha.txt"
echo "[WORLD PASS] Restored and promoted $TARGET_ASSET ($LOCAL_SHA)."
