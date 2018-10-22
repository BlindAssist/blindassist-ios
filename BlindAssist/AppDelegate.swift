//
//  AppDelegate.swift
//  BlindAssist
//
//  Created by Giovanni Terlingen on 21/10/2018.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Override point for customization after application launch.
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let controller = OnboardingViewController()
        window!.rootViewController = controller
        window!.makeKeyAndVisible()
        
        controller.onDone = {
            self.switchToMain()
        }
        
        return true
    }
    
    func switchToMain() {
        window!.rootViewController = ViewController()
    }
}
