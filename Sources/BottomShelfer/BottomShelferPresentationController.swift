import UIKit

/// Invisible hit-test view that lets touches pass through itself but still
/// drive its own gesture recognizer – used for the grabber area so the rest
/// of the 44pt band stays tappable by the content beneath.
private final class GrabberHitAreaView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view === self ? nil : view
    }
}

/// A custom `UIPresentationController` that renders the presented view as a
/// bottom-anchored sheet with multiple height detents, a draggable grabber,
/// and an optional dimming scrim.
public class BottomShelferPresentationController: UIPresentationController {

    // MARK: Views

    private let dimmingView: UIView = {
        let v = UIView()
        v.backgroundColor = BottomShelferLayout.defaultDimmingColor
        v.alpha = 0
        return v
    }()

    private let grabberPill: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: 0.15)
        v.layer.cornerRadius = BottomShelferLayout.grabberPillCornerRadius
        v.alpha = 0
        return v
    }()

    private let grabberHitArea: GrabberHitAreaView = {
        let v = GrabberHitAreaView()
        v.backgroundColor = .clear
        return v
    }()

    // MARK: Config

    var detents: [BottomShelferDetent] = [.large()] {
        didSet { rebuildSnapPoints() }
    }
    var selectedDetentIndex: Int = 0
    var cornerRadius: CGFloat = 20
    var isDimmingViewEnabled: Bool = true
    var isDraggingEnabled: Bool = true
    var allowGrabbingNonScrollViews: Bool = false

    /// Geometric layout metrics for this presentation. Copied from the
    /// `BottomShelferPresentationManager` before the sheet appears.
    var layoutConfiguration: BottomShelferLayoutConfiguration = .default

    /// Color of the scrim behind the sheet.
    var dimmingColor: UIColor = BottomShelferLayout.defaultDimmingColor {
        didSet { dimmingView.backgroundColor = dimmingColor }
    }

    // MARK: State

    /// `snapYPositions[i]` is the `y` origin for the detent at index `i`.
    /// Both arrays are sorted smallest height -> largest height.
    private var snapYPositions: [CGFloat] = []
    private var snapHeights: [CGFloat] = []

    private var dragStartY: CGFloat = 0
    private var isUserDragging = false
    private var trackedScrollView: UIScrollView?
    private var scrollViewBouncesCache = false

    private var containerHeight: CGFloat {
        containerView?.bounds.height ?? UIScreen.main.bounds.height
    }

    private var currentDetentHeight: CGFloat {
        guard !detents.isEmpty else { return containerHeight * layoutConfiguration.maxHeightFraction }
        return detents[min(selectedDetentIndex, detents.count - 1)].height
    }

    // MARK: Gestures

    /// Lazily created so the gesture's target is bound to a fully initialized
    /// controller. Marked `internal` because the gesture-delegate extension
    /// lives in a separate file.
    lazy var grabberPanGesture: UIPanGestureRecognizer = {
        let g = UIPanGestureRecognizer(target: self, action: #selector(handleGrabberPan(_:)))
        g.delegate = self
        return g
    }()

    lazy var contentPanGesture: UIPanGestureRecognizer = {
        let g = UIPanGestureRecognizer(target: self, action: #selector(handleGrabberPan(_:)))
        g.delegate = self
        return g
    }()

    // MARK: Init

    public override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    // MARK: Snap-point math

    private func rebuildSnapPoints() {
        let ch = containerHeight
        let maxH = ch * layoutConfiguration.maxHeightFraction
        let sorted = detents.sorted { $0.height < $1.height }
        snapHeights = sorted.map { min($0.height, maxH) }
        snapYPositions = snapHeights.map { ch - $0 }
    }

    private func snapIndexClosest(to y: CGFloat) -> Int {
        guard !snapYPositions.isEmpty else { return 0 }
        var best = 0
        var bestDist = abs(snapYPositions[0] - y)
        for i in 1..<snapYPositions.count {
            let d = abs(snapYPositions[i] - y)
            if d < bestDist { bestDist = d; best = i }
        }
        return best
    }

    private func detentIndex(forHeight height: CGFloat) -> Int {
        detents.firstIndex { abs($0.height - height) < 1 } ?? 0
    }

    // MARK: Scroll-view discovery

    func findScrollView(at point: CGPoint, in view: UIView) -> UIScrollView? {
        if let sv = view as? UIScrollView,
           sv.bounds.contains(sv.convert(point, from: presentedView)) {
            return sv
        }
        for sub in view.subviews {
            if let found = findScrollView(at: point, in: sub) { return found }
        }
        return nil
    }

    func isScrollViewAtTop(_ sv: UIScrollView) -> Bool {
        sv.contentOffset.y <= sv.adjustedContentInset.top
    }

    // MARK: Pan handling

    @objc private func handleGrabberPan(_ gesture: UIPanGestureRecognizer) {
        guard let presentedView = presentedView else { return }
        let velocity = gesture.velocity(in: presentedView.superview)

        switch gesture.state {
        case .began:
            dragStartY = presentedView.frame.origin.y
            isUserDragging = true
            let point = gesture.location(in: presentedView)
            trackedScrollView = findScrollView(at: point, in: presentedView)
            if let sv = trackedScrollView {
                scrollViewBouncesCache = sv.bounces
                sv.bounces = false
            }

        case .changed:
            // For content pans over a scroll view, hand control to the sheet
            // only once the scroll view is pinned to the top; otherwise let it
            // scroll normally and keep its offset locked at the top.
            if gesture !== grabberPanGesture, let sv = trackedScrollView {
                guard isScrollViewAtTop(sv) else { return }
                sv.contentOffset.y = sv.adjustedContentInset.top
            }

            var newY = dragStartY + gesture.translation(in: presentedView.superview).y
            let topY = snapYPositions.last ?? 0
            let ch = containerHeight
            newY = max(topY, min(newY, ch))
            let newHeight = ch - newY
            presentedView.frame = CGRect(
                x: presentedView.frame.origin.x,
                y: newY,
                width: presentedView.frame.width,
                height: newHeight
            )

        case .ended, .cancelled:
            resolveAndSnap(velocity: velocity)
            if let sv = trackedScrollView {
                sv.bounces = scrollViewBouncesCache
                sv.contentOffset.y = sv.adjustedContentInset.top
            }
            trackedScrollView = nil

        default:
            break
        }
    }

    // MARK: Snap resolution

    private func resolveAndSnap(velocity: CGPoint) {
        guard let presentedView = presentedView else { return }
        let currentY = presentedView.frame.origin.y
        let ch = containerHeight

        let startSnapIndex = snapIndexClosest(to: dragStartY)
        let isDraggingDown = velocity.y >= 0
        let isFastSwipe = abs(velocity.y) > 1500

        if isFastSwipe {
            if isDraggingDown {
                let nextIndex = startSnapIndex - 1
                if nextIndex < 0 {
                    dismissAnimated()
                    return
                }
                snapToIndex(nextIndex, velocity: velocity.y)
            } else {
                let prevIndex = min(startSnapIndex + 1, snapYPositions.count - 1)
                snapToIndex(prevIndex, velocity: velocity.y)
            }
            return
        }

        let closestIndex = snapIndexClosest(to: currentY)
        let smallestSnapY = snapYPositions.first ?? ch
        let gapToBottom = ch - smallestSnapY
        let dismissThreshold = smallestSnapY + gapToBottom * 0.4

        if currentY > dismissThreshold {
            dismissAnimated()
            return
        }

        snapToIndex(closestIndex, velocity: velocity.y)
    }

    private func snapToIndex(_ index: Int, velocity: CGFloat = 0) {
        guard let presentedView = presentedView else { return }
        let targetY = snapYPositions[index]
        let targetHeight = snapHeights[index]
        selectedDetentIndex = detentIndex(forHeight: targetHeight)
        let targetFrame = CGRect(
            x: presentedView.frame.origin.x,
            y: targetY,
            width: presentedView.frame.width,
            height: targetHeight
        )

        let springVelocity = abs(velocity) > 0 ? min(abs(velocity) / 2000, 2.0) : 0

        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: springVelocity,
            options: .curveEaseInOut
        ) {
            presentedView.frame = targetFrame
        } completion: { [weak self] _ in
            self?.finalizeSnap(to: targetFrame.size)
        }
    }

    /// Programmatic snap to an explicit height (e.g. driven by a button).
    public func snapToHeight(_ targetHeight: CGFloat) {
        guard let presentedView = presentedView else { return }

        let targetFrame = CGRect(
            x: presentedView.frame.origin.x,
            y: containerHeight - targetHeight,
            width: presentedView.frame.width,
            height: targetHeight
        )

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: .curveEaseInOut
        ) {
            presentedView.frame = targetFrame
        } completion: { [weak self] _ in
            self?.finalizeSnap(to: targetFrame.size)
        }
    }

    /// Shared completion for snap animations: publish the new preferred size,
    /// clear the drag flag, and ensure the scrim is fully visible.
    private func finalizeSnap(to size: CGSize) {
        presentedViewController.preferredContentSize = size
        isUserDragging = false
        UIView.animate(withDuration: 0.2) {
            self.dimmingView.alpha = 1.0
        }
    }

    private func dismissAnimated() {
        isUserDragging = false
        presentedViewController.dismiss(animated: true)
    }

    // MARK: Tap-to-dismiss

    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        let presentable = presentedViewController as? BottomShelferPresentable

        if presentable?.dismissOnHide == true {
            presentedViewController.dismiss(animated: true)
        } else if presentedViewController.view.bottomShelfer_firstResponder != nil {
            // Keyboard is up – close it first; a second tap will dismiss.
            presentedViewController.view.endEditing(true)
        } else {
            presentedViewController.dismiss(animated: true)
        }
    }

    // MARK: Presentation lifecycle

    public override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }

        rebuildSnapPoints()

        dimmingView.frame = containerView.bounds
        dimmingView.backgroundColor = dimmingColor
        dimmingView.alpha = 0
        if !containerView.subviews.contains(dimmingView) {
            containerView.addSubview(dimmingView)
        }
        if isDimmingViewEnabled {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            dimmingView.addGestureRecognizer(tap)
        }

        let targetAlpha: CGFloat = isDimmingViewEnabled ? 1.0 : 0
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = targetAlpha
            })
        } else {
            dimmingView.alpha = targetAlpha
        }

        stylePresentedView()
        installGrabber()
        enableGestures(isDraggingEnabled)
    }

    public override func dismissalTransitionWillBegin() {
        guard isDimmingViewEnabled else { return }
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 0
            })
        } else {
            dimmingView.alpha = 0
        }
    }

    public override func presentationTransitionDidEnd(_ completed: Bool) {
        if completed {
            dragStartY = presentedView?.frame.origin.y ?? 0
        }
    }

    public override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        rebuildSnapPoints()
        guard !isUserDragging else { return }
        // Preserve the current selection across rotations / layout passes
        // rather than forcing it back to the smallest detent.
        selectedDetentIndex = min(selectedDetentIndex, max(detents.count - 1, 0))
        presentedView?.frame = frameOfPresentedViewInContainerView
        presentedViewController.preferredContentSize = frameOfPresentedViewInContainerView.size
    }

    public override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        if isDimmingViewEnabled {
            dimmingView.frame = containerView?.bounds ?? .zero
        }
    }

    public override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        let maxHeight = containerHeight * layoutConfiguration.maxHeightFraction
        let height = min(currentDetentHeight, maxHeight)
        let width = layoutConfiguration.sheetWidth(in: containerView)
        let x = (containerView.bounds.width - width) / 2.0
        return CGRect(x: x, y: containerView.bounds.height - height, width: width, height: height)
    }

    // MARK: View setup helpers

    private func stylePresentedView() {
        guard let presentedView = presentedView else { return }
        presentedView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        presentedView.layer.cornerRadius = cornerRadius
        presentedView.clipsToBounds = true
    }

    private func installGrabber() {
        guard let presentedView = presentedView else { return }

        grabberHitArea.translatesAutoresizingMaskIntoConstraints = false
        grabberPill.translatesAutoresizingMaskIntoConstraints = false
        if grabberPill.superview !== grabberHitArea {
            grabberHitArea.addSubview(grabberPill)
        }
        if grabberHitArea.superview !== presentedView {
            presentedView.addSubview(grabberHitArea)
        }

        let pillSize = layoutConfiguration.grabberPillSize
        grabberPill.layer.cornerRadius = layoutConfiguration.grabberPillCornerRadius
        NSLayoutConstraint.activate([
            grabberHitArea.topAnchor.constraint(equalTo: presentedView.topAnchor),
            grabberHitArea.leadingAnchor.constraint(equalTo: presentedView.leadingAnchor),
            grabberHitArea.trailingAnchor.constraint(equalTo: presentedView.trailingAnchor),
            grabberHitArea.heightAnchor.constraint(equalToConstant: layoutConfiguration.grabberHitAreaHeight),

            grabberPill.centerXAnchor.constraint(equalTo: grabberHitArea.centerXAnchor),
            grabberPill.bottomAnchor.constraint(
                equalTo: grabberHitArea.topAnchor,
                constant: layoutConfiguration.grabberPillBottomOffset
            ),
            grabberPill.widthAnchor.constraint(equalToConstant: pillSize.width),
            grabberPill.heightAnchor.constraint(equalToConstant: pillSize.height),
        ])

        presentedView.addGestureRecognizer(grabberPanGesture)
        presentedView.addGestureRecognizer(contentPanGesture)
    }

    private func enableGestures(_ enabled: Bool) {
        grabberHitArea.isUserInteractionEnabled = enabled
        grabberPanGesture.isEnabled = enabled
        contentPanGesture.isEnabled = enabled
    }
}
