#!/bin/bash
set -e

APP_PATH=".build/arm64-apple-macosx/debug/ClipboardManager"
PASS=0
FAIL=0

echo "=== ClipboardManager E2E Test ==="
echo ""

# Build
echo "[1/5] Building..."
swift build -c debug 2>&1 | tail -1

# Kill any existing instance
pkill -f "ClipboardManager" 2>/dev/null || true
sleep 1

# Launch app
echo "[2/5] Launching app..."
"$APP_PATH" &
APP_PID=$!
sleep 2

# Verify app is running
if ps -p $APP_PID > /dev/null 2>&1; then
    echo "  ✓ App launched (PID: $APP_PID)"
    ((PASS++))
else
    echo "  ✗ App failed to launch"
    ((FAIL++))
    exit 1
fi

# Check menu bar icon exists
echo "[3/5] Checking menu bar status item..."
MENU_CHECK=$(osascript -e '
tell application "System Events"
    tell process "ClipboardManager"
        return exists menu bar 2
    end tell
end tell
' 2>/dev/null || echo "false")

if [ "$MENU_CHECK" = "true" ]; then
    echo "  ✓ Menu bar item exists"
    ((PASS++))
else
    echo "  ✗ Menu bar item not found (may need accessibility permission)"
    ((FAIL++))
fi

# Simulate Command+Shift+V hotkey
echo "[4/5] Simulating ⌘⇧V hotkey..."
osascript -e '
tell application "System Events"
    key code 9 using {command down, shift down}
end tell
' 2>/dev/null
sleep 1

# Check if panel window appeared
WINDOW_CHECK=$(osascript -e '
tell application "System Events"
    tell process "ClipboardManager"
        return count of windows
    end tell
end tell
' 2>/dev/null || echo "0")

if [ "$WINDOW_CHECK" -gt "0" ] 2>/dev/null; then
    echo "  ✓ Panel appeared ($WINDOW_CHECK window(s))"
    ((PASS++))
else
    echo "  ✗ Panel did not appear (windows: $WINDOW_CHECK)"
    ((FAIL++))
fi

# Simulate hotkey again to toggle off
echo "[5/5] Simulating ⌘⇧V again to close..."
osascript -e '
tell application "System Events"
    key code 9 using {command down, shift down}
end tell
' 2>/dev/null
sleep 1

WINDOW_AFTER=$(osascript -e '
tell application "System Events"
    tell process "ClipboardManager"
        return count of windows
    end tell
end tell
' 2>/dev/null || echo "0")

if [ "$WINDOW_AFTER" = "0" ] 2>/dev/null; then
    echo "  ✓ Panel closed"
    ((PASS++))
else
    echo "  ✗ Panel still visible (windows: $WINDOW_AFTER)"
    ((FAIL++))
fi

# Cleanup
kill $APP_PID 2>/dev/null
wait $APP_PID 2>/dev/null

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ] && exit 0 || exit 1
