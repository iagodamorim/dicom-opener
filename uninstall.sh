#!/bin/bash
# =============================================================
# uninstall.sh — Remove o DICOM Opener do Mac
# =============================================================

echo "=== DICOM Opener — Desinstalação ==="
echo ""

# Para o daemon
echo "[1/3] Parando daemon..."
launchctl unload "$HOME/Library/LaunchAgents/com.dicomopener.watcher.plist" 2>/dev/null || true

# Remove plist
echo "[2/3] Removendo serviço..."
rm -f "$HOME/Library/LaunchAgents/com.dicomopener.watcher.plist"

# Remove pasta
echo "[3/3] Removendo scripts..."
rm -rf "$HOME/.dicom-opener"

echo ""
echo "=== Desinstalação concluída! ==="
echo ""
echo "Remova manualmente (se criou):"
echo "  - /Applications/Toggle Watcher.app"
echo "  - ~/Library/Services/Abrir DICOM.workflow"
