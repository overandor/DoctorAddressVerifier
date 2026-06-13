#!/bin/bash
set -euo pipefail

APP_NAME="DoctorAddressVerifier"
BUNDLE_ID="com.membra.doctor-address-verifier"
VERSION="${1:-1.0.0}"

echo "=== Building Release ==="
swift build -c release

BINARY=".build/release/$APP_NAME"
APP_DIR=".build/release/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "=== Packaging .app ==="
rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"

cp "$BINARY" "$MACOS/$APP_NAME"
chmod +x "$MACOS/$APP_NAME"

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
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "=== Signing ==="
if [ -z "${SIGNING_IDENTITY:-}" ]; then
    echo "SIGNING_IDENTITY not set; using ad-hoc sign"
    codesign --force --deep --options runtime \
        --entitlements DoctorAddressVerifier.entitlements \
        --sign - "$APP_DIR"
else
    codesign --force --deep --options runtime \
        --entitlements DoctorAddressVerifier.entitlements \
        --sign "$SIGNING_IDENTITY" "$APP_DIR"
fi

echo "=== Building .pkg ==="
PKG_NAME="$APP_NAME-$VERSION.pkg"
if [ -z "${INSTALLER_IDENTITY:-}" ]; then
    echo "INSTALLER_IDENTITY not set; building unsigned pkg"
    productbuild --component "$APP_DIR" /Applications ".build/release/$PKG_NAME"
else
    productbuild --component "$APP_DIR" /Applications \
        --sign "$INSTALLER_IDENTITY" ".build/release/$PKG_NAME"
fi

echo "=== Done ==="
echo "Package: $(pwd)/.build/release/$PKG_NAME"
