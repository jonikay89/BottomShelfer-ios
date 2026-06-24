import UIKit

// MARK: - UIGestureRecognizerDelegate

extension BottomShelferPresentationController: UIGestureRecognizerDelegate {

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pv = presentedView else { return false }
        let point = gestureRecognizer.location(in: pv)

        // Grabber pan only activates inside the 44pt grabber band.
        if gestureRecognizer === grabberPanGesture {
            return point.y < layoutConfiguration.grabberHitAreaHeight
        }

        // Content pan never activates inside the grabber band.
        if gestureRecognizer === contentPanGesture {
            if point.y < layoutConfiguration.grabberHitAreaHeight { return false }

            // Only take over for downward pans (the dismiss / shrink direction).
            if let pan = gestureRecognizer as? UIPanGestureRecognizer {
                guard pan.velocity(in: pv).y > 0 else { return false }
            }

            if let sv = findScrollView(at: point, in: pv) {
                return isScrollViewAtTop(sv)
            }

            // Yield to other drags (e.g. a color picker with its own pan
            // handling) unless explicitly told to grab non-scroll views.
            if !allowGrabbingNonScrollViews,
               hasNonScrollPanGesture(at: point, in: pv) {
                return false
            }

            return true
        }

        return true
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if gestureRecognizer === grabberPanGesture { return false }
        if gestureRecognizer === contentPanGesture,
           otherGestureRecognizer is UIPanGestureRecognizer {
            return otherGestureRecognizer.view is UIScrollView
        }
        return false
    }

    /// Walks from the hit view up to `view`, returning `true` if any ancestor
    /// (that isn't a scroll view) owns a pan gesture other than our two.
    func hasNonScrollPanGesture(at point: CGPoint, in view: UIView) -> Bool {
        guard let hitView = view.hitTest(point, with: nil) else { return false }
        var current: UIView? = hitView
        while let v = current {
            for gr in v.gestureRecognizers ?? [] {
                if let pan = gr as? UIPanGestureRecognizer,
                   pan !== contentPanGesture,
                   pan !== grabberPanGesture,
                   !(v is UIScrollView) {
                    return true
                }
            }
            if v === view { break }
            current = v.superview
        }
        return false
    }
}
