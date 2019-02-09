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

// --------  Assignment 2  --------
//  So far we're detecting the table and we can add balls to it
//  Let's implement the ability to shoot our pool balls!
//
//  Shooting poolballs is actually quite simple, we only need to apply some force to our sphere
//  Because of the dynamic shape, SceneKit will do all the actual heavy lifting!
//
//  1. In didTapView under our let location change our if let result to and else if let result
//      the corrosponding if that should go with that looks like this:
//      if let result = sceneView.hitTest(location, options: [:]).first, let sphere = result.node as? Sphere {
//  We'll do a hit test and verify that we've actually tapped a sphere
//  Define a let called force, we're going to use the result.localNormal for it
//  LocalNormal is the angle the ball is tapped at but the force is define as going outwards
//  Because we want to shoot the ball in the direction we're looking call .inverse() on the localNormal
//  Inverse is not normally something part of SceneKit but I've prepared a method to use now, feel free to look at it
//
//  The tapping doesn't feel very satisfying yet, actually it's quite slow
//  Let's call .multiply(factor: 2) on the inverted force
//  Multiply isn't part of sceneKit either, it's just something I've prepared
//      so you can play around with more and less force
//
//  Finally let's call sphere.physicsBody it's applyForce method, pass our force as an impulse
//
//
//
//  Run the app and notice that you can now tap the poolballs for a very satisfying shot!
//  We can add poolballs now and shoot them as well, but our game doesn't look like pool yet
//  For the next assignment we're going to clean it up and make our game look the part!
// --------------------------------

extension ViewController {
    
    @objc func didTapView(sender: UITapGestureRecognizer) {
        let location = sender.location(in: sender.view)
        if let result = sceneView.hitTest(location, types: .existingPlane).first {
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
