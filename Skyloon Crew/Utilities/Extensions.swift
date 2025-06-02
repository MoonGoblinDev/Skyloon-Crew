import SceneKit

// Extension for SCNVector3 linear interpolation and basic math
extension SCNVector3 {
    static func lerp(start: SCNVector3, end: SCNVector3, t: Float) -> SCNVector3 {
        let t_clamped = max(0, min(1, t)) // Ensure t is between 0 and 1
        return SCNVector3(start.x + (end.x - start.x) * CGFloat(t_clamped),
                          start.y + (end.y - start.y) * CGFloat(t_clamped),
                          start.z + (end.z - start.z) * CGFloat(t_clamped))
    }

    func length() -> Float {
        return sqrtf(Float(x*x + y*y + z*z))
    }

    func normalized() -> SCNVector3 {
        let l = self.length()
        if l == 0 { return SCNVector3Zero }
        return SCNVector3(x: x/CGFloat(l), y: y/CGFloat(l), z: z/CGFloat(l))
    }

    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
    }
}

// Operator for SCNVector3 scaling
func * (vector: SCNVector3, scalar: CGFloat) -> SCNVector3 {
    return SCNVector3(vector.x * scalar, vector.y * scalar, vector.z * scalar)
}

func * (vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return vector * CGFloat(scalar)
}

extension SCNVector3 {
    static func cross(_ vector1: SCNVector3, _ vector2: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(vector1.y * vector2.z - vector1.z * vector2.y,
                              vector1.z * vector2.x - vector1.x * vector2.z,
                              vector1.x * vector2.y - vector1.y * vector2.x)
    }
}
