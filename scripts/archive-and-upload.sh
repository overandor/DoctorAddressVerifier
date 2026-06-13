#!/bin/bash
set -e

# Archive and upload to App Store Connect
# Usage: ./scripts/archive-and-upload.sh [version]

VERSION=${1:-"1.0.0"}
PROJECT="DoctorAddressVerifier.xcodeproj"
SCHEME="DoctorAddressVerifier"
ARCHIVE_PATH="build/DoctorAddressVerifier.xcarchive"
EXPORT_PATH="build/export"

echo "📦 Archiving DoctorAddressVerifier v${VERSION}..."

# Clean build
xcodebuild clean \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release

# Archive
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates

echo "✅ Archive created at $ARCHIVE_PATH"

# Upload to App Store Connect
echo "📤 Uploading to App Store Connect..."

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist ExportOptions.plist

# Upload using altool or notarytool
if [ -n "$APPLE_ID" ] && [ -n "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
  echo "📤 Uploading via altool..."
  xcrun altool --upload-app \
    --type osx \
    --file "$EXPORT_PATH/DoctorAddressVerifier.app" \
    --username "$APPLE_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD"
elif [ -f "$APPLE_API_KEY_PATH" ]; then
  echo "📤 Uploading via notarytool with API key..."
  xcrun notarytool submit "$EXPORT_PATH/DoctorAddressVerifier.app" \
    --key "$APPLE_API_KEY_PATH" \
    --issuer "$APPLE_ISSUER_ID" \
    --wait
else
  echo "⚠️  No credentials configured. Archive ready at $ARCHIVE_PATH"
  echo "   Upload manually via Xcode Organizer or Transporter"
fi

echo "✅ Done"
