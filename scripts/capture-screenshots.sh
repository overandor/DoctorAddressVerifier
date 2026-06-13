#!/bin/bash
set -e

echo "📸 Capturing Doctor Address Verifier screenshots..."
echo "This script will launch the app and capture screenshots."
echo ""

# Build the app
echo "🔨 Building app..."
swift build -c release

# Create screenshots directory
mkdir -p screenshots

# Launch the app in background
echo "🚀 Launching app..."
.build/release/DoctorAddressVerifier &
APP_PID=$!

# Wait for app to fully launch
sleep 3

# Capture screenshot of menu bar area
echo "📸 Capturing menu bar screenshot..."
screencapture -R0,0,1920,100 screenshots/menubar.png

# If the app has a window, capture it
echo "📸 Capturing app window..."
screencapture -x screenshots/app-window.png

# Kill the app
echo "🛑 Stopping app..."
kill $APP_PID

echo "✅ Screenshots saved to screenshots/"
echo "   - menubar.png"
echo "   - app-window.png"
