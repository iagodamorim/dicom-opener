#!/bin/bash
# =============================================================
# install.sh — Instala o DICOM Opener no Mac
# Uso: git clone → cd dicom-opener → ./install.sh
# =============================================================

set -e

INSTALL_DIR="$HOME/.dicom-opener"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.dicomopener.watcher.plist"

echo "=== DICOM Opener — Instalação ==="
echo ""

# 1. Copia scripts para ~/.dicom-opener/
echo "[1/4] Copiando scripts para $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp open-dicom.sh toggle-watcher.sh watcher-daemon.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/open-dicom.sh"
chmod +x "$INSTALL_DIR/toggle-watcher.sh"
chmod +x "$INSTALL_DIR/watcher-daemon.sh"
touch "$INSTALL_DIR/.opened_zips"

# 2. Gera o plist com o caminho correto do usuário
echo "[2/4] Criando serviço macOS (launchd)..."
mkdir -p "$PLIST_DIR"
cat > "$PLIST_DIR/$PLIST_NAME" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.dicomopener.watcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/watcher-daemon.sh</string>
    </array>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

# 3. Ativa o daemon
echo "[3/4] Ativando daemon..."
launchctl unload "$PLIST_DIR/$PLIST_NAME" 2>/dev/null || true
launchctl load "$PLIST_DIR/$PLIST_NAME"

# 4. Verifica
echo "[4/4] Verificando..."
if launchctl list | grep -q "com.dicomopener.watcher"; then
    echo ""
    echo "=== Instalação concluída! ==="
    echo ""
    echo "O daemon está rodando. ZIPs de exame baixados em ~/Downloads"
    echo "serão abertos automaticamente no OsiriX Lite."
    echo ""
    echo "Comandos úteis:"
    echo "  Ligar/desligar:  ~/.dicom-opener/toggle-watcher.sh"
    echo "  Abrir manual:    ~/.dicom-opener/open-dicom.sh"
    echo "  Limpar histórico: > ~/.dicom-opener/.opened_zips"
    echo ""
    echo "Próximo passo (opcional):"
    echo "  Crie atalhos no Automator apontando para os scripts acima."
    echo "  Veja o README.md para instruções detalhadas."
else
    echo "ERRO: daemon não iniciou. Verifique as permissões."
    exit 1
fi
