/// A star system with a central star and orbiting planets.
///
/// Positioned in a spiral galaxy pattern using golden-angle distribution.
struct StarSystem {
    var seed: String
    var name: String
    var planets: [Planet]
    var starType: StarType
    var position: StarPosition
}

/// Realistic spectral classification based on the Morgan-Keenan system.
/// Temperature ranges, radii, and colors are astronomically grounded.
enum StarType: Int, CaseIterable {
    case oType   // Blue supergiant, 30,000-50,000K
    case bType   // Blue-white, 10,000-30,000K
    case aType   // White, 7,500-10,000K
    case fType   // Yellow-white, 6,000-7,500K
    case gType   // Yellow (Sun-like), 5,200-6,000K
    case kType   // Orange, 3,700-5,200K
    case mType   // Red dwarf, 2,400-3,700K
    case lType   // Brown dwarf, 1,300-2,400K
    case wolfRayet  // Wolf-Rayet, 30,000-200,000K (rare)
    case carbon  // Carbon star, 2,000-3,500K (rare)
    case whiteDwarf  // White dwarf, 4,000-150,000K (tiny)

    var spectralClass: String {
        switch self {
        case .oType: return "O"
        case .bType: return "B"
        case .aType: return "A"
        case .fType: return "F"
        case .gType: return "G"
        case .kType: return "K"
        case .mType: return "M"
        case .lType: return "L"
        case .wolfRayet: return "W"
        case .carbon: return "C"
        case .whiteDwarf: return "D"
        }
    }

    var description: String {
        switch self {
        case .oType: return "Blue Supergiant"
        case .bType: return "Blue-White Star"
        case .aType: return "White Star"
        case .fType: return "Yellow-White Star"
        case .gType: return "Yellow Star (G-class)"
        case .kType: return "Orange Star"
        case .mType: return "Red Dwarf"
        case .lType: return "Brown Dwarf"
        case .wolfRayet: return "Wolf-Rayet Star"
        case .carbon: return "Carbon Star"
        case .whiteDwarf: return "White Dwarf"
        }
    }

    /// Realistic radius in km (for rendering the star dot).
    var radiusKm: Double {
        switch self {
        case .oType: return 1_500_000
        case .bType: return 700_000
        case .aType: return 250_000
        case .fType: return 180_000
        case .gType: return 140_000  // Sun-like
        case .kType: return 100_000
        case .mType: return 50_000
        case .lType: return 30_000
        case .wolfRayet: return 1_200_000
        case .carbon: return 80_000
        case .whiteDwarf: return 8_000  // Earth-sized remnant
        }
    }

    /// RGB color for rendering.
    var color: StarColor {
        switch self {
        case .oType: return StarColor(r: 0.55, g: 0.65, b: 1.0)
        case .bType: return StarColor(r: 0.7, g: 0.8, b: 1.0)
        case .aType: return StarColor(r: 0.95, g: 0.95, b: 1.0)
        case .fType: return StarColor(r: 1.0, g: 0.95, b: 0.85)
        case .gType: return StarColor(r: 1.0, g: 0.95, b: 0.7)
        case .kType: return StarColor(r: 1.0, g: 0.8, b: 0.5)
        case .mType: return StarColor(r: 1.0, g: 0.5, b: 0.3)
        case .lType: return StarColor(r: 0.8, g: 0.3, b: 0.1)
        case .wolfRayet: return StarColor(r: 0.4, g: 0.5, b: 1.0)
        case .carbon: return StarColor(r: 0.9, g: 0.4, b: 0.2)
        case .whiteDwarf: return StarColor(r: 0.85, g: 0.85, b: 1.0)
        }
    }

    /// Weighted rarity for generation. M and K are most common,
    /// O and Wolf-Rayet are extremely rare.
    var rarityWeight: Int {
        switch self {
        case .oType: return 1
        case .bType: return 3
        case .aType: return 8
        case .fType: return 15
        case .gType: return 20
        case .kType: return 25
        case .mType: return 22
        case .lType: return 5
        case .wolfRayet: return 1
        case .carbon: return 2
        case .whiteDwarf: return 4
        }
    }

    /// Estimate surface temperature (K) for display.
    var temperatureK: Int {
        switch self {
        case .oType: return 40000
        case .bType: return 20000
        case .aType: return 9000
        case .fType: return 7000
        case .gType: return 5800
        case .kType: return 4500
        case .mType: return 3000
        case .lType: return 1800
        case .wolfRayet: return 80000
        case .carbon: return 2800
        case .whiteDwarf: return 25000
        }
    }

    static func pickWeighted(_ rng: inout PlanetGenerator.SeededRng) -> StarType {
        let total = StarType.allCases.reduce(0) { $0 + $1.rarityWeight }
        let roll = Int(rng.next() % UInt64(total))
        var cumulative = 0
        for type in StarType.allCases {
            cumulative += type.rarityWeight
            if roll < cumulative { return type }
        }
        return .gType  // fallback
    }
}

struct StarColor {
    let r: Float
    let g: Float
    let b: Float

    init(r: Float, g: Float, b: Float) {
        self.r = r
        self.g = g
        self.b = b
    }
}

struct StarPosition {
    var x: Double
    var y: Double
    var z: Double

    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

/// Orbit information for a planet around its star (or moon around its planet).
struct OrbitInfo: Codable {
    let semiMajorAxisAU: Double  // AU for planets, 10^3 km for moons
    let eccentricity: Double     // 0.0-1.0
    let inclination: Double      // degrees
    let periodDays: Double       // orbital period

    init(semiMajorAxisAU: Double, eccentricity: Double = 0, inclination: Double = 0, periodDays: Double = 0) {
        self.semiMajorAxisAU = semiMajorAxisAU
        self.eccentricity = eccentricity
        self.inclination = inclination
        self.periodDays = periodDays
    }

    var description: String {
        if semiMajorAxisAU > 100 {
            // Moon distance in thousands of km
            return String(format: "%.1f km", semiMajorAxisAU)
        } else {
            return String(format: "%.3f AU", semiMajorAxisAU)
        }
    }
}
