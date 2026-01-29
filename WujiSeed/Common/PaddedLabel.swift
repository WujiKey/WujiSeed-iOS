//
//  PaddedLabel.swift
//  WujiSeed
//
//  UILabel with padding, used for tag effects
//

import UIKit

/// UILabel with padding, supports setting textInsets to add padding
class PaddedLabel: UILabel {

    var textInsets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8) {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + textInsets.left + textInsets.right,
            height: size.height + textInsets.top + textInsets.bottom
        )
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetRect = bounds.inset(by: textInsets)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        return textRect
    }
}
