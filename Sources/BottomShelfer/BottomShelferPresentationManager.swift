import UIKit

/// Configuration + delegate for slide-up presentations.
///
/// Hold one instance per presenting flow and assign it as the presented view
/// controller's `transitioningDelegate` – typically via
/// `BottomShelferPresentable.presentAsBottomShelfer(from:)`. All configuration is copied
/// into the freshly created `BottomShelferPresentationController` on each present,
/// so later mutations only affect subsequent presentations.
@MainActor
public final class BottomShelferPresentationManager: NSObject, UIViewControllerTransitioningDelegate {
    /// Snap points, in any order. Index `selectedDetentIndex` of this array
    /// is the detent used on present; the controller sorts the rest for snap
    /// resolution.
    public var detents: [BottomShelferDetent] = [.large()]

    /// Index into `detents` selected when the sheet appears.
    public var selectedDetentIndex: Int = 0

    public var cornerRadius: CGFloat = 20
    public var isDimmingViewEnabled: Bool = true
    public var isDraggingEnabled: Bool = true
    public var allowGrabbingNonScrollViews: Bool = false

    /// Color of the scrim behind the sheet.
    public var dimmingColor: UIColor = BottomShelferLayout.defaultDimmingColor

    /// Geometric layout metrics (sheet width/height caps, grabber geometry).
    /// Override the defaults to restyle the sheet for your app.
    public var layoutConfiguration: BottomShelferLayoutConfiguration = .default

    /// Height of the currently selected detent, clamped to the array bounds.
    public var currentDetentHeight: CGFloat {
        guard !detents.isEmpty else { return UIScreen.main.bounds.height * layoutConfiguration.maxHeightFraction }
        return detents[min(selectedDetentIndex, detents.count - 1)].height
    }

    public override init() {
        super.init()
    }

    public func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let pc = BottomShelferPresentationController(presentedViewController: presented, presenting: presenting)
        pc.detents = detents
        pc.selectedDetentIndex = selectedDetentIndex
        pc.cornerRadius = cornerRadius
        pc.isDimmingViewEnabled = isDimmingViewEnabled
        pc.isDraggingEnabled = isDraggingEnabled
        pc.allowGrabbingNonScrollViews = allowGrabbingNonScrollViews
        pc.dimmingColor = dimmingColor
        pc.layoutConfiguration = layoutConfiguration
        return pc
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        BottomShelferPresentationAnimator(isPresenting: true, layoutConfiguration: layoutConfiguration)
    }

    public func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        BottomShelferPresentationAnimator(isPresenting: false, layoutConfiguration: layoutConfiguration)
    }
}
