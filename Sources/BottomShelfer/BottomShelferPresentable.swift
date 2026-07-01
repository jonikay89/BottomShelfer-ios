import UIKit
import Combine

/// Adopted by a view controller that wants to be presented as a slide-up sheet.
///
/// The conforming type owns the `BottomShelferPresentationManager` so the same
/// instance is reused as the `transitioningDelegate` across presentations.
@MainActor
public protocol BottomShelferPresentable: AnyObject {
    var bottomShelferPresentationManager: BottomShelferPresentationManager { get }

    /// `true`  – tapping the dimming view dismisses the sheet immediately.
    /// `false` – the first tap on the dimming view closes the keyboard (if
    ///           visible) instead of dismissing; a second tap dismisses.
    var dismissOnHide: Bool { get }
}

extension BottomShelferPresentable where Self: UIViewController {
    /// Default: don't dismiss on the first tap; close the keyboard first.
    public var dismissOnHide: Bool { false }

    /// Convenience entry point: configures `modalPresentationStyle = .custom`
    /// and forwards to the presenting controller's `present(_:animated:)`.
    @MainActor
    public func presentAsBottomShelfer(
        from presentingViewController: UIViewController,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        modalPresentationStyle = .custom
        transitioningDelegate = bottomShelferPresentationManager
        presentingViewController.preferredContentSize = CGSize(
            width: presentingViewController.preferredContentSize.width,
            height: bottomShelferPresentationManager.currentDetentHeight
        )
        presentingViewController.present(self, animated: animated, completion: completion)
    }

    /// Subscribes the sheet to keyboard show/hide notifications so it lifts
    /// out of the way of the keyboard. The supplied `Set<AnyCancellable>`
    /// must be retained by the conforming type for the lifetime of the sheet.
    @MainActor
    public func startObservingKeyboardForBottomShelfer(cancellables: inout Set<AnyCancellable>) {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                // Keyboard notifications are always delivered on the main thread.
                MainActor.assumeIsolated {
                    guard let self,
                          let userInfo = notification.userInfo,
                          let keyboardFrameEnd = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                          let pc = self.presentationController as? BottomShelferPresentationController,
                          let presentedView = pc.presentedView,
                          let containerView = pc.containerView
                    else { return }

                    let keyboardFrameInContainer = containerView.convert(keyboardFrameEnd, from: nil)
                    let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.3
                    // The system reports a private curve (raw value 7) for keyboard
                    // animations; shifting it into the animation-options bits is the
                    // documented way to match the keyboard's motion exactly.
                    let curveValue = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt) ?? 7
                    let options = UIView.AnimationOptions(rawValue: curveValue << 16)

                    let sheetHeight = presentedView.frame.height
                    let targetY = max(keyboardFrameInContainer.minY - sheetHeight, 0)

                    UIView.animate(withDuration: duration, delay: 0, options: options) {
                        presentedView.frame.origin.y = targetY
                    }
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] notification in
                MainActor.assumeIsolated {
                    guard let self,
                          !self.isBeingDismissed,
                          let pc = self.presentationController as? BottomShelferPresentationController,
                          let presentedView = pc.presentedView
                    else { return }

                    let containerHeight = pc.containerView?.bounds.height ?? UIScreen.main.bounds.height
                    let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.25

                    UIView.animate(withDuration: duration) {
                        presentedView.frame.origin.y = containerHeight - presentedView.frame.height
                    }
                }
            }
            .store(in: &cancellables)
    }
}
