//
//  MainController.swift
//  BlindAssist
//
//  Created by khoa on 10.10.2018.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

import UIKit
import Anchors
import AVFoundation
import Vision
import CoreML
import CoreMotion

final class InferenceViewController: UIViewController {
    
    private lazy var cameraPreview = CameraPreviewView()
    private lazy var predictionView = UIImageView()
    private var session: AVCaptureSession?
    private var motionManager: CMMotionManager?
    private var isFacingHorzion: Bool = false
    private var tts: AVSpeechSynthesizer = AVSpeechSynthesizer()
    private var request: VNCoreMLRequest?
    private var lastPredictionTime: Double = 0
    
    private let GravityCheckInterval: TimeInterval = 1.0
    private let PredictionInterval: TimeInterval = 3.0
    
    required init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupConstraints()
    }
    
    private func setup() {
        view.backgroundColor = .white
        predictionView.contentMode = .scaleToFill
        
        speak("Initializing application")
        
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = TimeInterval(GravityCheckInterval)
        
        if let queue = OperationQueue.current {
            motionManager!.startDeviceMotionUpdates(to: queue, withHandler: { motionData, error in
                self.handleGravity(motionData!.gravity)
            })
        }
        
        do {
            let model = try VNCoreMLModel(for: cityscapes().model)
            request = VNCoreMLRequest(model: model, completionHandler: self.handlePrediction)
            request!.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop
        } catch {
            fatalError("Can't load BlindAssist CoreML model: \(error)")
        }
        
        speak("Finished loading, detecting environment")
    }
    
    private func setupConstraints() {
        view.addSubview(cameraPreview)
        view.addSubview(predictionView)
        
        activate(
            cameraPreview.anchor.left.top.right,
            cameraPreview.anchor.width,
            cameraPreview.anchor.height.ratio(1.0),
            predictionView.anchor.edges.equal.to(cameraPreview.anchor)
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AVCaptureDevice.requestAccess(for: .video) { granted in
            self.permissions(granted)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        session?.stopRunning()
    }
    
    private func permissions(_ granted: Bool) {
        if granted && session == nil {
            setupSession()
        }
    }
    
    private func setupSession() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) else {
            fatalError("Camera not available")
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            fatalError("Camera data not available")
        }
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
        
        let session = AVCaptureSession()
        session.addInput(input)
        session.addOutput(output)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        DispatchQueue.main.async(execute: {
            self.cameraPreview.addCaptureVideoPreviewLayer(previewLayer)
        })
        
        self.session = session
        session.startRunning()
    }
    
    private func deviceOrientationDidChange() {
        session?.outputs.forEach {
            $0.connections.forEach {
                $0.videoOrientation = UIDevice.current.videoOrientation
            }
        }
    }
    
    private func handlePrediction(request: VNRequest, error: Error?) {
        if (!isFacingHorzion) {
            return
        }
        
        var information = scene_information()
        let result = Inference.handlePrediction(request, self.predictionView, &information)
        if (result != SUCCESS) {
            return
        }
        
        let currentTime = Date().timeIntervalSince1970

        if (lastPredictionTime == 0 || (currentTime - lastPredictionTime) > PredictionInterval) {
            if information.poles_detected > 0 {
                speak("Poles detected.")
            }
            if information.vehicle_detected > 0 {
                speak("Parked car detected.")
            }
            if information.bikes_detected > 0 {
                speak("Bikes detected.")
            }
            if information.walk_position == FRONT {
                speak("You can walk in front of you.")
            } else if information.walk_position == LEFT {
                speak("You can walk left.")
            } else if information.walk_position == RIGHT {
                speak("You can walk right.")
            }
            lastPredictionTime = Date().timeIntervalSince1970
        }
    }
    
    func speak(_ string: String?) {
        let utterance = AVSpeechUtterance(string: string ?? "")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceMaximumSpeechRate * 0.60
        tts.speak(utterance)
    }
    
    func handleGravity(_ gravity: CMAcceleration) {
        isFacingHorzion = gravity.y <= -0.97 && gravity.y <= 1.0
        if (!isFacingHorzion) {
            // TODO: Make some beep for this
            speak("Warning: camera is not facing the horizon.")
        }
    }
}

extension InferenceViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        deviceOrientationDidChange()
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var requestOptions: [VNImageOption: Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: requestOptions)
        do {
            try handler.perform([request!])
        } catch {
            fatalError("Error while requesting predicition")
        }
    }
}
