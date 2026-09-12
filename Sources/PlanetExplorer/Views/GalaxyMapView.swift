import SwiftUI

// MARK: - Galaxy Map View (2D overview of all systems)

struct GalaxyMapView: View {
    let systems: [StarSystem]
    @Binding var selectedSystem: Int?
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack {
                // Background
                Color.black

                // Galaxy background gradient
                RadialGradient(
                    colors: [
                        Color.purple.opacity(0.15),
                        Color.black
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 800
                )

                // Connection lines between nearby systems
                ForEach(0..<systems.count, id: \.self) { i in
                    if i > 0 {
                        Path { path in
                            let p1 = systemPosition(i - 1)
                            let p2 = systemPosition(i)
                            path.move(to: p1)
                            path.addLine(to: p2)
                        }
                        .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
                    }
                }

                // System dots
                ForEach(0..<systems.count, id: \.self) { i in
                    let pos = systemPosition(i)
                    let isSelected = (selectedSystem == i)

                    Button(action: {
                        selectedSystem = i
                        onSelect(i)
                    }) {
                        ZStack {
                            Circle()
                                .fill(systemColor(i))
                                .frame(width: isSelected ? 16 : 10, height: isSelected ? 16 : 10)

                            if isSelected {
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 22, height: 22)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .position(pos)
                    .overlay(
                        Text(systems[i].name)
                            .font(.system(size: 8))
                            .foregroundColor(isSelected ? .white : .gray)
                            .offset(y: 14)
                            .position(pos)
                    )
                }
            }
            .frame(width: 2000, height: 2000)
        }
        .background(Color.black)
    }

    private func systemPosition(_ i: Int) -> CGPoint {
        let angle = Double(i) * 2.399963  // golden angle
        let radius = Double(i) * 120.0 + 100.0
        let x = 1000.0 + cos(angle) * radius
        let y = 1000.0 + sin(angle) * radius
        return CGPoint(x: x, y: y)
    }

    private func systemColor(_ i: Int) -> Color {
        let planets = systems[i].planets
        if planets.contains(where: { $0.hasFlora || $0.hasFauna }) {
            return .green
        }
        if planets.contains(where: { $0.type == .terrestrial || $0.type == .superEarth }) {
            return .blue
        }
        return .orange
    }
}

// MARK: - Planet Info Sidebar

struct PlanetInfoView: View {
    let planet: Planet?

    var body: some View {
        if let planet = planet {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
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

                    // Stats
                    Group {
                        InfoRow(label: "Radius", value: planet.formattedRadius)
                        InfoRow(label: "Moons", value: planet.moonCount)

                        if let biome = planet.biome {
                            InfoRow(label: "Biome", value: biome.name)
                        }

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

                    Divider().background(Color.gray)

                    // Moons list
                    if !planet.moons.isEmpty {
                        Text("Moons (\(planet.moons.count))")
                            .font(.headline)
                            .foregroundColor(.white)

                        ForEach(0..<planet.moons.count, id: \.self) { i in
                            let moon = planet.moons[i]
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
