#!/bin/bash
# DICOM Watcher Daemon — checa Downloads a cada 2 segundos
LOG="$HOME/.dicom-opener/.opened_zips"
touch "$LOG"

while true; do
    # Usa osascript para listar ZIPs (bypass TCC)
    ZIPS=$(osascript -e '
tell application "System Events"
    set dlFolder to (path to downloads folder) as text
    set zipFiles to name of every file of folder dlFolder whose name extension is "zip"
end tell
return zipFiles
' 2>/dev/null)

    IFS=', ' read -ra NAMES <<< "$ZIPS"
    for B in "${NAMES[@]}"; do
        if echo "$B" | grep -qE '^[A-Z][A-Z_]+-[0-9]+\.zip$'; then
            if ! grep -qF "$B" "$LOG"; then
                # Abre OsiriX se necessário
                if ! pgrep -x "OsiriX Lite" > /dev/null; then
                    open -a "OsiriX Lite"
                    sleep 2
                fi

                open -a "OsiriX Lite" "$HOME/Downloads/$B"
                echo "$B" >> "$LOG"
                osascript -e "display notification \"Abrindo: $B\" with title \"DICOM Opener\" sound name \"Glass\""
                break
            fi
        fi
    done

    sleep 2
done
