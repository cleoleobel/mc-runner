#!/usr/bin/env bash
# Verify the NEXUS server bundle checksum and extraction safety.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

readonly DOWNLOAD_DIR="download_bundle"
readonly ARCHIVE="$DOWNLOAD_DIR/server-bundle.tar.gz"
readonly CHECKSUM_FILE="$DOWNLOAD_DIR/checksums.sha256"

echo "=== VERIFYING NEXUS SERVER BUNDLE ==="

if [ ! -f "$ARCHIVE" ] || [ ! -f "$CHECKSUM_FILE" ]; then
    echo "[VERIFY ERROR] server-bundle.tar.gz or checksums.sha256 is missing."
    exit 1
fi

sed -i '1s/^\xef\xbb\xbf//' "$CHECKSUM_FILE" 2>/dev/null || true
sed -i 's/\r$//' "$CHECKSUM_FILE"

if ! awk '
    BEGIN { valid = 1; count = 0 }
    {
        count++
        sha = substr($0, 1, 64)
        suffix = substr($0, 65)
        if (length(sha) != 64 || sha !~ /^[a-fA-F0-9]+$/ || suffix != "  server-bundle.tar.gz") valid = 0
    }
    END { exit(valid && count == 1 ? 0 : 1) }
' "$CHECKSUM_FILE"; then
    echo "[VERIFY ERROR] checksums.sha256 must contain exactly one approved bundle entry."
    exit 1
fi

(
    cd "$DOWNLOAD_DIR"
    sha256sum --check --strict checksums.sha256
)

ARCHIVE_LIST="$(tar -tzf "$ARCHIVE")"
while IFS= read -r archive_entry; do
    archive_entry="${archive_entry#./}"
    case "$archive_entry" in
        ""|".") continue ;;
        /*|../*|*/../*|*/..|*\\*)
            echo "[VERIFY ERROR] Unsafe path in server bundle: $archive_entry"
            exit 1
            ;;
        run.sh|server.properties|manifest.json|eula.txt|user_jvm_args.txt) ;;
        mods|mods/*|config|config/*|defaultconfigs|defaultconfigs/*|libraries|libraries/*|tacz|tacz/*) ;;
        *)
            echo "[VERIFY ERROR] Unexpected top-level bundle entry: $archive_entry"
            exit 1
            ;;
    esac
done <<< "$ARCHIVE_LIST"

UNSAFE_TYPE="$(tar -tvzf "$ARCHIVE" | awk 'substr($1,1,1) != "-" && substr($1,1,1) != "d" { print; exit }')"
if [ -n "$UNSAFE_TYPE" ]; then
    echo "[VERIFY ERROR] Bundle contains a symlink, hardlink or unsupported entry:"
    echo "$UNSAFE_TYPE"
    exit 1
fi

for required_path in run.sh server.properties manifest.json eula.txt mods/ libraries/; do
    if ! grep -E "^\./?${required_path}" <<< "$ARCHIVE_LIST" >/dev/null; then
        echo "[VERIFY ERROR] Required bundle path is missing: $required_path"
        exit 1
    fi
done

echo "[VERIFY PASS] Checksum, paths, entry types and required payloads are valid."
if [ -f "$DOWNLOAD_DIR/manifest.json" ]; then
    echo "[VERIFY MANIFEST]"
    cat "$DOWNLOAD_DIR/manifest.json"
fi
