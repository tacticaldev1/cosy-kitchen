#!/usr/bin/env bash
# Runs the Godot console binary against this project. Usage:
#   tools/gd.sh import                    # (re)import assets, refresh class cache
#   tools/gd.sh shot <scene> <out.png> [frames] [WxH] [--user-args...]   # screenshot a scene
#   tools/gd.sh run [args...]             # run the project
#   tools/gd.sh test                      # headless test suite
GODOT="${GODOT:-/c/Users/maste/Downloads/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe}"
DIR="$(cd "$(dirname "$0")/.." && pwd)"
cmd="$1"; shift
case "$cmd" in
  import) "$GODOT" --headless --path "$DIR" --import 2>&1 | grep -v "^$" ;;
  shot)
    scene="$1"; out="$2"; frames="${3:-30}"; res="${4:-1600x900}"; shift 4 2>/dev/null
    "$GODOT" --path "$DIR" --windowed --resolution "$res" --position 40,40 "$scene" -- --shot="$out" --frames="$frames" "$@" 2>&1 | grep -v "^$" ;;
  run) "$GODOT" --path "$DIR" "$@" 2>&1 ;;
  test) "$GODOT" --headless --path "$DIR" res://tests/test_runner.tscn -- --test 2>&1 | grep -v "^$" ;;
  *) "$GODOT" --path "$DIR" "$cmd" "$@" 2>&1 ;;
esac
