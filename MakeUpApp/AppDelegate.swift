//
//  AppDelegate.swift
//  MakeUpApp
//
//  Created by kashee kushwaha on 01/06/20.
//  Copyright © 2020 kashee kushwaha. All rights reserved.
//

import UIKit
import ARKit
import Firebase

var useFallbackImplementation: Bool {
    return !ARFaceTrackingConfiguration.isSupported
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if targetEnvironment(simulator)
        #error("iOS Simulator doesn't have a camera. Connect a physical iOS device and select it as your Xcode run destination, or select Generic iOS Device as a build-only destination.")
        #endif
        if useFallbackImplementation {
            FirebaseApp.configure()
            let storyboard = UIStoryboard(name: "Main", bundle: .main)
            window?.rootViewController = storyboard.instantiateViewController(withIdentifier: "mlvision")
        }
        return true
    }
    
}
