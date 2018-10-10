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

    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "ViewController")

    addChild(viewController)
    view.addSubview(viewController.view)
    viewController.didMove(toParent: self)
  }
}
