import UIKit

/// Shared layout constants and helpers for the slide-up presentation.
///
/// These values are the package defaults. Override them per-presentation through
/// a `BottomShelferLayoutConfiguration` set on the `BottomShelferPresentationManager`.
public enum BottomShelferLayout {
    /// Default scrim color: 30%-opaque black.
    public static let defaultDimmingColor: UIColor = UIColor.black.withAlphaComponent(0.3)

    /// Maximum sheet width, capped at iPhone Pro Max logical width.
    public static let maxSheetWidth: CGFloat = 430

    /// Sheet height is never allowed to exceed this fraction of its container.
    public static let maxHeightFraction: CGFloat = 0.9

    /// Height of the draggable grabber area at the top of the sheet.
    public static let grabberHitAreaHeight: CGFloat = 44

    /// Grabber pill geometry.
    public static let grabberPillSize = CGSize(width: 36, height: 5)
    /// Distance from the sheet's top edge to the pill's bottom edge.
    public static let grabberPillBottomOffset: CGFloat = 12
    public static let grabberPillCornerRadius: CGFloat = 2.5

    /// Resolved sheet width given a container, clamped to `maxSheetWidth`.
    @MainActor
    public static func sheetWidth(in containerView: UIView) -> CGFloat {
        min(maxSheetWidth, min(containerView.bounds.width, UIScreen.main.bounds.width))
    }
}

/// All geometric metrics that govern how a slide-up sheet is laid out.
///
/// Every property defaults to the matching value in `BottomShelferLayout`, so a
/// freshly created configuration reproduces the package's built-in appearance.
/// Override only the values you care about and assign it to the manager:
///
/// ```swift
/// var layout = BottomShelferLayoutConfiguration()
/// layout.maxSheetWidth = 500
/// layout.grabberPillSize = CGSize(width: 60, height: 8)
/// manager.layoutConfiguration = layout
/// ```
public struct BottomShelferLayoutConfiguration: Equatable, Sendable {
    /// Maximum sheet width. The sheet never grows wider than this even on iPad.
    public var maxSheetWidth: CGFloat

    /// Sheet height is never allowed to exceed this fraction of its container.
    public var maxHeightFraction: CGFloat

    /// Height of the draggable grabber band at the top of the sheet.
    public var grabberHitAreaHeight: CGFloat

    /// Size of the grabber pill view.
    public var grabberPillSize: CGSize

    /// Distance from the sheet's top edge to the pill's bottom edge.
    public var grabberPillBottomOffset: CGFloat

    /// Corner radius of the grabber pill.
    public var grabberPillCornerRadius: CGFloat

    /// Creates a configuration, defaulting every metric to the package value.
    public init(
        maxSheetWidth: CGFloat = BottomShelferLayout.maxSheetWidth,
        maxHeightFraction: CGFloat = BottomShelferLayout.maxHeightFraction,
        grabberHitAreaHeight: CGFloat = BottomShelferLayout.grabberHitAreaHeight,
        grabberPillSize: CGSize = BottomShelferLayout.grabberPillSize,
        grabberPillBottomOffset: CGFloat = BottomShelferLayout.grabberPillBottomOffset,
        grabberPillCornerRadius: CGFloat = BottomShelferLayout.grabberPillCornerRadius
    ) {
        self.maxSheetWidth = maxSheetWidth
        self.maxHeightFraction = maxHeightFraction
        self.grabberHitAreaHeight = grabberHitAreaHeight
        self.grabberPillSize = grabberPillSize
        self.grabberPillBottomOffset = grabberPillBottomOffset
        self.grabberPillCornerRadius = grabberPillCornerRadius
    }

    /// The package's built-in layout values.
    public static let `default` = BottomShelferLayoutConfiguration()

    /// Resolved sheet width given a container, clamped to `maxSheetWidth`.
    @MainActor
    public func sheetWidth(in containerView: UIView) -> CGFloat {
        min(maxSheetWidth, min(containerView.bounds.width, UIScreen.main.bounds.width))
    }
}
