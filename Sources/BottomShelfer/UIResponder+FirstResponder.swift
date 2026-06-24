import UIKit

/// Access to the current first responder via the action-into-responder-chain trick.
///
/// `UIKit` does not expose the first responder directly. We send an action to
/// `nil` (which routes to the first responder); the receiver records itself
/// into a static weak slot, which we then read back. Safe to call from the
/// main thread only.
extension UIResponder {

    private static weak var current: UIResponder?

    /// The current first responder, or `nil` if there is none.
    /// Sending `self` as the `from:` object lets us return early if no
    /// responder answers along the chain.
    var bottomShelfer_firstResponder: UIResponder? {
        UIResponder.current = nil
        UIApplication.shared.sendAction(
            #selector(UIResponder.bottomShelfer_findFirstResponder(_:)),
            to: nil,
            from: self,
            for: nil
        )
        return UIResponder.current
    }

    @objc fileprivate func bottomShelfer_findFirstResponder(_ sender: Any) {
        UIResponder.current = self
    }
}
