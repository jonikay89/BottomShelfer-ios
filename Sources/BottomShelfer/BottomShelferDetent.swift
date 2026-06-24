import UIKit

/// A discrete height that a slide-up sheet can snap to.
///
/// Modeled after `UISheetPresentationController.Detent`, but available
/// pre-iOS 15 and fully customizable (any height, not just system detents).
/// Snap math is handled by `BottomShelferPresentationController`.
public struct BottomShelferDetent: Hashable {
    /// Height, in points, the sheet occupies when snapped to this detent.
    public let height: CGFloat

    /// Creates a detent for an explicit height, in points.
    public init(height: CGFloat) {
        self.height = height
    }

    /// ~25% of the screen height.
    @MainActor
    public static func small() -> BottomShelferDetent {
        BottomShelferDetent(height: UIScreen.main.bounds.height * 0.25)
    }

    /// ~50% of the screen height.
    @MainActor
    public static func medium() -> BottomShelferDetent {
        BottomShelferDetent(height: UIScreen.main.bounds.height * 0.5)
    }

    /// ~90% of the screen height.
    @MainActor
    public static func large() -> BottomShelferDetent {
        BottomShelferDetent(height: UIScreen.main.bounds.height * 0.9)
    }

    /// A detent with an explicit height.
    public static func custom(height: CGFloat) -> BottomShelferDetent {
        BottomShelferDetent(height: height)
    }

    /// Builds three snap points from a single content height.
    ///
    /// - small:  `contentHeight * 0.4`, clamped to at least 200pt.
    /// - medium: `contentHeight` (the content's intrinsic size).
    /// - large:  `contentHeight * 1.5`, clamped to 90% of the screen.
    ///
    /// Returned in ascending height order so `selectedDetentIndex` keeps a
    /// stable meaning (0 = smallest, last = largest). Pick the initial index
    /// on the manager to choose where the sheet opens.
    @MainActor
    public static func detents(forContentHeight height: CGFloat) -> [BottomShelferDetent] {
        let screenHeight = UIScreen.main.bounds.height
        return [
            .custom(height: min(max(height * 0.4, 200), screenHeight * 0.9)),
            .custom(height: min(height, screenHeight * 0.9)),
            .custom(height: min(height * 1.5, screenHeight * 0.9)),
        ]
    }
}
