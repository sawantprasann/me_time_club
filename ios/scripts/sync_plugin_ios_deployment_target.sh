#!/bin/sh
# Flutter regenerates FlutterGeneratedPluginSwiftPackage with iOS 13.0.
# Firebase requires iOS 15, so match the package to the app deployment target
# before Xcode resolves Swift packages.
set -eu

ROOT="${SRCROOT:-$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)}"
MANIFEST="$ROOT/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"
PBX="$ROOT/Runner.xcodeproj/project.pbxproj"

if [ ! -f "$MANIFEST" ]; then
  exit 0
fi

TARGET="$(grep -m1 'IPHONEOS_DEPLOYMENT_TARGET' "$PBX" | sed -E 's/.*IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);/\1/')"
if [ -z "$TARGET" ]; then
  echo "error: IPHONEOS_DEPLOYMENT_TARGET was not found in project.pbxproj" >&2
  exit 1
fi

/usr/bin/sed -i '' -E "s/\\.iOS\\(\"[0-9.]+\"\\)/.iOS(\"${TARGET}\")/" "$MANIFEST"
