import UIKit

/// Shared layout constants and helpers for the slide-up presentation.
enum BottomShelferLayout {
    /// Default scrim color: 30%-opaque black.
    static let defaultDimmingColor: UIColor = UIColor.black.withAlphaComponent(0.3)

    /// Maximum sheet width, capped at iPhone Pro Max logical width.
    static let maxSheetWidth: CGFloat = 430

    /// Sheet height is never allowed to exceed this fraction of its container.
    static let maxHeightFraction: CGFloat = 0.9

    /// Height of the draggable grabber area at the top of the sheet.
    static let grabberHitAreaHeight: CGFloat = 44

    /// Grabber pill geometry.
    static let grabberPillSize = CGSize(width: 36, height: 5)
    /// Distance from the sheet's top edge to the pill's bottom edge.
    static let grabberPillBottomOffset: CGFloat = 12
    static let grabberPillCornerRadius: CGFloat = 2.5

    /// Resolved sheet width given a container, clamped to `maxSheetWidth`.
    static func sheetWidth(in containerView: UIView) -> CGFloat {
        min(maxSheetWidth, min(containerView.bounds.width, UIScreen.main.bounds.width))
    }
}
