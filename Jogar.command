#!/bin/bash
# Abre o Focus Town RPG direto, sem abrir o editor do Godot (Mac).
# Uso: dê dois cliques neste arquivo. Se o Godot estiver em outro lugar, mude a linha GODOT=.
cd "$(dirname "$0")"
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
if [ ! -x "$GODOT" ]; then
  GODOT="$(mdfind "kMDItemFSName == 'Godot*.app'" | head -1)/Contents/MacOS/Godot"
fi
exec "$GODOT" --path . 
