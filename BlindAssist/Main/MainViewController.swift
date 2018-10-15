//
//  MainController.swift
//  BlindAssist
//
//  Created by khoa on 10.10.2018.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

import UIKit
import Anchors

final class MainViewController: UIViewController {

  private lazy var cameraPreview = CameraPreviewView()
  private lazy var predictionView = UIImageView()

  // MARK: - Init

  required init() {
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  // MARK: - Life cycle

  override func viewDidLoad() {
    super.viewDidLoad()

    setup()
    setupConstraints()
  }

  // MARK: - Setup

  private func setup() {

  }

  private func setupConstraints() {
    view.addSubview(cameraPreview)
    view.addSubview(predictionView)
  }
}
