import SwiftUI
import Combine

/// Radial map of a single star system, inspired by vintage Solar System infographics.
struct SystemMapView: View {
    let system: StarSystem
    @ObservedObject private var hoverState = HoverState()

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let maxRadius = min(geo.size.width, geo.size.height) * 0.75 / 2

            ScrollView([.horizontal, .vertical]) {
                ZStack {
                    Color.black

                    // Starfield
                    ForEach(0..<150, id: \.self) { _ in
                        Circle()
                            .fill(Color.white.opacity(Double.random(in: 0.03...0.2)))
                            .frame(width: CGFloat.random(in: 0.5...1.5))
                            .position(
                                x: CGFloat.random(in: 0...max(geo.size.width, 1600)),
                                y: CGFloat.random(in: 0...max(geo.size.height, 1600))
                            )
                    }

                    // Habitable zone band
                    Circle()
                        .stroke(Color.green.opacity(0.15), lineWidth: 30)
                        .frame(width: maxRadius * 0.7 * 2, height: maxRadius * 0.7 * 2)
                        .position(center)

                    // Orbital rings
                    ForEach(0..<system.planets.count, id: \.self) { i in
                        let orbitRadius = orbitRadius(for: i, maxRadius: maxRadius)
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                            .frame(width: orbitRadius * 2, height: orbitRadius * 2)
                            .position(center)
                    }

                    // Radial spokes
                    ForEach(0..<12) { spoke in
                        let angle = Double(spoke) * (.pi / 6)
                        Path { path in
                            path.move(to: center)
                            path.addLine(to: CGPoint(
                                x: center.x + cos(angle) * maxRadius,
                                y: center.y + sin(angle) * maxRadius
                            ))
                        }
                        .stroke(Color.white.opacity(0.02), lineWidth: 0.5)
                    }

                    // Central star
                    ZStack {
                        Circle()
                            .fill(RadialGradient(
                                colors: [
                                    Color(red: Double(system.starColor.r), green: Double(system.starColor.g), blue: Double(system.starColor.b)).opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 50
                            ))
                            .frame(width: 100, height: 100)

                        Circle()
                            .fill(RadialGradient(
                                colors: [
                                    Color(
                                        red: Double(system.starColor.r),
                                        green: Double(system.starColor.g),
                                        blue: Double(system.starColor.b)
                                    ).opacity(0.9),
                                    Color(
                                        red: Double(system.starColor.r) * 0.6,
                                        green: Double(system.starColor.g) * 0.6,
                                        blue: Double(system.starColor.b) * 0.6
                                    )
                                ],
                                center: .init(x: 0.35, y: 0.35),
                                startRadius: 5,
                                endRadius: 30
                            ))
                            .frame(width: 40, height: 40)
                            .shadow(color: Color(
                                red: Double(system.starColor.r),
                                green: Double(system.starColor.g),
                                blue: Double(system.starColor.b)
                            ), radius: 15)
                    }
                    .position(center)

                    // Star label
                    Text(system.name)
                        .font(.system(size: 10, weight: .semibold, design: .serif))
                        .foregroundColor(.white.opacity(0.7))
                        .position(x: center.x, y: center.y + 35)

                    // Planets
                    ForEach(0..<system.planets.count, id: \.self) { i in
                        let planet = system.planets[i]
                        let orbitRadius = orbitRadius(for: i, maxRadius: maxRadius)
                        let angle = Double(i) * 0.8
                        let pos = CGPoint(
                            x: center.x + cos(angle) * orbitRadius,
                            y: center.y + sin(angle) * orbitRadius
                        )

                        PlanetOrbitalView(
                            planet: planet,
                            position: pos,
                            isHovered: Binding(
                                get: { hoverState.hoveredIndex == i },
                                set: { _ in
                                    hoverState.hoveredIndex = hoverState.hoveredIndex == i ? nil : i
                                }
                            )
                        )
                    }

                    // Scale marker
                    Path { path in
                        let y = center.y + maxRadius + 40
                        path.move(to: CGPoint(x: center.x - 80, y: y))
                        path.addLine(to: CGPoint(x: center.x + 80, y: y))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .foregroundColor(.red.opacity(0.3))

                    Text("NOT TO SCALE")
                        .font(.system(size: 7, design: .serif))
                        .foregroundColor(.red.opacity(0.4))
                        .position(x: center.x, y: center.y + maxRadius + 55)
                }
                .frame(width: max(geo.size.width, 1600), height: max(geo.size.height, 1600))
            }
        }
        .background(Color.black)
    }

    private func orbitRadius(for index: Int, maxRadius: CGFloat) -> CGFloat {
        let fraction = CGFloat(index + 1) / CGFloat(system.planets.count + 1)
        return maxRadius * fraction
    }
}

/// Tracks which planet is currently hovered, without @State macros.
final class HoverState: ObservableObject {
    @Published var hoveredIndex: Int? = nil
}

struct PlanetOrbitalView: View {
    let planet: Planet
    let position: CGPoint
    @Binding var isHovered: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(
                    red: Double(planet.type.color.r),
                    green: Double(planet.type.color.g),
                    blue: Double(planet.type.color.b)
                ))
                .frame(width: planetSize, height: planetSize)
                .shadow(color: Color(
                    red: Double(planet.type.color.r),
                    green: Double(planet.type.color.g),
                    blue: Double(planet.type.color.b)
                ), radius: isHovered ? 6 : 2)
                .scaleEffect(isHovered ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)

            Text(planet.name)
                .font(.system(size: 7, weight: .medium, design: .serif))
                .foregroundColor(.white.opacity(isHovered ? 1.0 : 0.6))
                .position(x: position.x, y: position.y + planetSize / 2 + 10)

            if isHovered {
                VStack(alignment: .leading, spacing: 2) {
                    Text(planet.type.name)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                    Text(planet.formattedRadius)
                        .font(.system(size: 7))
                        .foregroundColor(.gray)
                    if let biome = planet.biome {
                        Text(biome.name)
                            .font(.system(size: 7))
                            .foregroundColor(.gray)
                    }
                    if planet.hasFlora {
                        Label("Flora", systemImage: "leaf.fill")
                            .font(.system(size: 7))
                            .foregroundColor(.green)
                    }
                    if planet.hasFauna {
                        Label("Fauna", systemImage: "pawprint.fill")
                            .font(.system(size: 7))
                            .foregroundColor(.green)
                    }
                    if !planet.moons.isEmpty {
                        Text("\(planet.moons.count) moon\(planet.moons.count == 1 ? "" : "s")")
                            .font(.system(size: 7))
                            .foregroundColor(.gray)
                    }
                }
                .padding(6)
                .background(Color.black.opacity(0.85))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .position(x: position.x + 60, y: position.y - 30)
            }
        }
        .position(position)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var planetSize: CGFloat {
        let base: CGFloat = 6
        let scale = CGFloat(log10(planet.radiusKm / 1000.0 + 1)) * 3
        return base + scale
    }
}
