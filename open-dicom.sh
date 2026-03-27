#!/bin/bash
# =============================================================
# open-dicom.sh
# Pega o ZIP mais recente (padrão telemedicina) e abre no OsiriX
# Pode ser usado manualmente (atalho/Dock) ou pelo watcher
# =============================================================

APP_NAME="OsiriX Lite"
DOWNLOADS_DIR="$HOME/Downloads"
OPENED_LOG="$HOME/.dicom-opener/.opened_zips"

# Cria o log se não existir
touch "$OPENED_LOG"

# Padrão: NOME_MAIUSCULO_COM_UNDERSCORES-NUMERO.zip
PATTERN='^[A-Z][A-Z_]+-[0-9]+\.zip$'

# Encontra o ZIP mais recente que bate com o padrão e ainda não foi aberto
LATEST_ZIP=""
for f in $(ls -t "$DOWNLOADS_DIR"/*.zip 2>/dev/null); do
  BASENAME=$(basename "$f")
  if echo "$BASENAME" | grep -qE "$PATTERN"; then
    if ! grep -qF "$BASENAME" "$OPENED_LOG"; then
      LATEST_ZIP="$f"
      break
    fi
  fi
done

if [ -z "$LATEST_ZIP" ]; then
  osascript -e 'display notification "Nenhum ZIP de exame novo encontrado" with title "DICOM Opener" sound name "Basso"'
  exit 1
fi

FILENAME=$(basename "$LATEST_ZIP")

# Garante que OsiriX está aberto
if ! pgrep -x "OsiriX Lite" > /dev/null; then
  open -a "$APP_NAME"
  sleep 2
fi

# Abre o ZIP no OsiriX
open -a "$APP_NAME" "$LATEST_ZIP"

# Registra como aberto
echo "$FILENAME" >> "$OPENED_LOG"

osascript -e "display notification \"Abrindo: $FILENAME\" with title \"DICOM Opener\" sound name \"Glass\""
