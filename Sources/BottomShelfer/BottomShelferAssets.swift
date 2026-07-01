import UIKit

/// Access to the images bundled with the `BottomShelfer` framework.
public enum BottomShelferAssets {

    /// The `BottomShelfer` logo image, loaded from the framework's asset
    /// catalog. Returns `nil` if the image cannot be resolved at runtime.
    @MainActor
    public static var logo: UIImage? {
        UIImage(named: "BottomShelfer", in: .module, with: nil)
    }
}
