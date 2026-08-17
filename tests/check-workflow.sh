#!/bin/sh
set -eu

workflow_dir="workflow"
script_path="$workflow_dir/scripts/gemini-chat.applescript"
plist_path="$workflow_dir/info.plist"

osacompile -o /tmp/alfred-gemini-test.scpt "$script_path"
plutil -lint "$plist_path" >/dev/null

normal_script=$(/usr/libexec/PlistBuddy -c "Print :objects:2:config:script" "$plist_path")
temporary_script=$(/usr/libexec/PlistBuddy -c "Print :objects:3:config:script" "$plist_path")

test "$normal_script" = "/usr/bin/osascript ./scripts/gemini-chat.applescript normal"
test "$temporary_script" = "/usr/bin/osascript ./scripts/gemini-chat.applescript temporary"

grep -q 'property geminiProcessName : "Gemini"' "$script_path"
grep -q 'keystroke "n" using {command down}' "$script_path"
grep -q 'keystroke "n" using {command down, shift down}' "$script_path"
! grep -q 'property geminiProcessName : "Web App"' "$script_path"
! grep -q 'click at' "$script_path"
! grep -q 'AXButton' "$script_path"
