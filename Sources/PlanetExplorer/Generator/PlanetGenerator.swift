import Foundation

/// Deterministic procedural planet generator (Rust-equivalent algorithm)
struct PlanetGenerator {

    // MARK: - FNV-1a seeded RNG

    static func hashStringSeed(_ seed: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x100000001b3
        for byte in seed.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return hash
    }

    struct SeededRng {
        var state: UInt64

        init(seed: UInt64) {
            state = seed
            if state == 0 { state = 0xdeadbeef }
        }

        mutating func next() -> UInt64 {
            state ^= state >> 12
            state ^= state << 25
            state ^= state >> 27
            return state &* 2685821657736338717
        }

        mutating func nextFloat() -> Float {
            Float(UInt32(truncatingIfNeeded: next() >> 32)) / Float(UInt32.max)
        }

        mutating func genRange(_ range: ClosedRange<Double>) -> Double {
            let t = nextFloat()
            return range.lowerBound + Double(t) * (range.upperBound - range.lowerBound)
        }

        mutating func genRange(_ range: Range<Int>) -> Int {
            let count = range.count
            if count <= 0 { return range.lowerBound }
            let val = Int(next() % UInt64(count))
            return range.lowerBound + val
        }

        mutating func genBool(_ probability: Double) -> Bool {
            nextFloat() < Float(probability)
        }

        mutating func pick<T>(_ array: [T]) -> T {
            array[genRange(0..<array.count)]
        }
    }

    // MARK: - Galaxy / System name generation (No Man's Sky style)

    static let galaxyPrefixes = [
        "Euclid", "Eissentam", "Hilbert", "Calypso", "Hesperius", "Iousongola",
        "Odyalutcha", "Baptyllmu", "Strevor", "Kobamtrum", "Cimenhofen",
        "Zolrevov", "Zazabari", "Cotamanga", "Savenomos", "Edkiyonda",
        "Avjijamas", "Nekolokai", "Vujirui", "Iberenki", "Nudquedur"
    ]

    static let galaxySuffixes = [
        "Galaxy", "Cluster", "Reach", "Expanse", "Spiral", "Cloud",
        "Veil", "Drift", "Realm", "Belt", "Nexus", "Sphere"
    ]

    static let systemFirstParts = [
        "Acsoc", "Ald", "Am", "Anger", "Ar", "As", "Ax", "Ban", "Bel", "Blod",
        "Ca", "Car", "Ce", "Craw", "Cup", "Dab", "Dac", "De", "Deb", "Do",
        "Drac", "Dra", "Dre", "Ei", "El", "En", "Eo", "Er", "Eri", "Fak",
        "Fas", "Fei", "Fla", "Fol", "Fro", "Fu", "Gan", "Gar", "Gei", "Goa",
        "Grei", "Gul", "Hai", "Han", "Has", "Hei", "Hel", "Hes", "Him", "Ho",
        "Hon", "Hur", "Hy", "Hyc", "Ia", "Ike", "Ila", "Ild", "Ilt", "In",
        "Ing", "Iri", "Iro", "Isl", "Ith", "Iut", "Jap", "Jas", "Je", "Jes",
        "Jon", "Jor", "Jorl", "Jorv", "Jul", "Jup", "Jur", "Kai", "Kal", "Kan",
        "Kar", "Kei", "Ken", "Ki", "Kin", "Kir", "Koh", "Kon", "Kor", "Kras",
        "Kri", "Kro", "Krum", "Kul", "Kus", "Lac", "Lag", "Lak", "Lan", "Las",
        "Leo", "Li", "Lil", "Lo", "Lon", "Los", "Lud", "Lug", "Lul", "Lum",
        "Lus", "Lux", "Lyc", "Lyg", "Lyl", "Lyr", "Lys", "Ma", "Mac", "Mag",
        "Mal", "Man", "Mar", "Mas", "Maw", "Max", "Med", "Meg", "Mel", "Men",
        "Mer", "Mes", "Met", "Mez", "Mi", "Mic", "Mil", "Min", "Mir", "Mo",
        "Moc", "Mol", "Mon", "Mor", "Mos", "Mu", "Mul", "Mur", "Mus", "Mut",
        "Myr", "Mys", "Na", "Nac", "Nag", "Nal", "Nan", "Nar", "Nas", "Nat",
        "Neb", "Ned", "Nef", "Nei", "Nek", "Nel", "Nem", "Neo", "Nep", "Nes",
        "Net", "Nev", "New", "Nex", "Ni", "Nic", "Nil", "Nim", "Nin", "Nip",
        "Nis", "Nit", "No", "Noc", "Nod", "Nol", "Nom", "Nor", "Nos", "Not",
        "Nou", "Nov", "Nox", "Nu", "Nub", "Nul", "Num", "Nun", "Nut", "Nux",
        "Nyl", "Nys", "Ob", "Oc", "Och", "Oct", "Od", "Oe", "Of", "Og",
        "Oh", "Oi", "Oj", "Ok", "Ol", "Om", "On", "Oo", "Op", "Or",
        "Os", "Ot", "Ou", "Ov", "Ow", "Ox", "Oy", "Oz", "Pa", "Pac",
        "Pad", "Paf", "Pag", "Pak", "Pal", "Pam", "Pan", "Pap", "Par", "Pas",
        "Pat", "Pav", "Pax", "Pay", "Pea", "Pec", "Ped", "Pee", "Peg", "Pei",
        "Pel", "Pem", "Pen", "Pep", "Per", "Pes", "Pet", "Pex", "Pey", "Pha",
        "Phe", "Phi", "Pho", "Phu", "Pi", "Pic", "Pid", "Pie", "Pig", "Pik",
        "Pil", "Pim", "Pin", "Pip", "Pir", "Pis", "Pit", "Pix", "Piz", "Poa",
        "Poc", "Pod", "Poe", "Pog", "Poi", "Pok", "Pol", "Pom", "Pon", "Pop",
        "Por", "Pos", "Pot", "Pox", "Poy", "Poz", "Pra", "Pre", "Pri", "Pro",
        "Pru", "Pry", "Psi", "Pte", "Ptu", "Pua", "Pub", "Puc", "Pud", "Pue",
        "Puf", "Pug", "Puh", "Pui", "Puj", "Puk", "Pul", "Pum", "Pun", "Pup",
        "Pur", "Pus", "Put", "Pux", "Puy", "Puz", "Qua", "Que", "Qui", "Quo",
        "Ra", "Rac", "Rad", "Rae", "Raf", "Rag", "Rai", "Raj", "Rak", "Ram",
        "Ran", "Rap", "Rar", "Ras", "Rat", "Rav", "Rax", "Ray", "Rea", "Reb",
        "Rec", "Red", "Ree", "Ref", "Reg", "Rei", "Rek", "Rel", "Rem", "Ren",
        "Rep", "Res", "Ret", "Rev", "Rex", "Rey", "Rho", "Rhu", "Ria", "Rib",
        "Ric", "Rid", "Rie", "Rig", "Rik", "Ril", "Rim", "Rin", "Rip", "Ris",
        "Rit", "Riv", "Rix", "Riz", "Roa", "Rob", "Roc", "Rod", "Roe", "Rog",
        "Roi", "Roj", "Rok", "Rol", "Rom", "Ron", "Rop", "Ror", "Ros", "Rot",
        "Rov", "Rox", "Roy", "Roz", "Rua", "Rub", "Rud", "Rue", "Ruf", "Rug",
        "Ruh", "Rui", "Ruj", "Ruk", "Rul", "Rum", "Run", "Rup", "Rur", "Rus",
        "Rut", "Ruv", "Rux", "Ruy", "Ruz", "Rya", "Ryb", "Ryc", "Ryd", "Rye",
        "Ryg", "Ryh", "Ryi", "Ryj", "Ryk", "Ryl", "Rym", "Ryn", "Ryp", "Ryr",
        "Rys", "Ryt", "Ryv", "Ryx", "Ryy", "Ryz", "Rza", "Rzb", "Rzc", "Rzd",
        "Rze", "Rzg", "Rzh", "Rzi", "Rzj", "Rzk", "Rzl", "Rzm", "Rzn", "Rzp",
        "Rzr", "Rzs", "Rzt", "Rzv", "Rzx", "Rzy", "Rzz"
    ]

    static let systemSecondParts = [
        "an", "ar", "ba", "bo", "bu", "ca", "ce", "ci", "co", "cu",
        "da", "de", "di", "do", "du", "el", "en", "er", "ga", "ge",
        "gi", "go", "gu", "hi", "ho", "hu", "ia", "ie", "in", "io",
        "ir", "is", "ka", "ke", "ki", "ko", "ku", "la", "le", "li",
        "lo", "lu", "ma", "me", "mi", "mo", "mu", "na", "ne", "ni",
        "no", "nu", "or", "os", "pa", "pe", "pi", "po", "pu", "ra",
        "re", "ri", "ro", "ru", "sa", "se", "si", "so", "su", "ta",
        "te", "ti", "to", "tu", "ul", "um", "un", "ur", "us", "va",
        "ve", "vi", "vo", "vu", "wa", "we", "wi", "wo", "wu", "ya",
        "ye", "yi", "yo", "yu", "za", "ze", "zi", "zo", "zu"
    ]

    static let systemNumerals = [
        " I", " II", " III", " IV", " V", " VI", " VII", " VIII", " IX", " X"
    ]

    static func generateGalaxyName(_ rng: inout SeededRng) -> String {
        let prefix = rng.pick(galaxyPrefixes)
        let suffix = rng.pick(galaxySuffixes)
        let num = Int(rng.genRange(1.0...999.0))
        if rng.genBool(0.6) {
            return "\(prefix) \(suffix)"
        } else {
            return "\(prefix)-\(num) \(suffix)"
        }
    }

    static func generateSystemName(_ rng: inout SeededRng, starType: StarType) -> String {
        let first = rng.pick(systemFirstParts)
        let second = rng.pick(systemSecondParts)
        let catalog = Int(rng.genRange(1.0...9999.0))
        let numeral = rng.pick(systemNumerals)
        if rng.genBool(0.5) {
            return "\(first)\(second)-\(catalog)\(numeral)"
        } else {
            return "\(first)\(second) \(catalog)\(numeral)"
        }
    }

    // MARK: - Planet name generation

    static let planetFirstParts = [
        "Aci", "Ago", "Alu", "Ame", "Amo", "Anu", "Ara", "Atu", "Ava", "Avi",
        "Bal", "Ban", "Bex", "Bin", "Bor", "Bot", "Bru", "Bud", "Bur", "Bys",
        "Cap", "Cen", "Cep", "Cim", "Cir", "Cod", "Col", "Com", "Cor", "Cos",
        "Cra", "Cre", "Cri", "Cul", "Cun", "Cur", "Cus", "Dac", "Dak", "Dal",
        "Dan", "Dar", "Das", "Dec", "Dei", "Del", "Dem", "Den", "Dio", "Dir",
        "Dis", "Dit", "Dod", "Don", "Dor", "Dra", "Dre", "Dri", "Dro", "Dry",
        "Duc", "Dun", "Dup", "Dur", "Dus", "Dut", "Eci", "Ede", "Ego", "Egr",
        "Eja", "Ela", "Elo", "Ema", "Emi", "Emp", "Emu", "Enc", "End", "Eno",
        "Epe", "Epi", "Equ", "Era", "Ere", "Eri", "Ero", "Eru", "Ery", "Esi",
        "Ess", "Est", "Ete", "Eti", "Eto", "Etu", "Eva", "Eve", "Evi", "Evo",
        "Ezi", "Fab", "Fad", "Fae", "Fah", "Fai", "Fak", "Fal", "Fan", "Fap",
        "Far", "Fas", "Fat", "Fav", "Fax", "Faz", "Fel", "Fer", "Fes", "Fet",
        "Fib", "Fid", "Fil", "Fin", "Fip", "Fir", "Fis", "Fit", "Fiz", "Fob",
        "Fod", "Foi", "Fok", "Fol", "Fon", "Fop", "For", "Fos", "Fot", "Fou",
        "Fox", "Foy", "Foz", "Fra", "Fre", "Fri", "Fro", "Fry", "Ful", "Fun",
        "Fup", "Fur", "Fus", "Fut", "Fux", "Fuz", "Gad", "Gal", "Gam", "Gan",
        "Gao", "Gap", "Gar", "Gas", "Gat", "Gaw", "Gaz", "Ged", "Gel", "Gem",
        "Gen", "Geo", "Ger", "Get", "Gez", "Gid", "Gil", "Gim", "Gin", "Gip",
        "Gir", "Gis", "Git", "Gla", "Gle", "Gli", "Glo", "Glu", "Gly", "Gob",
        "Gol", "Gon", "Gop", "Gor", "Gos", "Got", "Goz", "Gra", "Gre", "Gri",
        "Gro", "Gru", "Gul", "Gum", "Gun", "Gup", "Gur", "Gus", "Gut", "Guy",
        "Gym", "Gyn", "Gyp"
    ]

    static let planetSecondParts = [
        "ara", "ata", "axa", "ea", "ega", "ela", "ely", "ema", "ena", "eno",
        "era", "eri", "esa", "eto", "eva", "evo", "exo", "ia", "ila", "ily",
        "ima", "ina", "ine", "ino", "ira", "iri", "isa", "ita", "ito", "ius",
        "iva", "ivo", "ius", "ix", "o", "oba", "ode", "ody", "oe", "oka",
        "ola", "oma", "ona", "opa", "ora", "ori", "osa", "ota", "oti", "ova",
        "oxa", "u", "ubi", "uco", "uda", "udi", "udo", "ue", "ufi", "uga",
        "ugi", "ugo", "uid", "uip", "uit", "uk", "ula", "uli", "ulo", "uma",
        "umi", "umu", "una", "uni", "uno", "upa", "uri", "uru", "us", "uta",
        "ute", "uti", "uto", "uva", "ux", "uz"
    ]

    static func generatePlanetName(_ rng: inout SeededRng) -> String {
        let first = rng.pick(planetFirstParts)
        let second = rng.pick(planetSecondParts)
        return "\(first)\(second)"
    }

    // MARK: - Main generation entry point

    static func generate(seed: String, orbit: OrbitInfo) -> Planet {
        let hash = hashStringSeed(seed)
        var rng = SeededRng(seed: hash)

        let allTypes = PlanetType.allCases
        let type = rng.pick(allTypes)
        let radius = rng.genRange(type.radiusRange)

        let surfaceBiomes = [Biome.tropical, Biome.arid, Biome.desert, Biome.toxic, Biome.ice]
        let biome: Biome?
        switch type {
        case .terrestrial, .superEarth:
            biome = rng.pick(surfaceBiomes)
        default:
            biome = nil
        }

        let canHaveFlora = (biome == .tropical || biome == .arid)
        let hasFlora = canHaveFlora && rng.genBool(0.7)
        let hasFauna = hasFlora && rng.genBool(0.5)

        let moonCount = rng.genRange(0..<5)
        var moons: [Moon] = []
        var lastMoonOrbitKm: Double = 0

        // Planet density for Kepler's 3rd law calculation (kg/m³)
        let planetDensity: Double
        switch type {
        case .terrestrial: planetDensity = 5514
        case .superEarth: planetDensity = 6500
        case .gasGiant: planetDensity = 1326
        case .iceGiant: planetDensity = 1638
        case .hotJupiter: planetDensity = 800
        }
        let G = 6.674e-11
        let planetRadiusM = radius * 1000
        let planetMassKg = planetDensity * (4.0/3.0) * .pi * pow(planetRadiusM, 3)

        for m in 0..<moonCount {
            let moonRadiusKm = rng.genRange(200.0...3000.0)
            let moonBiome: Biome = rng.genBool(0.5) ? .ice : .barren

            // Roche limit: minimum distance before tidal forces tear moon apart
            // d = 2.44 * R_planet * (ρ_planet/ρ_moon)^(1/3)
            let moonDensity: Double = moonBiome == .ice ? 1500 : 2500
            let rocheLimitKm = 2.44 * radius * pow(planetDensity / moonDensity, 1.0/3.0)

            // Minimum orbital separation: 20% of previous orbit or 3000 km
            // This prevents moons from being placed at the same distance
            let minSeparation = max(lastMoonOrbitKm * 0.20, 3000.0)
            let minOrbitKm = max(rocheLimitKm + 500, lastMoonOrbitKm + minSeparation)
            let maxOrbitKm = 50000.0

            guard minOrbitKm < maxOrbitKm else { continue }

            let moonOrbitKm = rng.genRange(minOrbitKm...max(minOrbitKm + 1000, maxOrbitKm))
            lastMoonOrbitKm = moonOrbitKm

            // Kepler's 3rd law: T = 2π√(a³/μ) where μ = G × M_planet
            // This ensures orbital period is physically determined, not random
            let a = moonOrbitKm * 1000  // km → m
            let mu = G * planetMassKg
            let periodSec = 2 * .pi * sqrt(pow(a, 3) / mu)
            let moonPeriodDays = periodSec / 86400.0

            moons.append(Moon(
                radiusKm: moonRadiusKm,
                biome: moonBiome,
                orbit: OrbitInfo(
                    semiMajorAxisAU: moonOrbitKm,
                    eccentricity: rng.genRange(0.0...0.3),
                    inclination: rng.genRange(0.0...15.0),
                    periodDays: moonPeriodDays
                )
            ))
        }

        let name = generatePlanetName(&rng)

        return Planet(
            type: type,
            radiusKm: radius,
            biome: biome,
            hasFlora: hasFlora,
            hasFauna: hasFauna,
            moons: moons,
            name: name,
            orbit: orbit
        )
    }

    // MARK: - System generation

    static func generateSystem(seed: String, galaxySeed: String) -> StarSystem {
        var rng = SeededRng(seed: hashStringSeed(seed + "-star"))
        let starType = StarType.pickWeighted(&rng)

        // Planet count: 2-9, weighted toward fewer
        let planetCount: Int
        let roll = rng.genRange(0..<100)
        if roll < 10 { planetCount = 2 }
        else if roll < 25 { planetCount = 3 }
        else if roll < 45 { planetCount = 4 }
        else if roll < 65 { planetCount = 5 }
        else if roll < 80 { planetCount = 6 }
        else if roll < 90 { planetCount = 7 }
        else if roll < 96 { planetCount = 8 }
        else { planetCount = 9 }

        // Generate planets with Titius-Bode-like orbital distances + randomness
        var planets: [Planet] = []
        var lastOrbitAU: Double = 0.3  // Inner edge

        for i in 0..<planetCount {
            // Titius-Bode law: each planet is ~1.5-2.5x further than the last
            let titiusBodeFactor = rng.genRange(1.4...2.6)
            let minGap = rng.genRange(0.2...0.8)  // minimum gap between orbits
            let semiMajorAxisAU = lastOrbitAU * titiusBodeFactor + minGap
            lastOrbitAU = semiMajorAxisAU

            let eccentricity = rng.genRange(0.0...0.35)
            let inclination = rng.genRange(0.0...12.0)
            // Period (years) from Kepler's third law: P² ∝ a³ (where a is in AU, P in years)
            let periodYears = sqrt(semiMajorAxisAU * semiMajorAxisAU * semiMajorAxisAU)
            let periodDays = periodYears * 365.25

            let orbit = OrbitInfo(
                semiMajorAxisAU: semiMajorAxisAU,
                eccentricity: eccentricity,
                inclination: inclination,
                periodDays: periodDays
            )

            let planet = generate(seed: "\(seed)-planet-\(i)", orbit: orbit)
            planets.append(planet)
        }

        let systemName = generateSystemName(&rng, starType: starType)

        return StarSystem(
            seed: seed,
            name: systemName,
            planets: planets,
            starType: starType,
            position: StarPosition(x: 0, y: 0, z: 0)
        )
    }

    // MARK: - Galaxy generation

    static func generateGalaxy(seed: String, systemCount: Int = 25) -> (name: String, systems: [StarSystem]) {
        var rng = SeededRng(seed: hashStringSeed(seed + "-galaxy"))
        let galaxyName = generateGalaxyName(&rng)

        var systems: [StarSystem] = []
        for i in 0..<systemCount {
            let systemSeed = "\(seed)-system-\(i)"
            var system = generateSystem(seed: systemSeed, galaxySeed: seed)
            // Position in a spiral galaxy pattern using golden angle
            let angle = Double(i) * 2.399963
            let radius = Double(i) * 15000.0 + rng.genRange(0.0...5000.0)
            let x = cos(angle) * radius
            let y = sin(angle) * radius
            let z = rng.genRange(-2000.0...2000.0)
            system.position = StarPosition(x: x, y: y, z: z)
            systems.append(system)
        }

        return (galaxyName, systems)
    }
}
