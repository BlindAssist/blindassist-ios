//
//  CameraPreviewView.swift
//  BlindAssist
//
//  Created by Giovanni Terlingen on 22/10/2018.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

// Uses code from https://github.com/vfa-tranhv/MobileAILab-HairColor-iOS

import UIKit
import AVFoundation

final class CameraPreviewView: UIView {
    
    private weak var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Observe device rotation
        let selector = #selector(deviceOrientationDidChange(_:))
        UIDevice.subscribeToDeviceOrientationNotifications(self, selector: selector)
    }
    
    // Insert layer at index 0
    func addCaptureVideoPreviewLayer(_ previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer?.removeFromSuperlayer()
        self.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
        self.previewLayer?.videoGravity = .resizeAspectFill
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    // Change video orientation to always display video in correct orientation
    @objc private func deviceOrientationDidChange(_ notification: Notification) {
        previewLayer?.connection?.videoOrientation = UIDevice.current.videoOrientation
    }
}
