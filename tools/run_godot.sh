#!/bin/bash
# Roda o Godot com limite de tempo (macOS não tem `timeout`).
# Uso: tools/run_godot.sh <segundos> [args do godot...]
LIMIT="$1"; shift
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
cd "$(dirname "$0")/.."
"$GODOT" --path . "$@" &
PID=$!
( sleep "$LIMIT"; kill -9 $PID 2>/dev/null ) >/dev/null 2>&1 &
WATCH=$!
wait $PID 2>/dev/null
CODE=$?
kill $WATCH 2>/dev/null
exit $CODE
