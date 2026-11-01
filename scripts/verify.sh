#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-/Applications/Godot_mono.app/Contents/MacOS/Godot}"
cd "$project_dir"

check_gameplay_log() {
  if rg -n 'SCRIPT ERROR:|Parse Error:|Failed to load script|Invalid call\.' "$1"; then
    echo "Gameplay script errors found in $1" >&2
    exit 1
  fi
}

run_suite() {
  "$godot_bin" --headless --path . --log-file "$1" --script "$2" -- --qa
  check_gameplay_log "$1"
}
run_suite /tmp/berania-models.log tests/run_tests.gd
run_suite /tmp/berania-flow.log tests/demo_flow_test.gd
run_suite /tmp/berania-workshop.log tests/workshop_test.gd
run_suite /tmp/berania-region-tests.log tests/region_test.gd
"$godot_bin" --headless --main-pack builds/BeraniaDemo.pck --log-file /tmp/berania-pack-smoke.log --quit-after 20 -- --qa
check_gameplay_log /tmp/berania-pack-smoke.log
"$godot_bin" --headless --main-pack builds/BeraniaDemo.pck --log-file /tmp/berania-pack-region-smoke.log --quit-after 60 -- --qa --region-review --capacity-15
check_gameplay_log /tmp/berania-pack-region-smoke.log
