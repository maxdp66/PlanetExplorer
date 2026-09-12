#!/bin/bash
set -e
cd "$(dirname "$0")"

# Try swift run first (works on macOS with Swift installed)
if command -v swift &> /dev/null; then
    echo "Building and running with 'swift run'..."
    swift run
else
    echo "Swift not found on this machine."
    echo "Transfer this project to a Mac and run:"
    echo "  swift run"
    echo "or:"
    echo "  swift build"
    echo "  .build/debug/PlanetExplorer"
fi
