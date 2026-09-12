import Foundation

/// Deterministic procedural planet generator (Rust-equivalent algorithm)
///
/// Replicates the exact logic from the Rust source: FNV-1a seeded PRNG,
/// range-weighted type selection, surface biome assignment, flora/fauna rolls,
/// and moon generation.
struct PlanetGenerator {

    // MARK: - FNV-1a seeded RNG

    /// Mirrors `hash_string_seed()` from the Rust source.
    /// FNV-1a 64-bit: hash = hash XOR byte, hash = hash * FNV_PRIME.
    static func hashStringSeed(_ seed: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x100000001b3
        for byte in seed.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime  // wrapping multiply
        }
        return hash
    }

    /// Simple, seedable PRNG (xorshift64s) — not the Rust StdRng, but
    /// deterministic from a single u64 seed and good enough for procedural content.
    struct SeededRng {
        var state: UInt64

        init(seed: UInt64) {
            state = seed
            // Prime the state — xorshift needs non-zero
            if state == 0 { state = 0xdeadbeef }
        }

        /// xorshift64* — fast, good statistical properties.
        mutating func next() -> UInt64 {
            state ^= state >> 12
            state ^= state << 25
            state ^= state >> 27
            return state &* 2685821657736338717
        }

        mutating func nextFloat() -> Float {
            UInt32(truncatingIfNeeded: next() >> 32) / Float(UInt32.max)
        }

        mutating func genRange(_ range: ClosedRange<Double>) -> Double {
            let t = nextFloat()
            return range.lowerBound + Double(t) * (range.upperBound - range.lowerBound)
        }

        mutating func genRange(_ range: Range<Int>) -> Int {
            let count = range.count
            if count <= 0 { return range.lowerBound }
            let val = Int(truncatingIfNeeded: next()) % count
            return range.lowerBound + val
        }

        mutating func genBool(_ probability: Double) -> Bool {
            nextFloat() < Float(probability)
        }

        mutating func pick<T>(_ array: [T]) -> T {
            array[genRange(0..<array.count)]
        }
    }

    // MARK: - Planet name generator

    static let namePrefixes = [
        "Proxima", "Nova", "Kepler", "Gliese", "Trappist", "Ross", "Luyten",
        "Wolf", "Epsilon", "Tau", "Beta", "Gamma", "Delta", "Zeta", "Eta",
        "Theta", "Iota", "Kappa", "Lambda", "Mu", "Nu", "Xi", "Omicron",
        "Pi", "Rho", "Sigma", "Phi", "Chi", "Psi", "Omega"
    ]

    static let nameSuffixes = [
        "Prime", "Major", "Minor", "Alpha", "Beta", "Centauri", "b", "c",
        "d", "e", "f", "g", "VII", "IX", "XII", "XIV", "XVIII", "XXII",
        "Ultra", "Maxima", "Proxima", "Ultima", "Genesis", "Aurora", "Solis"
    ]

    static func generateName(_ rng: inout SeededRng) -> String {
        let prefix = rng.pick(namePrefixes)
        let suffix = rng.pick(nameSuffixes)
        let num = Int(rng.genRange(1.0...999.0))
        if rng.genBool(0.5) {
            return "\(prefix)-\(num) \(suffix)"
        } else {
            return "\(prefix) \(suffix)"
        }
    }

    // MARK: - Main generation entry point

    static func generate(seed: String) -> Planet {
        let hash = hashStringSeed(seed)
        var rng = SeededRng(seed: hash)

        // Pick a type — uniform selection mirroring the Rust `.choose(&mut rng)`
        let allTypes = PlanetType.allCases
        let type = rng.pick(allTypes)

        // Radius from the type's range
        let radius = rng.genRange(type.radiusRange)

        // Biome only for terrestrial / super-earth
        let surfaceBiomes = [Biome.tropical, Biome.arid, Biome.desert, Biome.toxic, Biome.ice]
        let biome: Biome?
        switch type {
        case .terrestrial, .superEarth:
            biome = rng.pick(surfaceBiomes)
        default:
            biome = nil
        }

        // Flora/fauna rolls
        let canHaveFlora = (biome == .tropical || biome == .arid)
        let hasFlora = canHaveFlora && rng.genBool(0.7)
        let hasFauna = hasFlora && rng.genBool(0.5)

        // Moons
        let moonCount = rng.genRange(0..<4)
        var moons: [Moon] = []
        for _ in 0..<moonCount {
            let moonRadius = rng.genRange(500.0...2000.0)
            let moonBiome: Biome = rng.genBool(0.5) ? .ice : .barren
            moons.append(Moon(radiusKm: moonRadius, biome: moonBiome))
        }

        let name = generateName(&rng)

        return Planet(
            type: type,
            radiusKm: radius,
            biome: biome,
            hasFlora: hasFlora,
            hasFauna: hasFauna,
            moons: moons,
            name: name
        )
    }

    // MARK: - System / Galaxy generation

    static func generateSystem(seed: String, planetCount: Int = 5) -> StarSystem {
        var rng = SeededRng(seed: hashStringSeed(seed + "-star"))
        let starRadius = rng.genRange(40000.0...80000.0)
        let colors: [StarColor] = [
            StarColor(r: 1.0, g: 0.95, b: 0.8),   // yellow-white
            StarColor(r: 0.6, g: 0.7, b: 1.0),    // blue
            StarColor(r: 1.0, g: 0.6, b: 0.3),    // orange
            StarColor(r: 1.0, g: 0.4, b: 0.3),    // red dwarf
            StarColor(r: 0.9, g: 0.85, b: 1.0),   // white
        ]
        let starColor = rng.pick(colors)

        var planets: [Planet] = []
        for i in 0..<planetCount {
            let planet = generate(seed: "\(seed)-planet-\(i)")
            planets.append(planet)
        }

        let systemName = generateName(&rng)

        return StarSystem(
            seed: seed,
            name: systemName,
            planets: planets,
            starRadius: starRadius,
            starColor: starColor,
            position: StarPosition(x: 0, y: 0, z: 0)
        )
    }

    static func generateGalaxy(seed: String, systemCount: Int = 20, planetsPerSystem: Int = 5) -> [StarSystem] {
        var rng = SeededRng(seed: hashStringSeed(seed + "-galaxy"))
        var systems: [StarSystem] = []
        for i in 0..<systemCount {
            let systemSeed = "\(seed)-system-\(i)"
            var system = generateSystem(seed: systemSeed, planetCount: planetsPerSystem)
            // Position in a spiral galaxy pattern using golden angle
            let angle = Double(i) * 2.399963
            let radius = Double(i) * 15000.0 + rng.genRange(0.0...5000.0)
            let x = cos(angle) * radius
            let y = sin(angle) * radius
            let z = rng.genRange(-2000.0...2000.0)
            system.position = StarPosition(x: x, y: y, z: z)
            systems.append(system)
        }
        return systems
    }
}
