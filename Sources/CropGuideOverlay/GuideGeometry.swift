import Foundation
import CoreGraphics

/// Largest centered rectangle of the requested aspect that fits in the display.
func fittedGuide(in bounds: CGRect, aspectWidth: CGFloat, aspectHeight: CGFloat) -> CGRect {
    guard aspectWidth > 0, aspectHeight > 0, bounds.width > 0, bounds.height > 0 else { return .zero }
    let width = min(bounds.width, bounds.height * aspectWidth / aspectHeight)
    let height = width * aspectHeight / aspectWidth
    return CGRect(x: bounds.midX - width / 2, y: bounds.midY - height / 2, width: width, height: height)
}
