//
//  ViewController.swift
//  MakeUpApp
//
//  Created by kashee kushwaha on 01/06/20.
//  Copyright © 2020 kashee kushwaha. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, LipstickChooserDelegate {
    // MARK: - Lipstick
    var lipstickColor: UIColor = .black {
        didSet {
            for mask in masks where mask.geometry is ARSCNFaceGeometry {
                mask.geometry?.firstMaterial?.multiply.contents = lipstickColor
            }
        }
    }
    
    func didChooseLipstick(_ lipstick: Lipstick) {
        lipstickColor = lipstick.color
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "segue",
            let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? ColorLipstickTableViewController
            else { return }
        vc.delegate = self
    }
    
    // MARK: - Rendering
    
    var faceAnchors: Set<ARFaceAnchor> = []
    var masks: Set<SCNNode> = []
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return nil }
        faceAnchors.insert(faceAnchor)
        
        let faceGeometry = ARSCNFaceGeometry(device: sceneView.device!)!
        
        let material = faceGeometry.firstMaterial!
        // Shape of lips
        material.diffuse.contents = #imageLiteral(resourceName: "wireframeTexture")
        // Lipstick color
        material.multiply.contents = lipstickColor
        // More realistic
        material.lightingModel = .physicallyBased
        material.transparency = 0.82
        
        let mask = SCNNode(geometry: faceGeometry)
        masks.insert(mask)
        return mask
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        guard faceAnchors.contains(faceAnchor),
            masks.contains(node),
            let faceGeometry = node.geometry as? ARSCNFaceGeometry
            else { fatalError() }
        
        faceGeometry.update(from: faceAnchor.geometry)
        if #available(iOS 12.0, *), faceAnchor.isTongueOut {
            print("No tongue, please")
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        faceAnchors.remove(faceAnchor)
        masks.remove(node)
    }
    
    // MARK: - Setup
    
    @IBOutlet var sceneView: ARSCNView!
    
    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        #if compiler(>=5.1)
        if #available(iOS 13.0, *) {
            configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
        }
        #endif
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
    }
    
    // MARK: - State Changes
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        sceneView.session.pause()
    }
    
    // MARK: - Error Handling
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async { [weak self] in
            self?.displayError(errorMessage, withTitle: NSLocalizedString("The AR session failed.", comment: "Alert title"))
        }
    }
    
    /// Present an alert informing about the error that has occurred.
    private func displayError(_ message: String, withTitle title: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let actionTitle = NSLocalizedString("Restart Session", comment: "Alert action title")
        let restartAction = UIAlertAction(title: actionTitle, style: .default) { [weak self] _ in
            alertController.dismiss(animated: true, completion: nil)
            self?.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Extensions

extension ARFaceAnchor {
    @available(iOS 12.0, *)
    var isTongueOut: Bool {
        return blendShapes[ARFaceAnchor.BlendShapeLocation.tongueOut]!.floatValue > 0.05
    }
}
