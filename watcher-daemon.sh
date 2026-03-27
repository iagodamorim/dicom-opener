#!/bin/bash
# DICOM Watcher Daemon — checa Downloads a cada 2 segundos
# Fluxo: detecta ZIP → unifica Patient ID → abre ZIP no OsiriX
LOG="$HOME/.dicom-opener/.opened_zips"
PYTHON="$HOME/.dicom-opener/venv/bin/python3"
UNIFY="$HOME/.dicom-opener/unify_patient.py"
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
                ZIP_PATH="$HOME/Downloads/$B"

                # Unifica Patient ID (retorna caminho do ZIP a abrir)
                OPEN_PATH=$("$PYTHON" "$UNIFY" "$ZIP_PATH" 2>/tmp/dicom_unify.log)

                # Fallback: se o script falhou, usa o ZIP original
                if [ -z "$OPEN_PATH" ] || [ ! -e "$OPEN_PATH" ]; then
                    OPEN_PATH="$ZIP_PATH"
                fi

                # Abre OsiriX se necessário
                if ! pgrep -x "OsiriX Lite" > /dev/null; then
                    open -a "OsiriX Lite"
                    sleep 2
                fi

                # Abre o ZIP no OsiriX (mesmo comportamento de antes)
                open -a "OsiriX Lite" "$OPEN_PATH"

                echo "$B" >> "$LOG"

                # Limpa ZIP unificado temporário após alguns segundos
                if [ "$OPEN_PATH" != "$ZIP_PATH" ]; then
                    (sleep 30 && rm -f "$OPEN_PATH") &
                fi

                # Notificação
                UNIFY_MSG=$(cat /tmp/dicom_unify.log 2>/dev/null | head -1)
                if echo "$UNIFY_MSG" | grep -q "UNIFIED"; then
                    osascript -e "display notification \"$B (paciente unificado)\" with title \"DICOM Opener\" sound name \"Glass\""
                else
                    osascript -e "display notification \"Abrindo: $B\" with title \"DICOM Opener\" sound name \"Glass\""
                fi

                break
            fi
        fi
    done

    sleep 2
done
