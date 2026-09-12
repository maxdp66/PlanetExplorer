import SceneKit
import SwiftUI

/// SceneKit-based 3D planet renderer with fly-around camera
class PlanetScene: SCNView {
    private var cameraNode: SCNNode!
    private var cameraOrbit: SCNNode!
    private var planetNode: SCNNode?
    private var starField: SCNNode?
    private var moonsNode: SCNNode?

    var arcadeMode: Bool = false

    // Camera state
    private var cameraDistance: Float = 30.0
    private var cameraYaw: Float = 0.0
    private var cameraPitch: Float = 0.3

    // Movement
    private var moveForward = false
    private var moveBackward = false
    private var moveLeft = false
    private var moveRight = false
    private var moveUp = false
    private var moveDown = false
    private var rollLeft = false
    private var rollRight = false
    private var speedBoost = false

    private var lastFrameTime: TimeInterval = 0
    private var displayLink: CVDisplayLink?

    override init(frame: NSRect, options: [String: Any]? = nil) {
        super.init(frame: frame, options: options)
        setupScene()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScene()
    }

    private func setupScene() {
        // Create the scene
        let scene = SCNScene()
        self.scene = scene
        self.backgroundColor = NSColor.black
        self.allowsCameraControl = false  // We handle camera ourselves
        self.showsStatistics = false
        self.antialiasingMode = .multisampling4X

        // Camera rig: orbit node -> camera node
        cameraOrbit = SCNNode()
        cameraOrbit.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(cameraOrbit)

        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 60
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 1_000_000
        cameraNode.position = SCNVector3(0, 0, cameraDistance)
        cameraOrbit.addChildNode(cameraNode)

        // Lighting
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.light?.intensity = 1000
        lightNode.position = SCNVector3(10, 10, 10)
        scene.rootNode.addChildNode(lightNode)

        let ambientNode = SCNNode()
        ambientNode.light = SCNLight()
        ambientNode.light?.type = .ambient
        ambientNode.light?.intensity = 200
        scene.rootNode.addChildNode(ambientNode)

        // Star field background
        createStarField()

        // Start render loop
        startRenderLoop()
    }

    private func createStarField() {
        let starCount = 5000
        let stars = SCNNode()

        for _ in 0..<starCount {
            let star = SCNNode()
            let sphere = SCNSphere(radius: 0.5)
            sphere.segmentCount = 4
            star.geometry = sphere

            let material = SCNMaterial()
            material.emission.contents = NSColor.white
            material.diffuse.contents = NSColor.white
            star.geometry?.materials = [material]

            // Random position on a large sphere
            let theta = Float.random(in: 0...(2 * .pi))
            let phi = Float.random(in: 0...(.pi))
            let r: Float = 5000
            star.position = SCNVector3(
                r * sin(phi) * cos(theta),
                r * sin(phi) * sin(theta),
                r * cos(phi)
            )
            stars.addChildNode(star)
        }

        scene?.rootNode.addChildNode(stars)
        starField = stars
    }

    func displayPlanet(_ planet: Planet) {
        // Remove existing planet
        planetNode?.removeFromParentNode()
        moonsNode?.removeFromParentNode()

        // Create planet sphere
        let planetSCN = SCNNode()
        let radius = Float(planet.radiusKm / 10000.0)  // Scale down for display
        let sphere = SCNSphere(radius: CGFloat(max(radius, 1.0)))
        sphere.segmentCount = 64
        planetSCN.geometry = sphere

        let material = SCNMaterial()
        let c = planet.type.color
        material.diffuse.contents = NSColor(red: CGFloat(c.r), green: CGFloat(c.g), blue: CGFloat(c.b), alpha: CGFloat(c.a))
        material.specular.contents = NSColor.white
        material.shininess = 0.3

        // Add some procedural noise texture for visual interest
        if planet.type == .terrestrial || planet.type == .superEarth {
            material.normal.contents = generateNoiseTexture(size: 512)
            material.normal.intensity = 0.3
        }

        // Gas giants get banded texture
        if planet.type == .gasGiant || planet.type == .hotJupiter || planet.type == .iceGiant {
            material.diffuse.contents = generateBandedTexture(planetType: planet.type, size: 512)
        }

        planetSCN.geometry?.materials = [material]
        planetSCN.position = SCNVector3(0, 0, 0)

        // Calculate planet rotation period from physics
        // Using breakup angular velocity: P_min = sqrt(3π / (G × ρ))
        let G = 6.674e-11
        let density = PlanetSimulation(planet: planet, star: .gType).density  // kg/m³
        let breakupPeriodSec = sqrt(3 * .pi / (G * density))
        let breakupPeriodHours = breakupPeriodSec / 3600
        // Real planets rotate well below breakup speed (factor of 2-10)
        let rotationFactor = Double.random(in: 2.5...8.0)
        let rotationHours = breakupPeriodHours * rotationFactor
        
        // Arcade mode: speed up 10x for visual effect
        let rotationDuration = arcadeMode ? rotationHours * 0.05 : rotationHours * 0.5

        let rotate = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: max(rotationDuration, 0.5))
        let repeatRotate = SCNAction.repeatForever(rotate)
        planetSCN.runAction(repeatRotate)

        scene?.rootNode.addChildNode(planetSCN)
        planetNode = planetSCN

        // Create moons with physics-based orbital periods
        let moonsSCN = SCNNode()
        for (i, moon) in planet.moons.enumerated() {
            let moonNode = SCNNode()
            let moonRadius = Float(moon.radiusKm / 10000.0)
            let moonSphere = SCNSphere(radius: CGFloat(max(moonRadius, 0.3)))
            moonSphere.segmentCount = 16
            moonNode.geometry = moonSphere

            let moonMat = SCNMaterial()
            let mc = moon.biome.color
            moonMat.diffuse.contents = NSColor(red: CGFloat(mc.r), green: CGFloat(mc.g), blue: CGFloat(mc.b), alpha: CGFloat(mc.a))
            moonNode.geometry?.materials = [moonMat]

            // Use the moon's actual orbital period from generation
            let orbitalPeriodDays = moon.orbit.periodDays
            
            // Scale period for visualization: logarithmic scale to show differences
            // Closer moons orbit much faster than distant ones
            let logPeriod = log10(orbitalPeriodDays + 1)
            let vizDuration = max(logPeriod * 3.0, 1.0)

            // Orbit radius: scale with moon's actual distance (log scale for visibility)
            let orbitRadius = Float(2.0 + log10(moon.orbit.semiMajorAxisAU / 1000.0 + 1) * 2.5)

            let orbitNode = SCNNode()
            orbitNode.position = SCNVector3(0, 0, 0)
            moonNode.position = SCNVector3(orbitRadius, 0, 0)
            orbitNode.addChildNode(moonNode)

            let orbitRotate = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: Double(vizDuration))
            let repeatOrbit = SCNAction.repeatForever(orbitRotate)
            orbitNode.runAction(repeatOrbit)

            moonsSCN.addChildNode(orbitNode)
        }
        scene?.rootNode.addChildNode(moonsSCN)
        moonsNode = moonsSCN

        // Reset camera distance based on planet size
        cameraDistance = max(radius * 4, 10)
        updateCameraPosition()
    }

    private func generateNoiseTexture(size: Int) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        let context = NSGraphicsContext.current!.cgContext

        for y in 0..<size {
            for x in 0..<size {
                let noise = CGFloat.random(in: 0...1)
                context.setFillColor(gray: noise, alpha: 1.0)
                context.fill(CGRect(x: x, y: y, width: 1, height: 1))
            }
        }

        image.unlockFocus()
        return image
    }

    private func generateBandedTexture(planetType: PlanetType, size: Int) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        let context = NSGraphicsContext.current!.cgContext

        let baseColor: (r: Float, g: Float, b: Float)
        switch planetType {
        case .gasGiant: baseColor = (0.8, 0.6, 0.2)
        case .hotJupiter: baseColor = (0.9, 0.3, 0.2)
        case .iceGiant: baseColor = (0.4, 0.6, 0.9)
        default: baseColor = (0.5, 0.5, 0.5)
        }

        for y in 0..<size {
            let band = sin(Float(y) / Float(size) * .pi * 8)
            let intensity = 0.7 + 0.3 * band
            for x in 0..<size {
                let noise = Float.random(in: -0.05...0.05)
                let r = min(max(baseColor.r * intensity + noise, 0), 1)
                let g = min(max(baseColor.g * intensity + noise, 0), 1)
                let b = min(max(baseColor.b * intensity + noise, 0), 1)
                context.setFillColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
                context.fill(CGRect(x: x, y: y, width: 1, height: 1))
            }
        }

        image.unlockFocus()
        return image
    }

    // MARK: - Camera Control

    private func updateCameraPosition() {
        let x = cameraDistance * cos(cameraPitch) * sin(cameraYaw)
        let y = cameraDistance * sin(cameraPitch)
        let z = cameraDistance * cos(cameraPitch) * cos(cameraYaw)
        cameraNode.position = SCNVector3(x, y, z)
        cameraNode.look(at: SCNVector3(0, 0, 0))
    }

    private func startRenderLoop() {
        // Use a Timer for the update loop (CVDisplayLink is more complex)
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    private func update() {
        let speed: Float = speedBoost ? 2.0 : 0.5

        if moveForward { cameraDistance = max(cameraDistance - speed, 2.0) }
        if moveBackward { cameraDistance += speed }
        if moveLeft { cameraYaw -= 0.02 }
        if moveRight { cameraYaw += 0.02 }
        if moveUp { cameraPitch = min(cameraPitch + 0.02, .pi/2 - 0.01) }
        if moveDown { cameraPitch = max(cameraPitch - 0.02, -.pi/2 + 0.01) }

        updateCameraPosition()
    }

    // MARK: - Key Handling

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        handleKey(event, down: true)
    }

    override func keyUp(with event: NSEvent) {
        handleKey(event, down: false)
    }

    private func handleKey(_ event: NSEvent, down: Bool) {
        switch event.keyCode {
        case 13: moveForward = down      // W
        case 1: moveBackward = down      // S
        case 0: moveLeft = down          // A
        case 2: moveRight = down         // D
        case 14: moveUp = down           // E
        case 12: moveDown = down         // Q
        case 123: if down { cameraYaw -= 0.05 }  // Left arrow
        case 124: if down { cameraYaw += 0.05 }  // Right arrow
        case 126: if down { cameraPitch = min(cameraPitch + 0.05, .pi/2 - 0.01) }  // Up arrow
        case 125: if down { cameraPitch = max(cameraPitch - 0.05, -.pi/2 + 0.01) }  // Down arrow
        default:
            if event.modifierFlags.contains(.shift) {
                speedBoost = down
            }
            break
        }
    }

    override func mouseDragged(with event: NSEvent) {
        cameraYaw += Float(event.deltaX) * 0.005
        cameraPitch = max(-.pi/2 + 0.01, min(.pi/2 - 0.01, cameraPitch - Float(event.deltaY) * 0.005))
        updateCameraPosition()
    }

    override func scrollWheel(with event: NSEvent) {
        cameraDistance = max(2.0, cameraDistance - Float(event.deltaY) * 0.5)
        updateCameraPosition()
    }
}

/// SwiftUI wrapper for the SceneKit planet view
struct PlanetSceneView: NSViewRepresentable {
    let planet: Planet?
    var arcadeMode: Bool = false

    func makeNSView(context: Context) -> PlanetScene {
        let scene = PlanetScene(frame: .zero)
        scene.arcadeMode = arcadeMode
        return scene
    }

    func updateNSView(_ nsView: PlanetScene, context: Context) {
        nsView.arcadeMode = arcadeMode
        if let planet = planet {
            nsView.displayPlanet(planet)
        }
    }
}
