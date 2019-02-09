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

// --------  Assignment 1  --------
//  This project contains the logic to create the planes for your virtual world already!
//  As promised we'll start adding some balls to our poolgame now
//  I've prepared a second SCNNode type, the Sphere!
//  Don't mind the positioning logic, we'll simply use it later
//
//  1. First off we're going to define a let sphere of type SCNSphere
//  Also add a radius of type Float with value 0.025
//  In the init method we're going to set self.sphere to a new SCNSphere with radisu CGFloat(radius)
//  Also set the sphere.materials to an array of SCNNode.material and let's use UIColor.red for now
//  Call super.init followed by setting self.geometry to sphere
//  Define a let called shape and fill it with a SCNPhysicsShape(geometry: sphere and options nil
//  Now set the physicsBody to a new SCNPhysicsBody but user type .dynamic this time and shape: shape
//  Since we want our poolballs to be movable we've selected the dynamic type for this object
//
//  2. Now we've defined what a poolball for our game is, let's start adding them to the table
//  Start in the didTapView method where we'll define a new let called location
//      assign the sender.location(in: sender.view) to our newly defined location
//  Now we need to check if we've actually tapped on something in our virtual world, do it as follows;
//      if let result = sceneView.hitTest(location, types: .existingPlane).first {
//  If the user has indeed tapped on a part of the virtual world we'll enter this block of code
//  Let's define a new let called sphere and fill it with a new Sphere()
//  Set the sphere.position at result.worldTransform, this is the calculated position in our virtual world
//  Since the user taps a plane and we want to place our ball on top of the plane we should
//      add the sphere.radius to our sphere.position.y
//  Lastly, we should add our ball to the scene by calling sceneView.scene.rootNode.addChildNode(sphere)
//
//
//
//  Run the app and observe that if you tap on any of our green planes you'll add a red pool ball
//  Since we've made our sphere shape a dynamic one they will automatically start moving if you place them
//      on top or against each other
//  Don't mind all the lines coming out of the balls, that's debug information for positioning elements
//  We're missing quite a key component though, shooting the pool ball!
//  We'll look into that for assignment 2
// --------------------------------

class Sphere: SCNNode {
    
    override init() {
        super.init()
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
