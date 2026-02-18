//
//  UIUtils.swift
//  WujiSeed
//
//  UIKit-specific utility extensions
//

import UIKit

extension String {
    /// Convert emoji string to UIImage
    /// - Parameter size: Target image size
    /// - Returns: UIImage rendered from emoji
    func emojiToImage(size: CGSize) -> UIImage? {
        let nsString = (self as NSString)
        let font = UIFont.systemFont(ofSize: min(size.width, size.height))
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = nsString.size(withAttributes: attributes)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let origin = CGPoint(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2
        )
        nsString.draw(at: origin, withAttributes: attributes)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}
