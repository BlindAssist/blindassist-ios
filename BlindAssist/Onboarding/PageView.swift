//
//  PageView.swift
//  BlindAssist
//
//  Created by khoa on 30.09.2018.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

import UIKit
import Anchors

final class PageView: UIView {
  private(set) lazy var backgroundImageView: UIImageView = {
    let view = UIImageView()
    view.contentMode = .scaleAspectFill
    view.clipsToBounds = true

    return view
  }()

  private(set) lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.textColor = UIColor.black
    label.numberOfLines = 0
    label.font = UIFont.preferredFont(forTextStyle: .headline)

    return label
  }()

  private(set) lazy var textLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.textColor = UIColor.black
    label.numberOfLines = 0
    label.font = UIFont.preferredFont(forTextStyle: .title3)

    return label
  }()

  // MARK: - Init

  override init(frame: CGRect) {
    super.init(frame: frame)

    addSubview(backgroundImageView)
    addSubview(titleLabel)
    addSubview(textLabel)

    activate(
      backgroundImageView.anchor.edges,
      titleLabel.anchor.centerY,
      titleLabel.anchor.paddingHorizontally(20),
      textLabel.anchor.top.equal.to(titleLabel.anchor.bottom).constant(20),
      textLabel.anchor.paddingHorizontally(20)
    )
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
}

