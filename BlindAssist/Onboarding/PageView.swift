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

  private(set) lazy var imageView: UIImageView = {
    let view = UIImageView()
    view.contentMode = .scaleAspectFit

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

  private(set) lazy var button: UIButton = {
    let button = UIButton(type: .custom)
    button.setTitle("Done", for: .normal)
    button.setTitleColor(.black, for: .normal)

    return button
  }()

  // MARK: - Init

  override init(frame: CGRect) {
    super.init(frame: frame)

    addSubview(backgroundImageView)
    addSubview(imageView)
    addSubview(titleLabel)
    addSubview(textLabel)
    addSubview(button)

    activate(
      backgroundImageView.anchor.edges,
      imageView.anchor.size.equal.to(150),
      imageView.anchor.centerX,
      imageView.anchor.top.equal.to(anchor.top).constant(150),
      titleLabel.anchor.top.equal.to(imageView.anchor.bottom).constant(50),
      titleLabel.anchor.paddingHorizontally(20),
      textLabel.anchor.top.equal.to(titleLabel.anchor.bottom).constant(20),
      textLabel.anchor.paddingHorizontally(20),
      button.anchor.centerX,
      button.anchor.bottom.constant(-40)
    )
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
}

