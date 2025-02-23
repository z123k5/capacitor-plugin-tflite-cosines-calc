import Foundation

@objc public class GalleryEngine: NSObject {
    @objc public func echo(_ value: String) -> String {
        print(value)
        return value
    }
}
