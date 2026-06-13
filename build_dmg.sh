#!/bin/bash
set -e

APP_NAME="DoctorAddressVerifier"
BUNDLE_ID="com.membra.doctor-address-verifier"
VERSION="1.0.0"

echo "=== Building Release Binary ==="
cd "$(dirname "$0")"
swift build -c release

BINARY=".build/release/$APP_NAME"
APP_DIR=".build/release/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "=== Creating .app Bundle ==="
rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"

# Copy binary
cp "$BINARY" "$MACOS/$APP_NAME"
chmod +x "$MACOS/$APP_NAME"

# Copy CLI into Resources (dist only, no node_modules — assume user has CLI deps installed)
CLI_SRC="../DoctorAddressVerifierCLI"
if [ -d "$CLI_SRC/dist" ]; then
    mkdir -p "$RESOURCES/cli"
    cp -R "$CLI_SRC/dist" "$RESOURCES/cli/"
    cp "$CLI_SRC/package.json" "$RESOURCES/cli/" 2>/dev/null || true
fi

# Create Info.plist
cat > "$CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>Doctor Address Verifier</string>
    <key>CFBundleDisplayName</key>
    <string>Doctor Address Verifier</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "=== Creating DMG ==="
DMG_NAME="$APP_NAME-$VERSION.dmg"
TMP_DMG=".build/release/tmp.dmg"
MOUNT_DIR="/Volumes/$APP_NAME"

# Clean up previous
rm -f "$TMP_DMG"
hdiutil detach "$MOUNT_DIR" 2>/dev/null || true

# Create temporary DMG
hdiutil create -srcfolder "$APP_DIR" -volname "$APP_NAME" -fs HFS+ -size 50m "$TMP_DMG" -ov

# Mount it
hdiutil attach "$TMP_DMG" -nobrowse

# Optional: add symlink to Applications
ln -s /Applications "$MOUNT_DIR/Applications" 2>/dev/null || true

# Set icon (optional)
# cp icon.icns "$MOUNT_DIR/.VolumeIcon.icns" 2>/dev/null || true

hdiutil detach "$MOUNT_DIR"

# Compress final DMG
hdiutil convert "$TMP_DMG" -format UDZO -o ".build/release/$DMG_NAME"
rm -f "$TMP_DMG"

echo "=== Done ==="
echo "DMG: $(pwd)/.build/release/$DMG_NAME"
