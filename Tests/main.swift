import Foundation
import CoreGraphics
var checks = 0
for (w, h) in [(1920.0, 1080.0), (1080, 1920), (1200, 1200), (3440, 1440)] {
    for scale in [1.0, 2.0] {
        for (aw, ah) in [(9.0, 16.0), (1, 1), (4, 5)] {
            let bounds = CGRect(x: -20, y: 40, width: w / scale, height: h / scale)
            let rect = fittedGuide(in: bounds, aspectWidth: aw, aspectHeight: ah)
            precondition(abs(rect.width / rect.height - aw / ah) < 0.00001)
            precondition(abs(rect.midX - bounds.midX) < 0.00001 && abs(rect.midY - bounds.midY) < 0.00001)
            precondition(rect.width <= bounds.width && rect.height <= bounds.height + 0.00001)
            checks += 1
        }
    }
}
precondition(fittedGuide(in: .zero, aspectWidth: 1, aspectHeight: 1) == .zero)
print("Passed \(checks + 1) crop geometry cases")
