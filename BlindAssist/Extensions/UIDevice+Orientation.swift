//
//  UIDevice+Orientation.swift
//  BlindAssist
//
//  Created by Giovanni Terlingen on 22/10/2018.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

// Uses code from https://github.com/vfa-tranhv/MobileAILab-HairColor-iOS

import UIKit
import AVFoundation

extension UIDevice {
    
    // Video orientation for current device orientation
    var videoOrientation: AVCaptureVideoOrientation {
        let orientation: AVCaptureVideoOrientation
        
        switch self.orientation {
        case .portrait:
            orientation = .portrait
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        case .landscapeLeft:
            orientation = .landscapeLeft
        case .landscapeRight:
            orientation = .landscapeRight
        default:
            orientation = .portrait
        }
        
        return orientation
    }
    
    // Subscribes target to default NotificationCenter .UIDeviceOrientationDidChange
    class func subscribeToDeviceOrientationNotifications(_ target: AnyObject, selector: Selector) {
        let center = NotificationCenter.default
        let name = UIDevice.orientationDidChangeNotification
        let selector = selector
        center.addObserver(target, selector: selector, name: name, object: nil)
    }
}
