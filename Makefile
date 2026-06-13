# DoctorAddressVerifier — Windsurf / Terminal Automation
# Run any target from Windsurf's integrated terminal

.PHONY: build test clean run dmg open info verify bridge-check

APP_NAME := DoctorAddressVerifier
BINARY := .build/debug/$(APP_NAME)
RELEASE_BINARY := .build/release/$(APP_NAME)

## build          — Debug build via SPM
build:
	swift build

## test           — Run unit tests
 test:
	swift test

## clean          — Remove build artifacts
clean:
	swift package clean
	rm -rf .build

## run            — Build and run the debug binary
run: build
	$(BINARY)

## release        — Build optimized release binary
release:
	swift build -c release

## dmg            — Build .app bundle and DMG (uses build_dmg.sh)
dmg: release
	./build_dmg.sh

## open           — Open Package.swift in Xcode
open:
	open Package.swift

## open-app       — Open the built .app bundle
open-app: release
	open .build/release/$(APP_NAME).app

## info           — Show project metadata
info:
	@echo "Package:   $(APP_NAME)"
	@echo "Location:  $(PWD)"
	@echo "Schemes:   $(shell swift package describe --type json 2>/dev/null | grep -o '"name" : \"[^\"]*\"' | head -5 | tr '\n' ' ')"
	@swift --version

## verify         — Smoke test: check binary exists and is executable
verify: build
	@test -f $(BINARY) && echo "✓ Binary exists: $(BINARY)" || (echo "✗ Binary missing" && exit 1)
	@file $(BINARY) | grep -q "executable" && echo "✓ Binary is executable" || (echo "✗ Not executable" && exit 1)
	@echo "✓ Build verification passed"

## bridge-check   — Verify Xcode/ChatGPT/Windsurf bridge commands
bridge-check:
	@sh scripts/check-ai-bridge.sh
