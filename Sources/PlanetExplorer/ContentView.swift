import SwiftUI
import Combine

// MARK: - App State

final class AppState: ObservableObject {
    @Published var galaxy: [StarSystem] = []
    @Published var selectedSystemIndex: Int? = nil
    @Published var selectedPlanetIndex: Int? = nil
    @Published var currentPlanet: Planet? = nil
    @Published var seed: String = "default"
    @Published var isGenerating = false

    // View-local state exposed as @Published on the ObservableObject
    // instead of @State (which requires SwiftUIMacros, unavailable to swift run)
    @Published var seedInput: String = "default"
    @Published var systemCount: Int = 25
    @Published var planetsPerSystem: Int = 5
    @Published var galaxyName: String = ""

    func generateGalaxy(seed: String, systemCount: Int = 25) {
        isGenerating = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let galaxy = PlanetGenerator.generateGalaxy(
                seed: seed,
                systemCount: systemCount
            )
            DispatchQueue.main.async {
                self?.galaxy = galaxy.systems
                self?.galaxyName = galaxy.name
                self?.selectedSystemIndex = 0
                self?.selectedPlanetIndex = 0
                if let system = galaxy.systems.first, let planet = system.planets.first {
                    self?.currentPlanet = planet
                }
                self?.isGenerating = false
            }
        }
    }

    func selectSystem(_ index: Int) {
        selectedSystemIndex = index
        selectedPlanetIndex = nil
        currentPlanet = nil
    }

    func selectPlanet(_ index: Int) {
        guard let sysIdx = selectedSystemIndex, sysIdx < galaxy.count else { return }
        let system = galaxy[sysIdx]
        guard index < system.planets.count else { return }
        selectedPlanetIndex = index
        currentPlanet = system.planets[index]
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @ObservedObject private var appState = AppState()

    var body: some View {
        NavigationSplitView {
            sidebar
                .frame(minWidth: 280, maxWidth: 340)
                .background(Color.black)
        } detail: {
            detailContent
        }
        .onAppear {
            if appState.galaxy.isEmpty {
                appState.generateGalaxy(seed: "default")
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                HStack {
                    Text("Galaxy Seed:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }

                TextField("Enter seed text...", text: Binding(
                    get: { appState.seedInput },
                    set: { appState.seedInput = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(height: 24)

                Stepper("Systems: \(appState.systemCount)", value: Binding(
                    get: { appState.systemCount },
                    set: { appState.systemCount = $0 }
                ), in: 5...100)
                .font(.caption)

                Button("Generate Galaxy") {
                    appState.generateGalaxy(
                        seed: appState.seedInput,
                        systemCount: appState.systemCount
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.isGenerating)
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            if appState.isGenerating {
                ProgressView("Generating galaxy...")
                    .padding()
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(0..<appState.galaxy.count, id: \.self) { i in
                        let system = appState.galaxy[i]
                        Button(action: {
                            appState.selectSystem(i)
                        }) {
                            SystemRowView(
                                system: system,
                                isSelected: appState.selectedSystemIndex == i
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                appState.selectedSystemIndex == i
                                    ? Color.accentColor.opacity(0.3)
                                    : Color.clear
                            )
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())

                        Divider().background(Color.white.opacity(0.05))
                    }
                }
            }
            .background(Color.black)
        }
    }

    // MARK: - Detail Content

    private var detailContent: some View {
        ZStack {
            if let sysIdx = appState.selectedSystemIndex {
                let system = appState.galaxy[sysIdx]

                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(system.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("\(system.starType.description) • \(system.planets.count) planets")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()

                        Button(action: { appState.showControls.toggle() }) {
                            Image(systemName: "questionmark.circle")
                        }

                        if appState.selectedPlanetIndex != nil {
                            Button("Galaxy Map") {
                                appState.selectedPlanetIndex = nil
                                appState.currentPlanet = nil
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.9))

                    if appState.currentPlanet != nil {
                        planetView
                    } else {
                        systemOverview
                    }
                }
            } else {
                welcomeScreen
            }

            if appState.showControls {
                VStack {
                    Spacer()
                    HStack {
                        ControlsOverlay()
                        Spacer()
                    }
                    Spacer()
                }
                .onTapGesture {
                    appState.showControls = false
                }
            }
        }
    }

    private var welcomeScreen: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            Text("Planet Explorer")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Enter a seed and click 'Generate Galaxy' to begin")
                .foregroundColor(.gray)
        }
    }

    private var planetView: some View {
        HStack(spacing: 0) {
            ZStack {
                Color.black
                PlanetSceneView(planet: appState.currentPlanet)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 0) {
                HStack {
                    Button("◀ Previous") {
                        guard let pIdx = appState.selectedPlanetIndex, pIdx > 0 else { return }
                        appState.selectPlanet(pIdx - 1)
                    }
                    .disabled(appState.selectedPlanetIndex == 0)

                    Spacer()

                    Text("Planet \((appState.selectedPlanetIndex ?? 0) + 1) of \(currentSystemPlanetCount)")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Spacer()

                    Button("Next ▶") {
                        guard let pIdx = appState.selectedPlanetIndex else { return }
                        guard pIdx < currentSystemPlanetCount - 1 else { return }
                        appState.selectPlanet(pIdx + 1)
                    }
                    .disabled(appState.selectedPlanetIndex == currentSystemPlanetCount - 1)
                }
                .padding()
                .background(Color.gray.opacity(0.1))

                ScrollView {
                    PlanetInfoView(planet: appState.currentPlanet)
                }
            }
            .frame(width: 280)
            .background(Color.black)
        }
    }

    private var currentSystemPlanetCount: Int {
        guard let sysIdx = appState.selectedSystemIndex,
              sysIdx < appState.galaxy.count else { return 0 }
        return appState.galaxy[sysIdx].planets.count
    }

    private var systemOverview: some View {
        SystemMapView(system: appState.galaxy[appState.selectedSystemIndex!])
    }
}

// MARK: - System Row

struct SystemRowView: View {
    let system: StarSystem
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(Color(
                        red: Double(system.starType.color.r),
                        green: Double(system.starType.color.g),
                        blue: Double(system.starType.color.b)
                    ))
                    .frame(width: 12, height: 12)
                Text(system.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(system.planets.count)p")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            HStack(spacing: 4) {
                ForEach(0..<min(system.planets.count, 8), id: \.self) { i in
                    let planet = system.planets[i]
                    Circle()
                        .fill(Color(
                            red: Double(planet.type.color.r),
                            green: Double(planet.type.color.g),
                            blue: Double(planet.type.color.b)
                        ))
                        .frame(width: 6, height: 6)
                }
                if system.planets.count > 8 {
                    Text("+\(system.planets.count - 8)")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
        .foregroundColor(isSelected ? .white : .gray)
    }
}

// MARK: - Planet Card

struct PlanetCardView: View {
    let planet: Planet
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(
                        red: Double(planet.type.color.r),
                        green: Double(planet.type.color.g),
                        blue: Double(planet.type.color.b)
                    ))
                    .frame(width: 60, height: 60)

                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 60, height: 60)

                if planet.hasFlora {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                        .offset(x: 25, y: -25)
                        .font(.caption)
                }
            }
            .padding(.bottom, 4)

            Text(planet.name)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)

            Text(planet.type.name)
                .font(.caption)
                .foregroundColor(.gray)

            HStack {
                if let biome = planet.biome {
                    Text(biome.name)
                        .font(.system(size: 10))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(4)
                }
                Spacer()
                Text("\(planet.moons.count) moons")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(planet.hasFlora ? 0.5 : 0.1), lineWidth: 1)
        )
    }
}
