//
//  ViewController.swift
//  SceneKitWorkshop
//
//  Created by Jurian de Cocq van Delwijnen on 21/10/2018.
//  Copyright © 2018 Sogeti. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class Plane: SCNNode {
    let plane: SCNBox
    let planeNode: SCNNode
    let planeHeight: Float = 0.1
    
    override init() {
        plane = SCNBox(width: 1, height: CGFloat(planeHeight), length: 1, chamferRadius: 0)
        planeNode = SCNNode(geometry: plane)
        super.init()
        addChildNode(planeNode)
        show(true)
    }
    
    func show(_ visible: Bool) {
        var materials = Array(repeating: SCNNode.material(for: UIColor.clear), count: 6)
        if visible {
            let color = UIColor.green.withAlphaComponent(0.7)
            materials[4] = SCNNode.material(for: color)
        }
        plane.materials = materials
    }
    
    func update(for anchor: ARPlaneAnchor) {
        plane.width = CGFloat(anchor.extent.x)
        plane.length = CGFloat(anchor.extent.z)
        let shape = SCNPhysicsShape(geometry: plane, options: nil)
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
        planeNode.position = SCNVector3(x: anchor.center.x, y: -planeHeight/2, z: anchor.center.z)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Ignore this method. It's required but won't serve us now.")
    }
}

// --------  Assignment 3  --------
//  We're able to detect a playing field, we're able to add balls, we can shoot the balls
//  Let's make sure our app looks like a poolgame
//  Assignment 3 is all about cleaning up
//
//  Open the ImageIterator class
//  I've added something called the sharedImageIterator
//  This will loop through images that can ensure our poolballs look like they're supposed to
//  1. Go back to our sphere class and change the material from red to sharedImageIterator.next()!
//  Run the app again and notice the different type of pool balls
//  The debug colors are still breaking our immersion though, let's get rid of those
//
//  2. Inside of the ViewController class let's get rid of the debug options
//  Remove the line: sceneView.debugOptions = [.showPhysicsShapes]
//  Run the app again and notice how it's a lot better already!
//  The final step to interacting with virtual objects in the physical world is the green plane we've defined
//
//  3. Change the show(true) method call to show(false) in plane to get rid of the green plane
//
//
//
//  Now after implementing these 3 final cleanup steps we're able to map some poolballs in a virtual world
//      on top of a physical plane!
//  Off course it's not a fully fleshed out game yet but you can see how with a few simple steps
//      you're able to already get quite far!
//
//
//  For more AR assignment check out:
//  https://github.com/cocqvaju/ARKitWorkshop
//  Which also contains assignments for SpriteKit, the 2d AR framework by Apple
// --------------------------------

class Sphere: SCNNode {
    let sphere: SCNSphere
    let radius: Float = 0.025
    
    override init() {
        self.sphere = SCNSphere(radius: CGFloat(radius))
        sphere.materials = [SCNNode.material(for: UIColor.red)]
        super.init()
        self.geometry = sphere
        let shape = SCNPhysicsShape(geometry: sphere, options: nil)
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Ignore this method. It's required but won't serve us now.")
    }
    
    func position(at transform: matrix_float4x4) {
        position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
}

extension ViewController {
    
    @objc func didTapView(sender: UITapGestureRecognizer) {
        let location = sender.location(in: sender.view)
        
        if let result = sceneView.hitTest(location, options: [:]).first, let sphere = result.node as? Sphere {
            // LocalNormal is the angle the ball is tapped and force going outwards
            let force = result.localNormal.inverse().multiply(factor: 2)
            sphere.physicsBody?.applyForce(force, asImpulse: true)
        }
        else if let result = sceneView.hitTest(location, types: .existingPlane).first {
            let sphere = Sphere()
            sphere.position(at: result.worldTransform)
            sphere.position.y += sphere.radius
            sceneView.scene.rootNode.addChildNode(sphere)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            let plane = Plane()
            plane.update(for: planeAnchor)
            planes[planeAnchor] = plane
            node.addChildNode(plane)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor, let plane = planes[planeAnchor] {
            plane.update(for: planeAnchor)
        }
    }
}

// Everything below this line is boilerplate, just some code to get SceneKit up and running

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var planes: [ARPlaneAnchor: Plane] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.showsStatistics = true
        
        sceneView.delegate = self
        
        sceneView.debugOptions = [.showPhysicsShapes]
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        sceneView.scene = SCNScene()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTapView))
        sceneView.addGestureRecognizer(gesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
}

extension SCNNode {
    class func material(for contents: Any) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = contents
        m.lightingModel = .physicallyBased
        
        return m
    }
}
