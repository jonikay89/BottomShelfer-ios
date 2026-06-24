import UIKit

/// Drives the slide-up / slide-down transition for `BottomShelferPresentationManager`.
///
/// A fresh instance is returned from the manager for each present/dismiss, so
/// the animator itself is stateless apart from its `isPresenting` flag.
@MainActor
public final class BottomShelferPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    let isPresenting: Bool
    let layoutConfiguration: BottomShelferLayoutConfiguration

    init(isPresenting: Bool, layoutConfiguration: BottomShelferLayoutConfiguration = .default) {
        self.isPresenting = isPresenting
        self.layoutConfiguration = layoutConfiguration
        super.init()
    }

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.3
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            present(using: transitionContext)
        } else {
            dismiss(using: transitionContext)
        }
    }

    // MARK: Present

    private func present(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        guard let toView = transitionContext.view(forKey: .to) else {
            // Always complete the transition, even on failure, so UIKit can
            // tear down the transition context.
            transitionContext.completeTransition(false)
            return
        }

        let targetFrame: CGRect
        if let pc = transitionContext.viewController(forKey: .to)?.presentationController as? BottomShelferPresentationController {
            targetFrame = pc.frameOfPresentedViewInContainerView
        } else {
            let width = layoutConfiguration.sheetWidth(in: containerView)
            targetFrame = CGRect(
                x: (containerView.bounds.width - width) / 2.0,
                y: containerView.bounds.height,
                width: width,
                height: containerView.bounds.height * layoutConfiguration.maxHeightFraction
            )
        }

        toView.frame = CGRect(
            x: targetFrame.origin.x,
            y: containerView.bounds.height,
            width: targetFrame.width,
            height: targetFrame.height
        )
        toView.setNeedsLayout()
        toView.layoutIfNeeded()
        containerView.addSubview(toView)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: { toView.frame.origin.y = targetFrame.origin.y },
            completion: { transitionContext.completeTransition($0) }
        )
    }

    // MARK: Dismiss

    private func dismiss(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        guard let fromView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: { fromView.frame.origin.y = containerView.bounds.height },
            completion: { transitionContext.completeTransition($0) }
        )
    }
}
