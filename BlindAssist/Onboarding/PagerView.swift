//
//  PagerView.swift
//  BlindAssist
//
//  Created by khoa on 30.09.2018.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

import UIKit
import Anchors

/// Show many views in horizonal paging
final class PagerView: UIView {
  private let views: [UIView]
  private let scrollView = UIScrollView()
  private let contentView = UIView()
  private let pageControl = UIPageControl()

  // MARK: - Init

  required init(views: [UIView]) {
    self.views = views
    super.init(frame: .zero)

    setup()
    setupConstraints()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Logic

  func goToPage(index: Int) {
    let offset = CGPoint(
      x: scrollView.frame.size.width * CGFloat(index),
      y: 0
    )
    scrollView.setContentOffset(offset, animated: true)
  }

  // MARK: - Setup

  private func setup() {
    addSubview(scrollView)
    addSubview(pageControl)
    scrollView.addSubview(contentView)
    views.forEach {
      contentView.addSubview($0)
    }

    scrollView.isPagingEnabled = true
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.delegate = self

    pageControl.currentPageIndicatorTintColor = UIColor.green
    pageControl.pageIndicatorTintColor = .gray
    pageControl.numberOfPages = views.count
    pageControl.isHidden = views.count < 2
  }

  private func setupConstraints() {
    activate(
      scrollView.anchor.edges,
      contentView.anchor.edges,
      pageControl.anchor.centerX,
      pageControl.anchor.bottom.constant(-20)
    )

    views.enumerated().forEach { tuple in
      let view = tuple.element

      activate(
        view.anchor.top.bottom.width.height.equal.to(scrollView.anchor)
      )

      if tuple.offset == 0 {
        activate(
          view.anchor.left
        )
      } else {
        activate(
          view.anchor.left.equal.to(views[tuple.offset-1].anchor.right)
        )
      }

      if tuple.offset == views.count - 1 {
        activate(
          view.anchor.right
        )
      }
    }
  }
}

extension PagerView: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    pageControl.currentPage = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
  }
}

