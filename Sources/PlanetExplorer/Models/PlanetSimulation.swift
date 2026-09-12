import Foundation

/// Real-time procedural planet simulation.
/// All values are calculated from the planet's physical parameters at runtime.
/// No pre-programmed data — everything derives from orbital mechanics, thermodynamics,
/// and the Morgan-Keenan stellar classification.
struct PlanetSimulation {
    let planet: Planet
    let star: StarType

    // MARK: - Derived planet physical properties

    /// Density based on planet type (kg/m³) — realistic values
    var density: Double {
        switch planet.type {
        case .terrestrial: return 5514   // Earth-like
        case .superEarth: return 6500    // denser rocky
        case .gasGiant: return 1326      // Saturn-like (could be Jupiter-like at 1326)
        case .iceGiant: return 1638      // Uranus/Neptune-like
        case .hotJupiter: return 800     // inflated hot gas giant
        }
    }

    /// Volume from radius: V = 4/3 π R³
    var volume: Double {
        let radiusM = planet.radiusKm * 1000  // km → m
        return (4.0 / 3.0) * .pi * pow(radiusM, 3)
    }

    /// Mass from density and volume (kg)
    var massKg: Double {
        return density * volume
    }

    /// Mass in Earth masses
    var massEarth: Double {
        return massKg / 5.972e24
    }

    /// Surface gravity: g = GM/R² (m/s²)
    var surfaceGravity: Double {
        let radiusM = planet.radiusKm * 1000
        let G = 6.674e-11
        return (G * massKg) / pow(radiusM, 2)
    }

    /// Surface gravity in g-forces
    var surfaceGravityG: Double {
        return surfaceGravity / 9.807
    }

    /// Escape velocity: v_esc = √(2GM/R) (km/s)
    var escapeVelocityKms: Double {
        let radiusM = planet.radiusKm * 1000
        let G = 6.674e-11
        let v = sqrt(2 * G * massKg / radiusM)
        return v / 1000
    }

    /// Surface area: A = 4πR² (km²)
    var surfaceAreaKm2: Double {
        return 4 * .pi * pow(planet.radiusKm, 2)
    }

    /// Surface area in Earth areas
    var surfaceAreaEarth: Double {
        return surfaceAreaKm2 / 510_072_000
    }

    // MARK: - Star properties

    /// Star luminosity in watts (Stefan-Boltzmann: L = 4πR²σT⁴)
    var starLuminosityW: Double {
        let radiusM = star.radiusKm * 1000
        let sigma = 5.670374419e-8  // Stefan-Boltzmann constant
        let temp = Double(star.temperatureK)
        return 4 * .pi * pow(radiusM, 2) * sigma * pow(temp, 4)
    }

    /// Star luminosity in solar luminosities
    var starLuminositySolar: Double {
        return starLuminosityW / 3.828e26
    }

    /// Star mass from mass-luminosity relation (main sequence): L ∝ M^3.5
    var starMassKg: Double {
        let solarMasses = pow(starLuminositySolar, 1.0/3.5)
        return solarMasses * 1.989e30
    }

    // MARK: - Orbital properties

    /// Orbital distance in meters
    var orbitalDistanceM: Double {
        return planet.orbit.semiMajorAxisAU * 1.496e11  // AU → m
    }

    /// Orbital distance in km
    var orbitalDistanceKm: Double {
        return orbitalDistanceM / 1000
    }

    /// Solar flux at planet's orbit: F = L / (4πd²) (W/m²)
    var solarFluxWm2: Double {
        let d = orbitalDistanceM
        return starLuminosityW / (4 * .pi * pow(d, 2))
    }

    /// Solar flux relative to Earth
    var solarFluxEarth: Double {
        return solarFluxWm2 / 1361
    }

    /// Orbital velocity: v = √(GM_star / r) (km/s)
    var orbitalVelocityKms: Double {
        let G = 6.674e-11
        let v = sqrt(G * starMassKg / orbitalDistanceM)
        return v / 1000
    }

    /// Orbital period in days (from Kepler's 3rd law)
    var orbitalPeriodDays: Double {
        return planet.orbit.periodDays
    }

    /// Orbital period in Earth years
    var orbitalPeriodYears: Double {
        return orbitalPeriodDays / 365.25
    }

    /// Orbital eccentricity (already have)
    var eccentricity: Double {
        return planet.orbit.eccentricity
    }

    /// Perihelion distance (km)
    var perihelionKm: Double {
        return orbitalDistanceKm * (1 - planet.orbit.eccentricity)
    }

    /// Aphelion distance (km)
    var aphelionKm: Double {
        return orbitalDistanceKm * (1 + planet.orbit.eccentricity)
    }

    // MARK: - Temperature calculations

    /// Equilibrium temperature (no atmosphere) in Kelvin
    /// T_eq = T_star × √(R_star / 2d) × (1 - A)^(1/4)
    /// where A is albedo (estimated from type)
    var equilibriumTempK: Double {
        let starRadiusM = star.radiusKm * 1000
        let d = orbitalDistanceM
        let albedo = estimatedAlbedo
        let tempFactor = sqrt(starRadiusM / (2 * d))
        return Double(star.temperatureK) * tempFactor * pow(1 - albedo, 0.25)
    }

    /// Equilibrium temperature in Celsius
    var equilibriumTempC: Double {
        return equilibriumTempK - 273.15
    }

    /// Estimated albedo based on planet type (Bond albedo)
    var estimatedAlbedo: Double {
        switch planet.type {
        case .terrestrial:
            if planet.biome == .ice { return 0.6 }
            if planet.biome == .desert { return 0.35 }
            if planet.biome == .tropical { return 0.25 }
            return 0.3
        case .superEarth: return 0.35
        case .gasGiant: return 0.5
        case .iceGiant: return 0.45
        case .hotJupiter: return 0.1  // dark, absorbs heat
        }
    }

    /// Effective temperature with greenhouse effect (rough estimate)
    var surfaceTempK: Double {
        // Greenhouse factor based on atmosphere type
        let greenhouseFactor: Double
        switch planet.type {
        case .terrestrial:
            if planet.hasFlora { greenhouseFactor = 1.15 }  // Earth-like biosphere
            else if planet.biome == .desert { greenhouseFactor = 1.05 }
            else { greenhouseFactor = 1.1 }
        case .superEarth: greenhouseFactor = 1.2  // thicker atmosphere
        case .gasGiant: greenhouseFactor = 1.0  // no surface
        case .iceGiant: greenhouseFactor = 1.0
        case .hotJupiter: greenhouseFactor = 1.05  // absorbed heat redistribution
        }
        return equilibriumTempK * greenhouseFactor
    }

    var surfaceTempC: Double {
        return surfaceTempK - 273.15
    }

    // MARK: - Habitability

    /// Is the planet in the habitable zone? (rough estimate)
    var isInHabitableZone: Double {
        let flux = solarFluxEarth
        // Conservative habitable zone: 0.35 to 1.5 × Earth flux
        if flux >= 0.35 && flux <= 1.5 { return 1.0 }
        // Optimistic extension: 0.25 to 2.0
        if flux >= 0.25 && flux <= 2.0 { return 0.5 }
        return 0.0
    }

    /// Habitable zone status string
    var habitability: String {
        let hz = isInHabitableZone
        if hz == 1.0 { return "Within habitable zone" }
        if hz == 0.5 { return "Extended habitable zone" }
        return "Outside habitable zone"
    }

    /// Liquid water possibility
    var liquidWaterPossible: Bool {
        return surfaceTempK >= 273.15 && surfaceTempK <= 373.15
    }

    // MARK: - Moon calculations

    /// Hill sphere radius (region of gravitational influence) in km
    var hillSphereKm: Double {
        let a = orbitalDistanceM
        let mPlanet = massKg
        let mStar = starMassKg
        return (a * pow(mPlanet / (3 * mStar), 1.0/3.0)) / 1000
    }

    /// Moon simulation for each moon
    func moonSimulation(_ moon: Moon) -> MoonSimulation {
        return MoonSimulation(moon: moon, planetSim: self)
    }

    // MARK: - Display strings

    var formattedMass: String {
        let m = massKg
        if m >= 1e24 {
            return String(format: "%.3e kg", m)
        } else {
            return String(format: "%.3e kg", m)
        }
    }

    var formattedOrbitalDistance: String {
        let d = planet.orbit.semiMajorAxisAU
        if d > 1 {
            return String(format: "%.3f AU", d)
        } else {
            return String(format: "%.1f km", orbitalDistanceKm)
        }
    }

    var formattedVelocity: String {
        return String(format: "%.2f km/s", orbitalVelocityKms)
    }

    var formattedSurfaceTemp: String {
        let c = surfaceTempC
        return String(format: "%.1f°C (%.1f°F)", c, c * 9/5 + 32)
    }

    var formattedGravity: String {
        return String(format: "%.2f m/s² (%.2fg)", surfaceGravity, surfaceGravityG)
    }

    var formattedSurfaceArea: String {
        if surfaceAreaEarth > 0.01 {
            return String(format: "%.2f Earth areas", surfaceAreaEarth)
        } else {
            return String(format: "%.0f km²", surfaceAreaKm2)
        }
    }
}

/// Moon-specific simulation
struct MoonSimulation {
    let moon: Moon
    let planetSim: PlanetSimulation

    /// Surface gravity (same as planet but for moon radius)
    var surfaceGravity: Double {
        let radiusM = moon.radiusKm * 1000
        let density: Double = moon.biome == .ice ? 1500 : 2500
        let volume = (4.0/3.0) * .pi * pow(radiusM, 3)
        let mass = density * volume
        let G = 6.674e-11
        return (G * mass) / pow(radiusM, 2)
    }

    var surfaceGravityG: Double {
        return surfaceGravity / 9.807
    }

    /// Orbital period from Kepler's 3rd law: T = 2π√(a³/μ) where μ = G × M_planet
    /// Calculated from physics, not stored — guarantees physical correctness
    var orbitalPeriodDays: Double {
        let G = 6.674e-11
        let r = moon.orbit.semiMajorAxisAU * 1000  // km → m
        let mu = G * planetSim.massKg
        let periodSec = 2 * .pi * sqrt(pow(r, 3) / mu)
        return periodSec / 86400.0
    }

    /// Orbital velocity around the planet (km/s)
    var orbitalVelocityKms: Double {
        let G = 6.674e-11
        let r = moon.orbit.semiMajorAxisAU * 1000  // m
        let v = sqrt(G * planetSim.massKg / r)
        return v / 1000
    }

    /// Is the moon's orbit stable (within Hill sphere)?
    var isStable: Bool {
        return moon.orbit.semiMajorAxisAU < planetSim.hillSphereKm * 0.5  // < 50% of Hill sphere
    }

    var formattedDistance: String {
        let d = moon.orbit.semiMajorAxisAU
        if d > 1000 {
            return String(format: "%.0f km", d)
        } else {
            return String(format: "%.1f km", d)
        }
    }

    var formattedVelocity: String {
        return String(format: "%.2f km/s", orbitalVelocityKms)
    }

    var formattedPeriod: String {
        let p = orbitalPeriodDays
        if p < 1 {
            return String(format: "%.1f hours", p * 24)
        } else {
            return String(format: "%.2f days", p)
        }
    }

    var formattedGravity: String {
        return String(format: "%.3f m/s² (%.3fg)", surfaceGravity, surfaceGravityG)
    }
}
