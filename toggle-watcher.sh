#!/bin/bash
PLIST="$HOME/Library/LaunchAgents/com.dicomopener.watcher.plist"

if launchctl list | grep -q "com.dicomopener.watcher"; then
  launchctl unload "$PLIST"
  osascript -e 'display notification "Watcher DESATIVADO" with title "DICOM Opener" sound name "Basso"'
else
  launchctl load "$PLIST"
  osascript -e 'display notification "Watcher ATIVADO" with title "DICOM Opener" sound name "Glass"'
fi
