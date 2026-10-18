#!/usr/bin/env bash
# Publishes a new version of Cosy Kitchen:
#   1. bumps the version in project.godot and the Windows export preset
#   2. runs the tests
#   3. exports build/windows/Cosy-Kitchen.exe and build/web/
#   4. commits + tags, creates a GitHub release with the exe (this is what the in-game
#      Update button looks for), and deploys the web build to GitHub Pages
#
# Usage (Git Bash, from godot/):   tools/release.sh 2.2.0 "What's new in this version"
set -euo pipefail
VER="${1:?usage: tools/release.sh <version> [notes]}"
NOTES="${2:-Cosy Kitchen $VER}"
DIR="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"
GODOT="${GODOT:-/c/Users/maste/Downloads/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe}"
GH="${GH:-$(command -v gh || echo "$LOCALAPPDATA/CosyKitchenTools/gh/bin/gh.exe")}"
REPO="$(grep '^config/github_repo=' "$DIR/project.godot" | cut -d'"' -f2)"

cd "$DIR"
sed -i "s/^config\/version=\".*\"/config\/version=\"$VER\"/" project.godot
sed -i "s/^application\/file_version=\".*\"/application\/file_version=\"$VER.0\"/; s/^application\/product_version=\".*\"/application\/product_version=\"$VER.0\"/" export_presets.cfg

echo "== tests"
tools/gd.sh test | grep -E "^[0-9]+ passed, [0-9]+ failed" | grep -q " 0 failed" || { echo "tests failed"; exit 1; }

echo "== export"
mkdir -p build/windows build/web
"$GODOT" --headless --path . --export-release "Windows Desktop" "build/windows/Cosy-Kitchen.exe" >/dev/null 2>&1
"$GODOT" --headless --path . --export-release "Web" "build/web/index.html" >/dev/null 2>&1
test -s build/windows/Cosy-Kitchen.exe && test -s build/web/index.wasm

echo "== commit + release v$VER"
cd "$ROOT"
git add -A
git commit -m "Release v$VER" || true
git tag -f "v$VER"
git push origin HEAD --tags -f
"$GH" release create "v$VER" "godot/build/windows/Cosy-Kitchen.exe" --repo "$REPO" --title "Cosy Kitchen v$VER" --notes "$NOTES" --latest

echo "== web -> GitHub Pages"
TMP="$(mktemp -d)"
cp -r godot/build/web/. "$TMP/"
touch "$TMP/.nojekyll"
( cd "$TMP" && git init -q -b gh-pages && git add -A && git -c user.name="$(git -C "$ROOT" config user.name)" -c user.email="$(git -C "$ROOT" config user.email)" commit -qm "Web build v$VER" && git push -qf "https://github.com/$REPO.git" gh-pages )
rm -rf "$TMP"
echo "Done: https://github.com/$REPO/releases/latest  ·  https://${REPO%%/*}.github.io/${REPO#*/}/"
