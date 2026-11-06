#!/usr/bin/env bash
# Runs the GdUnit4 suites under res://test headless and writes reports to reports/.
# Exits non-zero on any failed test. Use GODOT=/path/to/godot to override.
set -euo pipefail

GODOT_BIN="${GODOT:-godot}"

cd "$(dirname "$0")/.."

if [ ! -d .godot ]; then
	"$GODOT_BIN" --headless --import
fi

"$GODOT_BIN" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
	--ignoreHeadlessMode -a res://test -rd res://reports -c
