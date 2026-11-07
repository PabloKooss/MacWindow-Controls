#!/usr/bin/env bash
# Local install for the current user (no changes to KDE internal files).
set -uo pipefail
cd "$(dirname "$0")" || exit 1
SRC="$(pwd -P)"
ID=io.github.macwindowcontrols
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/$ID"

case "$SRC" in
    */Trash/*|*/.Trash*)
        echo "!! This folder is inside the Trash:"
        echo "   $SRC"
        echo "   Extract the zip into a normal folder and run install.sh from there."
        exit 1 ;;
esac

[ -f package/metadata.json ] || { echo "!! package/metadata.json not found in $SRC"; exit 1; }
command -v kpackagetool6 >/dev/null || { echo "!! kpackagetool6 not found"; exit 1; }

version_of() { grep -o '"Version": *"[^"]*"' "$1" 2>/dev/null | sed 's/.*: *"\(.*\)"/\1/'; }
SRC_VER="$(version_of package/metadata.json)"
OLD_VER="$(version_of "$DEST/metadata.json")"

echo "== Source:    $SRC"
echo "== Version:   $SRC_VER (currently installed: ${OLD_VER:-none})"

if ! kpackagetool6 --type Plasma/Applet --upgrade package; then
    echo "-- upgrade failed, trying a fresh install"
    if ! kpackagetool6 --type Plasma/Applet --install package; then
        echo "!! Installation failed. Try: ./uninstall.sh && ./install.sh"
        exit 1
    fi
fi

NEW_VER="$(version_of "$DEST/metadata.json")"
echo
echo "== Installed: $NEW_VER  ($DEST)"
if [ "$NEW_VER" != "$SRC_VER" ]; then
    echo "!! Installed version ($NEW_VER) does not match this folder ($SRC_VER)."
    exit 1
fi
echo
echo "Now restart the shell so the new QML is loaded:"
echo "  systemctl --user restart plasma-plasmashell.service"
echo "and check the log for: [MacWindow] loaded: build $SRC_VER"
