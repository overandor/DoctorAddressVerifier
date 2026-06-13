# App Store CI/CD Setup

## Menu Bar App
The app now runs as a macOS menu bar item (no dock icon). `LSUIElement` is set to `true` in `Info.plist`.

## Apple Developer Secrets
Add these to your repository Settings → Secrets and variables → Actions:

| Secret | Description |
|--------|-------------|
| `MACOS_CERTIFICATE` | Base64-encoded `.p12` of your **Apple Distribution** certificate |
| `MACOS_CERTIFICATE_PASSWORD` | Password for the `.p12` file |
| `KEYCHAIN_PASSWORD` | Any random password for the temporary CI keychain |
| `APPLE_SIGNING_IDENTITY` | Full name, e.g. `Apple Distribution: Membra Inc (ABCD123456)` |
| `APPLE_INSTALLER_IDENTITY` | Full name, e.g. `Apple Distribution: Membra Inc (ABCD123456)` or `3rd Party Mac Developer Installer: ...` |
| `APPLE_ID` | Your Apple Developer email |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password from [appleid.apple.com](https://appleid.apple.com) |
| `APPLE_TEAM_ID` | 10-character Team ID |

## Certificates & Profiles
1. In [Apple Developer Portal](https://developer.apple.com), create:
   - **Mac App Distribution** certificate (for signing the app)
   - **Mac Installer Distribution** certificate (for the `.pkg`)
   - **App ID** for `com.membra.doctor-address-verifier`
   - **Provisioning Profile** → Mac App Store → link to the App ID
2. Export both certificates as `.p12` from Keychain Access, then base64-encode:
   ```sh
   base64 -i Certificates.p12 | pbcopy
   ```

## Triggering a Release
- Push a tag: `git tag v1.0.0 && git push origin v1.0.0`
- Or use **Actions → Build and Upload to App Store → Run workflow** and enter a version string

## Widget Extension (App Store requirement)
App Extensions (widgets) **require an Xcode project** with a separate Widget Extension target. Swift Package Manager executables cannot bundle `.appex` bundles in a way App Store Connect accepts.

### Migration path
1. Open Xcode → File → New → Project → macOS → App
2. Add your existing Swift files from `Sources/DoctorAddressVerifier/`
3. File → New → Target → Widget Extension
4. Replace this SPM package with the Xcode project in CI:
   ```yaml
   - run: xcodebuild -project DoctorAddressVerifier.xcodeproj -scheme DoctorAddressVerifier -configuration Release archive -archivePath build/DoctorAddressVerifier.xcarchive
   - run: xcodebuild -exportArchive -archivePath build/DoctorAddressVerifier.xcarchive -exportPath build/export -exportOptionsPlist ExportOptions.plist
   ```

## Local Build
```sh
# Unsigned
./scripts/build-app-store.sh 1.0.0

# Signed (set env vars first)
export SIGNING_IDENTITY="Apple Distribution: Membra Inc (TEAMID)"
export INSTALLER_IDENTITY="Apple Distribution: Membra Inc (TEAMID)"
./scripts/build-app-store.sh 1.0.0
```
