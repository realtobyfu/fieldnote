import SwiftUI
import UIKit

/// Loads the bulk illustration & photo imagery that ships as loose HEIC files in
/// the app bundle rather than inside `Assets.xcassets`.
///
/// Why loose files: `actool` decompresses every asset-catalog image and re-stores
/// it with a near-lossless codec, so ~55 MB of HEIC sources compiled to a ~299 MB
/// `Assets.car` (the whole app was ~305 MB on the App Store). Shipping the same
/// HEIC files as plain bundle resources copies them byte-for-byte, keeping the
/// binary roughly 5× smaller. Each file is named `<assetName>.heic` so existing
/// asset-name call sites migrate with a one-line change.
///
/// Anything still living in the asset catalog (app icon, distribution maps, etc.)
/// is reached through the `UIImage(named:)` / `Image(_:)` fallbacks.
enum BundledImagery {
    /// Asset catalogs kept decoded images warm for us; loose files don't, so we
    /// hold a small purgeable cache to avoid re-reading HEIC on every access.
    private static let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 60
        return c
    }()

    /// Loads a bundled HEIC by asset name, falling back to the asset catalog.
    static func uiImage(named name: String) -> UIImage? {
        let key = name as NSString
        if let cached = cache.object(forKey: key) { return cached }
        if let url = Bundle.main.url(forResource: name, withExtension: "heic"),
           let image = UIImage(contentsOfFile: url.path) {
            cache.setObject(image, forKey: key)
            return image
        }
        return UIImage(named: name)
    }

    /// SwiftUI `Image` for a bundled asset name. Chainable with `.resizable()` just
    /// like `Image(name)` was. Falls back to an asset-catalog lookup if the file is
    /// missing, so callers still get the catalog's own placeholder behavior.
    static func image(_ name: String) -> Image {
        if let ui = uiImage(named: name) { return Image(uiImage: ui) }
        return Image(name)
    }
}
