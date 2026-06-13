#!/bin/bash
set -e

echo "🔐 App Store Connect Setup"
echo "=========================="
echo ""
echo "This script helps you set up App Store Connect API authentication."
echo ""

# Check if key already exists
if [ -f ~/.appstoreconnect/private_keys/AuthKey_*.p8 ]; then
    echo "✅ API key already exists at ~/.appstoreconnect/private_keys/"
    ls -la ~/.appstoreconnect/private_keys/
    echo ""
    read -p "Use existing key? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        KEY_FILE=$(ls ~/.appstoreconnect/private_keys/AuthKey_*.p8 | head -1)
        echo "Using existing key: $KEY_FILE"
        echo ""
        read -p "Enter Issuer ID: " ISSUER_ID
        read -p "Enter Key ID: " KEY_ID
        
        echo ""
        echo "Add these to your environment or .env file:"
        echo "export APPLE_API_KEY_PATH=$KEY_FILE"
        echo "export APPLE_ISSUER_ID=$ISSUER_ID"
        echo "export APPLE_KEY_ID=$KEY_ID"
        exit 0
    fi
fi

echo "To create an App Store Connect API key:"
echo "1. Go to https://appstoreconnect.apple.com/api"
echo "2. Create a new API key (requires Admin role)"
echo "3. Download the .p8 file"
echo "4. Note the Issuer ID and Key ID"
echo ""
read -p "Press Enter after you have the .p8 file..."

read -p "Path to .p8 file: " P8_PATH
if [ ! -f "$P8_PATH" ]; then
    echo "❌ File not found: $P8_PATH"
    exit 1
fi

# Copy to standard location
mkdir -p ~/.appstoreconnect/private_keys
cp "$P8_PATH" ~/.appstoreconnect/private_keys/
chmod 600 ~/.appstoreconnect/private_keys/*.p8

KEY_FILE=$(ls ~/.appstoreconnect/private_keys/AuthKey_*.p8 | head -1)
echo "✅ Key copied to: $KEY_FILE"

read -p "Enter Issuer ID: " ISSUER_ID
read -p "Enter Key ID: " KEY_ID

echo ""
echo "✅ Setup complete!"
echo ""
echo "Add these to your environment or .env file:"
echo "export APPLE_API_KEY_PATH=$KEY_FILE"
echo "export APPLE_ISSUER_ID=$ISSUER_ID"
echo "export APPLE_KEY_ID=$KEY_ID"
echo ""
echo "Then run: ./scripts/archive-and-upload.sh"
