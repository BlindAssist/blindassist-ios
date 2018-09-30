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
    let texts: [Text] = [
      Text(title: "What", text: "An iOS app which will support the blind in traffic"),
      Text(title: "Why", text: "To support blind people on the road"),
      Text(title: "How", text: "Image segmentation to segment camera images in realtime")
    ]

    let pageViews: [PageView] = texts.map({ text in
      let view = PageView()
      view.titleLabel.text = text.title
      view.textLabel.text = text.text
      return view
    })

    return PagerView(views: pageViews)
  }
}

private struct Text {
  let title: String
  let text: String
}
