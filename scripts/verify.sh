#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-/Applications/Godot_mono.app/Contents/MacOS/Godot}"
cd "$project_dir"
"$godot_bin" --headless --path . --log-file /tmp/berania-models.log --script tests/run_tests.gd -- --qa
"$godot_bin" --headless --path . --log-file /tmp/berania-flow.log --script tests/demo_flow_test.gd -- --qa
"$godot_bin" --headless --main-pack builds/BeraniaDemo.pck --log-file /tmp/berania-pack-smoke.log --quit-after 20 -- --qa
