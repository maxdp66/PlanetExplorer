#!/bin/bash
set -e
cd "$(dirname "$0")"

# Check if Xcode is available (preferred for SwiftUI apps)
if command -v xcodebuild &> /dev/null; then
    echo "Building with Xcode..."
    
    # Check if Xcode project exists
    if [ ! -d "PlanetExplorer.xcodeproj" ]; then
        if command -v swift &> /dev/null; then
            echo "Generating Xcode project..."
            swift package generate-xcodeproj
        else
            echo "No swift or xcodebuild found."
            echo "On a Mac, run: swift package generate-xcodeproj"
            exit 1
        fi
    fi
    
    xcodebuild -project PlanetExplorer.xcodeproj -scheme PlanetExplorer -configuration Debug -derivedDataPath build build
    echo "Build succeeded."
    echo "Opening app..."
    open build/Build/Products/Debug/PlanetExplorer.app 2>/dev/null || true
else
    echo "Xcode not found. Trying swift run..."
    if command -v swift &> /dev/null; then
        swift run
    else
        echo "Neither Xcode nor Swift found."
        echo "On a Mac with Xcode:"
        echo "  open PlanetExplorer.xcodeproj"
        echo "  # Press Cmd+R"
        echo ""
        echo "Or with Swift CLI:"
        echo "  swift run"
    fi
fi
