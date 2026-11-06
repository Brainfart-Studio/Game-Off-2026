#!/usr/bin/env bash
# Headless check: imports the project, runs the main scene for 300 frames,
# and fails on any script or load error. Use GODOT=/path/to/godot to override.
set -euo pipefail

GODOT_BIN="${GODOT:-godot}"
PATTERN='SCRIPT ERROR|Parse Error|Compile Error|Failed to load|Failed loading|Invalid call|Cannot call|Nonexistent|null instance|ERROR:'

cd "$(dirname "$0")/.."
LOG_DIR=".godot/check"
mkdir -p "$LOG_DIR"

scan() {
	local name="$1" log="$2" status="$3"
	if grep -E "$PATTERN" "$log"; then
		echo "check: $name failed (full log: $log)" >&2
		exit 1
	fi
	if [ "$status" -ne 0 ]; then
		echo "check: $name exited with $status (full log: $log)" >&2
		exit 1
	fi
}

status=0
"$GODOT_BIN" --headless --import >"$LOG_DIR/import.log" 2>&1 || status=$?
scan import "$LOG_DIR/import.log" "$status"

status=0
"$GODOT_BIN" --headless --quit-after 300 >"$LOG_DIR/run.log" 2>&1 || status=$?
scan run "$LOG_DIR/run.log" "$status"

echo "check: ok"
