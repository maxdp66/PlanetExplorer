import Foundation

// Mirrors the Rust enum
enum PlanetType: Int, CaseIterable, Codable {
    case terrestrial = 0
    case gasGiant = 1
    case iceGiant = 2
    case superEarth = 3
    case hotJupiter = 4

    var name: String {
        switch self {
        case .terrestrial: return "Terrestrial"
        case .gasGiant: return "Gas Giant"
        case .iceGiant: return "Ice Giant"
        case .superEarth: return "Super-Earth"
        case .hotJupiter: return "Hot Jupiter"
        }
    }

    var color: (r: Float, g: Float, b: Float, a: Float) {
        switch self {
        case .terrestrial: return (0.2, 0.55, 0.13, 1.0)    // green
        case .gasGiant: return (0.8, 0.6, 0.2, 1.0)         // orange
        case .iceGiant: return (0.4, 0.6, 0.9, 1.0)         // blue
        case .superEarth: return (0.5, 0.3, 0.7, 1.0)       // purple
        case .hotJupiter: return (0.9, 0.3, 0.2, 1.0)       // red
        }
    }

    var radiusRange: ClosedRange<Double> {
        switch self {
        case .terrestrial: return 3000.0...8000.0
        case .superEarth: return 8000.0...20000.0
        case .gasGiant: return 40000.0...100000.0
        case .iceGiant: return 20000.0...40000.0
        case .hotJupiter: return 50000.0...120000.0
        }
    }
}

enum Biome: Int, CaseIterable, Codable {
    case toxic = 0
    case tropical = 1
    case arid = 2
    case desert = 3
    case ice = 4
    case barren = 5

    var name: String {
        switch self {
        case .toxic: return "Toxic"
        case .tropical: return "Tropical"
        case .arid: return "Arid"
        case .desert: return "Desert"
        case .ice: return "Ice"
        case .barren: return "Barren"
        }
    }

    var color: (r: Float, g: Float, b: Float, a: Float) {
        switch self {
        case .toxic: return (0.6, 0.2, 0.6, 1.0)    // purple
        case .tropical: return (0.2, 0.7, 0.2, 1.0)  // green
        case .arid: return (0.7, 0.5, 0.2, 1.0)      // tan
        case .desert: return (0.8, 0.7, 0.3, 1.0)    // yellow
        case .ice: return (0.7, 0.85, 0.95, 1.0)     // light blue
        case .barren: return (0.5, 0.5, 0.5, 1.0)    // grey
        }
    }
}

struct Moon: Codable {
    var radiusKm: Double
    var biome: Biome

    init(radiusKm: Double, biome: Biome) {
        self.radiusKm = radiusKm
        self.biome = biome
    }
}

struct Planet: Codable, Identifiable {
    var id: UUID
    var type: PlanetType
    var radiusKm: Double
    var biome: Biome?
    var hasFlora: Bool
    var hasFauna: Bool
    var moons: [Moon]
    var name: String

    init(type: PlanetType, radiusKm: Double, biome: Biome?, hasFlora: Bool, hasFauna: Bool, moons: [Moon], name: String) {
        self.id = UUID()
        self.type = type
        self.radiusKm = radiusKm
        self.biome = biome
        self.hasFlora = hasFlora
        self.hasFauna = hasFauna
        self.moons = moons
        self.name = name
    }

    var formattedRadius: String {
        if radiusKm >= 1000 {
            return String(format: "%.0f km", radiusKm)
        } else {
            return String(format: "%.0f m", radiusKm)
        }
    }

    var moonCount: String {
        "\(moons.count)"
    }
}
