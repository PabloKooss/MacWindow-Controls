#!/usr/bin/env bash
# Removes the widget from the current user's Plasma packages (no KDE internal files touched).
set -uo pipefail
ID=io.github.macwindowcontrols
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/$ID"

command -v kpackagetool6 >/dev/null || { echo "!! kpackagetool6 not found"; exit 1; }

if [ ! -d "$DEST" ]; then
    echo "Not installed ($DEST does not exist). Nothing to remove."
    exit 0
fi

if ! kpackagetool6 --type Plasma/Applet --remove "$ID"; then
    echo "!! Removal failed."
    exit 1
fi

echo "Removed $ID."
echo "If the widget was in a panel, restart the shell to clear it:"
echo "  systemctl --user restart plasma-plasmashell.service"
