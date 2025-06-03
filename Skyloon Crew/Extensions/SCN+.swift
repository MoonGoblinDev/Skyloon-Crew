//
//  SCN+.swift
//  Skyloon Crew
//
//  Created by Bregas Satria Wicaksono on 03/06/25.
//
import SceneKit

extension SCNNode {
    convenience init(named name: String) {
        self.init()
        guard let scene = SCNScene(named: name) else {return}
        for childNode in scene.rootNode.childNodes {addChildNode(childNode)}
    }
}

extension SCNAnimationPlayer {
    class func loadAnimation(fromSceneNamed sceneName: String) -> SCNAnimationPlayer {
        let scene = SCNScene( named: sceneName )!
        // find top level animation
        var animationPlayer: SCNAnimationPlayer! = nil
        scene.rootNode.enumerateChildNodes { (child, stop) in
            if !child.animationKeys.isEmpty {
                animationPlayer = child.animationPlayer(forKey: child.animationKeys[0])
                stop.pointee = true
            }
        }
        return animationPlayer
    }
}
