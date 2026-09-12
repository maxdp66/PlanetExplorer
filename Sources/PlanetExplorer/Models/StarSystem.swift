/// A star system with a central star and orbiting planets.
///
/// Positioned in a spiral galaxy pattern using golden-angle distribution.
struct StarSystem {
    var seed: String
    var name: String
    var planets: [Planet]
    var starRadius: Double
    var starColor: StarColor
    var position: StarPosition
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
    let x: Double
    let y: Double
    let z: Double

    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}
