//
//  ViewControllerExtension.swift
//  BlindAssist
//
//  Created by Giovanni Terlingen on 22/10/2018.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

import UIKit
import Anchors

@objc class ViewControllerExtension: NSObject {
    
    @objc class func setup(view: UIView, cameraPreviewView: CameraPreviewView, predictionView: UIImageView) {
        view.backgroundColor = .white
        predictionView.contentMode = .scaleToFill
        
        view.addSubview(cameraPreviewView)
        view.addSubview(predictionView)
        
        activate(
            cameraPreviewView.anchor.left.top.right,
            cameraPreviewView.anchor.width,
            cameraPreviewView.anchor.height.ratio(1.0),
            predictionView.anchor.edges.equal.to(cameraPreviewView.anchor)
        )
    }
}
