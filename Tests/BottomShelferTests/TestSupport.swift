import UIKit
import BottomShelfer
@testable import BottomShelfer

// MARK: - Test sheet view controller

/// Minimal `BottomShelferPresentable` conformer used by the UI integration tests.
@MainActor
final class TestSheetViewController: UIViewController, BottomShelferPresentable {
    let bottomShelferPresentationManager = BottomShelferPresentationManager()

    var dismissOnHide: Bool { false }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
    }
}

// MARK: - Testable presentation controller

/// A `BottomShelferPresentationController` whose `containerView` is a fixed,
/// synthetic view. This lets the UI integration tests exercise the real frame
/// math and lifecycle methods deterministically, without relying on UIKit's
/// `present()` transition (which is not driven to completion inside the test
/// bundle's execution context).
@MainActor
final class TestablePresentationController: BottomShelferPresentationController {
    private let syntheticContainer: UIView

    init(presented: UIViewController,
         presenting: UIViewController?,
         containerSize: CGSize) {
        self.syntheticContainer = UIView(frame: CGRect(origin: .zero, size: containerSize))
        super.init(presentedViewController: presented, presenting: presenting)
    }

    override var containerView: UIView? { syntheticContainer }
}

// MARK: - Window harness

@MainActor
enum TestHarness {
    /// Spins the main run loop so a `UIView.animate` (driven by a CADisplayLink
    /// on the main run loop) can progress / settle.
    static func flushRunLoop(seconds: TimeInterval = 0.3) {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: seconds))
    }
}
