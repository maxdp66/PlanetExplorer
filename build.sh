#!/bin/bash
set -e
cd "$(dirname "$0")"

# Open project in Xcode
if command -v xcodebuild &> /dev/null; then
    echo "Building with xcodebuild..."
    xcodebuild -project PlanetExplorer.xcodeproj -scheme PlanetExplorer -configuration Debug -derivedDataPath build build
    echo "Build succeeded. App is at: build/Build/Products/Debug/PlanetExplorer.app"
    open build/Build/Products/Debug/PlanetExplorer.app 2>/dev/null || true
else
    echo "Xcode not found on this machine."
    echo "Transfer this project to a Mac and run:"
    echo "  xcodebuild -project PlanetExplorer.xcodeproj -scheme PlanetExplorer build"
    echo "or open PlanetExplorer.xcodeproj in Xcode and press Cmd+B"
fi
