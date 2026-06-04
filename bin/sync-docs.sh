#!/usr/bin/env bash
# Sync the Marketplace docs from a flyokai/flyokai checkout into this repo's
# docs/ tree. Modeled on flyokai/docs' bin/sync-docs.sh.
#
# Usage (local dev):
#   FLYOKAI_SOURCE_DIR=/www/sw6710/flyokai bin/sync-docs.sh
#
# Usage (CI): the workflow clones flyokai/flyokai to /tmp/flyokai-source and
# exports FLYOKAI_SOURCE_DIR=/tmp/flyokai-source before invoking this script.
#
# This is the **only** way content lands under docs/. Do not hand-edit docs/*.md;
# the next sync overwrites them. Edit upstream in flyokai/flyokai's
# marketplace-docs/docs/ instead.

set -euo pipefail

SRC="${FLYOKAI_SOURCE_DIR:?Set FLYOKAI_SOURCE_DIR to a flyokai/flyokai checkout root}"
SRC_DOCS="$SRC/marketplace-docs/docs"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$REPO_ROOT/docs"
SITE_DOMAIN="${SITE_DOMAIN:-marketplace.flyokai.com}"

[[ -d "$SRC_DOCS" ]]          || { echo "Error: $SRC_DOCS not found" >&2; exit 1; }
[[ -f "$SRC_DOCS/index.md" ]] || { echo "Error: $SRC_DOCS/index.md not found" >&2; exit 1; }

# Wipe and recreate so pages deleted upstream disappear from the site too.
rm -rf "$DEST"
mkdir -p "$DEST"

# The marketplace pages use only intra-site relative links (architecture.md, …)
# and absolute external links (github.com/flyokai, docs.flyokai.com), so nothing
# needs rewriting today. Keep this hook so cross-package links can be rewritten
# to absolute GitHub URLs later, the way flyokai/docs does.
rewrite_links() {
    sed -E \
        -e 's@\((\.\./)+([a-z][a-z0-9_-]*)/(README|AGENTS)\.md(#[a-z0-9_-]+)?\)@(https://github.com/flyokai/\2/blob/main/\3.md\4)@g'
}

for f in "$SRC_DOCS"/*.md; do
    rewrite_links < "$f" > "$DEST/$(basename "$f")"
done

# Brand assets (logo, favicon, CSS) — copied verbatim; mkdocs serves them as-is.
if [[ -d "$SRC_DOCS/assets" ]]; then
    cp -R "$SRC_DOCS/assets" "$DEST/assets"
fi

# Custom domain for GitHub Pages (written into the published gh-pages branch).
echo "$SITE_DOMAIN" > "$DEST/CNAME"

echo "Synced from: $SRC_DOCS"
echo "Files in $DEST:"
ls "$DEST"
