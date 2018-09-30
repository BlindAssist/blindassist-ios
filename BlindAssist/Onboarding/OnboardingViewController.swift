//
//  OnboardingViewController.swift
//  BlindAssist
//
//  Created by khoa on 30.09.2018.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

import UIKit
import Anchors

final class OnboardingViewController: UIViewController {
  private lazy var pagerView: PagerView = self.makePagerView()

  // MARK: - Life cycle

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(pagerView)
    activate(
      pagerView.anchor.edges
    )
  }

  // MARK: - Make

  private func makePagerView() -> PagerView {
    let contents: [Content] = [
      Content(title: "What", text: "An iOS app which will support the blind in traffic", image: "smiley"),
      Content(title: "Why", text: "To support blind people on the road", image: "car"),
      Content(title: "How", text: "Image segmentation to segment camera images in realtime", image: "camera")
    ]

    let pageViews: [PageView] = contents.map({ content in
      let view = PageView()
      view.titleLabel.text = content.title
      view.textLabel.text = content.text
      view.imageView.image = UIImage(named: content.image)
      return view
    })

    return PagerView(views: pageViews)
  }
}

private struct Content {
  let title: String
  let text: String
  let image: String
}
