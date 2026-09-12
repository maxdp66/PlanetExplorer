# Planet Explorer

A macOS native 3D procedural planet explorer inspired by No Man's Sky. Generate entire galaxies from a seed string, fly around planets in 3D, and explore procedurally generated star systems.

## Features

- **Procedural Galaxy Generation** — Deterministic generation from any seed string (same seed = same galaxy every time)
- **3D Planet Rendering** — SceneKit-powered 3D view with fly-around camera controls
- **Multiple Planet Types** — Terrestrial, Gas Giant, Ice Giant, Super-Earth, Hot Jupiter
- **Biomes & Life** — Tropical, Arid, Desert, Toxic, Ice biomes with flora/fauna
- **Moon Systems** — Each planet can have orbiting moons
- **Galaxy Map** — 2D overview of all star systems with spiral layout
- **Seed Explorer** — Change the seed to generate entirely different galaxies

## Requirements

- macOS 13.0+
- Xcode 15.0+ or Swift 5.0+ (Command Line Tools)

## Building & Running

### Option 1: Xcode (recommended)

The project generates automatically:

```bash
./build.sh
```

Or manually:

```bash
swift package generate-xcodeproj
open PlanetExplorer.xcodeproj
# Press Cmd+R
```

### Option 2: Command Line with Swift

```bash
swift run
```

> Note: `swift run` requires Swift to be able to load the SwiftUI macro plugins, which works on macOS 14+ with Xcode 15+.

### Option 3: xcodebuild CLI

```bash
xcodebuild -project PlanetExplorer.xcodeproj -scheme PlanetExplorer build
open build/Build/Products/Debug/PlanetExplorer.app
```

## Controls

| Key | Action |
|-----|--------|
| W / S | Move forward / backward |
| A / D | Move left / right |
| Q / E | Move up / down |
| Mouse Drag | Look around |
| Scroll | Zoom in/out |
| Shift | Speed boost |
| ◀ ▶ | Previous/Next planet |

## Architecture

```
PlanetExplorer/
├── Package.swift                         # Swift Package Manager config
├── Sources/PlanetExplorer/
│   ├── ContentView.swift                 # Main app, navigation, state
│   ├── Info.plist                        # macOS app configuration
│   ├── PlanetExplorer.entitlements       # App sandbox & code signing
│   ├── Models/
│   │   ├── Planet.swift                  # Planet, Moon, Biome, PlanetType
│   │   └── StarSystem.swift              # StarSystem, StarColor, StarPosition
│   ├── Generator/
│   │   └── PlanetGenerator.swift         # Procedural generation (Rust-equivalent)
│   ├── Scene/
│   │   └── PlanetSceneView.swift         # SceneKit 3D renderer with fly camera
│   └── Views/
│       └── GalaxyMapView.swift           # 2D galaxy map, planet cards, sidebar
├── PlanetExplorer.xcodeproj/             # Xcode project (auto-generated)
├── README.md
└── build.sh
```

## Algorithm

The procedural generator mirrors the Rust source exactly:

1. **FNV-1a hash** of the seed string → 64-bit seed
2. **xorshift64*** PRNG seeded from the hash
3. **Planet type** chosen uniformly from 5 variants
4. **Radius** sampled from type-specific range
5. **Biome** assigned for terrestrial/super-earth types
6. **Flora/fauna** rolled with probability chains (70% flora on tropical/arid, 50% fauna if flora present)
7. **Moons** (0-3) with ice/barren biomes
8. **System/galaxy** layout uses golden-angle spiral distribution

## License

MIT
