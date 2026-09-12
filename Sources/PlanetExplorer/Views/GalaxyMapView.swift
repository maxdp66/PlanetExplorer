import SwiftUI

// MARK: - Galaxy Map View (2D radial overview of all systems)

struct GalaxyMapView: View {
    let systems: [StarSystem]
    @Binding var selectedSystem: Int?
    let onSelect: (Int) -> Void

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ScrollView([.horizontal, .vertical]) {
                ZStack {
                    // Deep space background
                    Color.black

                    // Subtle starfield noise
                    ForEach(0..<200, id: \.self) { _ in
                        Circle()
                            .fill(Color.white.opacity(Double.random(in: 0.05...0.3)))
                            .frame(width: CGFloat.random(in: 0.5...1.5))
                            .position(
                                x: CGFloat.random(in: 0...max(geo.size.width, 2000)),
                                y: CGFloat.random(in: 0...max(geo.size.height, 2000))
                            )
                    }

                    // Radial grid — concentric orbital rings
                    ForEach(1..<6) { ring in
                        let r = CGFloat(ring) * size * 0.15
                        Circle()
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                            .frame(width: r * 2, height: r * 2)
                            .position(center)
                    }

                    // Radial axis lines (spokes)
                    ForEach(0..<12) { spoke in
                        let angle = Double(spoke) * (.pi / 6)
                        Path { path in
                            path.move(to: center)
                            path.addLine(to: CGPoint(
                                x: center.x + cos(angle) * size * 0.9,
                                y: center.y + sin(angle) * size * 0.9
                            ))
                        }
                        .stroke(Color.white.opacity(0.03), lineWidth: 0.5)
                    }

                    // Habitable zone band (green ring)
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 1.5)
                        .frame(width: size * 0.45 * 2, height: size * 0.45 * 2)
                        .position(center)

                    // Systems positioned by golden-angle spiral
                    ForEach(0..<systems.count, id: \.self) { i in
                        let pos = systemPosition(i, center: center, minSize: size)
                        let isSelected = (selectedSystem == i)
                        let system = systems[i]

                        Button(action: {
                            selectedSystem = i
                            onSelect(i)
                        }) {
                            ZStack {
                                // Selection ring
                                if isSelected {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 28, height: 28)
                                        .position(pos)
                                }

                                // Star dot
                                Circle()
                                    .fill(Color(
                                        red: Double(system.starType.color.r),
                                        green: Double(system.starType.color.g),
                                        blue: Double(system.starType.color.b)
                                    ))
                                    .frame(width: isSelected ? 14 : 10, height: isSelected ? 14 : 10)
                                    .position(pos)
                                    .shadow(color: Color(
                                        red: Double(system.starType.color.r),
                                        green: Double(system.starType.color.g),
                                        blue: Double(system.starType.color.b)
                                    ), radius: isSelected ? 6 : 2)

                                // System name label
                                Text(system.name)
                                    .font(.system(size: 7, weight: isSelected ? .semibold : .regular, design: .serif))
                                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
                                    .position(x: pos.x, y: pos.y + 16)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // Center marker
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 20, height: 20)
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            .frame(width: 20, height: 20)
                    }
                    .position(center)

                    // Scale marker (dashed red line across bottom)
                    Path { path in
                        let y = center.y + size * 0.7
                        path.move(to: CGPoint(x: center.x - size * 0.3, y: y))
                        path.addLine(to: CGPoint(x: center.x + size * 0.3, y: y))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundColor(.red.opacity(0.4))

                    Text("~50,000 ly")
                        .font(.system(size: 8, design: .serif))
                        .foregroundColor(.red.opacity(0.6))
                        .position(x: center.x, y: center.y + size * 0.73)
                }
                .frame(width: max(geo.size.width, 2000), height: max(geo.size.height, 2000))
            }
        }
        .background(Color.black)
    }

    private func systemPosition(_ i: Int, center: CGPoint, minSize: CGFloat) -> CGPoint {
        let angle = Double(i) * 2.399963  // golden angle
        let radius = CGFloat(i) * minSize * 0.025 + minSize * 0.08
        return CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }
}

// MARK: - Planet Info Sidebar

struct PlanetInfoView: View {
    let planet: Planet?
    let starType: StarType?
    @StateObject private var clock = Clock()

    var body: some View {
        if let planet = planet {
            let sim = PlanetSimulation(planet: planet, star: starType ?? .gType)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(planet.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(planet.type.name)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Divider().background(Color.gray)

                    // Live orbital data
                    Group {
                        Text("Orbital Data")
                            .font(.headline)
                            .foregroundColor(.cyan)
                        InfoRow(label: "Distance from star", value: sim.formattedOrbitalDistance)
                        InfoRow(label: "Orbital velocity", value: sim.formattedVelocity)
                        InfoRow(label: "Orbital period", value: String(format: "%.2f days", sim.orbitalPeriodDays))
                        InfoRow(label: "Eccentricity", value: String(format: "%.4f", sim.eccentricity))
                    }

                    Divider().background(Color.gray)

                    // Live physical data
                    Group {
                        Text("Physical Properties")
                            .font(.headline)
                            .foregroundColor(.orange)
                        InfoRow(label: "Mass", value: sim.formattedMass)
                        InfoRow(label: "Surface gravity", value: sim.formattedGravity)
                        InfoRow(label: "Escape velocity", value: String(format: "%.2f km/s", sim.escapeVelocityKms))
                        InfoRow(label: "Surface area", value: sim.formattedSurfaceArea)
                    }

                    Divider().background(Color.gray)

                    // Live environment data
                    Group {
                        Text("Environment")
                            .font(.headline)
                            .foregroundColor(.green)
                        InfoRow(label: "Surface temp", value: sim.formattedSurfaceTemp)
                        InfoRow(label: "Solar flux", value: String(format: "%.2f Earth flux", sim.solarFluxEarth))
                        InfoRow(label: "Habitability", value: sim.habitability)
                        InfoRow(label: "Liquid water", value: sim.liquidWaterPossible ? "Possible" : "No")
                    }

                    if let biome = planet.biome {
                        Divider().background(Color.gray)
                        Group {
                            Text("Biome")
                                .font(.headline)
                                .foregroundColor(.purple)
                            InfoRow(label: "Type", value: biome.name)
                            HStack {
                                Text("Flora:")
                                    .foregroundColor(.gray)
                                Image(systemName: planet.hasFlora ? "leaf.fill" : "xmark.circle")
                                    .foregroundColor(planet.hasFlora ? .green : .red)
                            }
                            HStack {
                                Text("Fauna:")
                                    .foregroundColor(.gray)
                                Image(systemName: planet.hasFauna ? "pawprint.fill" : "xmark.circle")
                                    .foregroundColor(planet.hasFauna ? .green : .red)
                            }
                        }
                    }

                    Divider().background(Color.gray)

                    if !planet.moons.isEmpty {
                        Text("Moons (\(planet.moons.count))")
                            .font(.headline)
                            .foregroundColor(.white)

                        ForEach(0..<planet.moons.count, id: \.self) { i in
                            let moon = planet.moons[i]
                            let moonSim = sim.moonSimulation(moon)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Moon \(i + 1)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                HStack {
                                    Text(moon.biome.name)
                                        .font(.caption)
                                    Spacer()
                                    Text(String(format: "%.0f km", moon.radiusKm))
                                        .font(.caption)
                                }
                                .foregroundColor(.gray)
                                HStack {
                                    Text("Distance: \(moonSim.formattedDistance)")
                                        .font(.caption)
                                    Spacer()
                                    Text("v: \(moonSim.formattedVelocity)")
                                        .font(.caption)
                                }
                                .foregroundColor(.gray)
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
        } else {
            VStack {
                Image(systemName: "globe")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
                Text("Select a planet")
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text("\(label):")
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
    }
}

/// Ticks every second to force UI refresh for "live" data display.
final class Clock: ObservableObject {
    @Published var now: Date = Date()

    init() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.now = Date()
            }
        }
    }
}

// MARK: - Control Hints Overlay

struct ControlsOverlay: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Controls")
                .font(.headline)
                .foregroundColor(.white)

            Group {
                ControlRow(key: "W/A/S/D", action: "Move")
                ControlRow(key: "Q/E", action: "Up/Down")
                ControlRow(key: "Mouse Drag", action: "Look")
                ControlRow(key: "Scroll", action: "Zoom")
                ControlRow(key: "Shift", action: "Speed Boost")
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }
}

struct ControlRow: View {
    let key: String
    let action: String

    var body: some View {
        HStack {
            Text(key)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.yellow)
            Text(action)
                .font(.caption)
                .foregroundColor(.white)
            Spacer()
        }
    }
}

// MARK: - Galaxy System Selector

struct SystemSelectorView: View {
    let systems: [StarSystem]
    @Binding var selectedIndex: Int?
    let onJump: (Int) -> Void

    var body: some View {
        HStack {
            Text("System:")
                .foregroundColor(.gray)

            Picker("", selection: $selectedIndex) {
                Text("Select...").tag(nil as Int?)
                ForEach(0..<systems.count, id: \.self) { i in
                    Text(systems[i].name).tag(i as Int?)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 200)

            if let idx = selectedIndex {
                Button("Jump to System") {
                    onJump(idx)
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()

            Text("\(systems.count) systems • \(systems.reduce(0) { $0 + $1.planets.count }) planets")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
}
