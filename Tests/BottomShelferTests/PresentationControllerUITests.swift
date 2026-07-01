import Testing
import UIKit
@testable import BottomShelfer

/// UI integration tests for `BottomShelferPresentationController`.
///
/// These exercise the real frame math, layout-configuration overrides, detent
/// selection, grabber/gesture installation, and programmatic snapping against a
/// synthetic container view. They do NOT go through `UIViewController.present`
/// (UIKit never drives a custom transition to completion inside the SwiftPM
/// test bundle's execution context), so a `TestablePresentationController`
/// stands in with a fixed container. This tests the controller's actual
/// behavior — the closest a SwiftPM package gets to "UI tests" without an app
/// host target for XCUITest.
@MainActor
struct PresentationControllerUITests {

    private static let containerSize = CGSize(width: 390, height: 844)

    /// Builds a configured, installed controller ready for assertions.
    private func makeController(
        detents: [BottomShelferDetent] = [.custom(height: 300)],
        selectedIndex: Int = 0,
        containerSize: CGSize = PresentationControllerUITests.containerSize,
        configure: ((inout BottomShelferLayoutConfiguration) -> Void)? = nil
    ) -> TestablePresentationController {
        let presented = UIViewController()
        let pc = TestablePresentationController(
            presented: presented,
            presenting: nil,
            containerSize: containerSize
        )
        pc.detents = detents
        pc.selectedDetentIndex = selectedIndex
        if let configure {
            var layout = pc.layoutConfiguration
            configure(&layout)
            pc.layoutConfiguration = layout
        }
        // Run the presentation lifecycle so the presented view is laid out,
        // grabber + gestures are installed, and snap points are built.
        pc.presentationTransitionWillBegin()
        pc.containerViewWillLayoutSubviews()
        return pc
    }

    // MARK: Frame geometry

    @Test func frameUsesCurrentDetentHeightAndBottomAnchors() {
        let pc = makeController(detents: [.custom(height: 300)])
        let frame = pc.frameOfPresentedViewInContainerView
        #expect(frame.height == 300)
        // Bottom-anchored: the sheet's bottom edge meets the container's bottom.
        #expect(frame.maxY == Self.containerSize.height)
    }

    @Test func frameIsHorizontallyCentered() {
        let pc = makeController()
        let frame = pc.frameOfPresentedViewInContainerView
        let sideMargins = Self.containerSize.width - frame.width
        #expect(frame.minX == sideMargins / 2)
    }

    @Test func frameWidthClampsToContainerWidth() {
        // Container is only 300pt wide; sheet must not exceed it even though the
        // default cap is 430.
        let pc = makeController(
            detents: [.custom(height: 200)],
            containerSize: CGSize(width: 300, height: 800)
        )
        #expect(pc.frameOfPresentedViewInContainerView.width == 300)
    }

    // MARK: Layout configuration overrides

    @Test func configuredMaxSheetWidthLimitsFrameWidth() {
        let pc = makeController(configure: { $0.maxSheetWidth = 200 })
        #expect(pc.frameOfPresentedViewInContainerView.width == 200)
    }

    @Test func configuredMaxHeightFractionCapsDetentHeight() {
        // Detent asks for 600, but a 0.4 max-fraction on an 844pt container
        // (≈336.8pt) must win.
        let pc = makeController(
            detents: [.custom(height: 600)],
            configure: { $0.maxHeightFraction = 0.4 }
        )
        let expected = min(600, Self.containerSize.height * 0.4)
        #expect(pc.frameOfPresentedViewInContainerView.height == expected)
    }

    @Test func configurationCarriesThroughAfterInstall() {
        let pc = makeController(configure: { config in
            config.grabberPillSize = CGSize(width: 60, height: 8)
            config.grabberHitAreaHeight = 50
            config.grabberPillBottomOffset = 20
            config.grabberPillCornerRadius = 6
        })
        #expect(pc.layoutConfiguration.grabberPillSize == CGSize(width: 60, height: 8))
        #expect(pc.layoutConfiguration.grabberHitAreaHeight == 50)
        #expect(pc.layoutConfiguration.grabberPillBottomOffset == 20)
        #expect(pc.layoutConfiguration.grabberPillCornerRadius == 6)
    }

    // MARK: Detent selection on present

    @Test func selectedDetentIndexChoosesOpeningHeight() {
        let pc = makeController(
            detents: [.custom(height: 200), .custom(height: 400), .custom(height: 600)],
            selectedIndex: 2
        )
        #expect(pc.frameOfPresentedViewInContainerView.height == 600)
    }

    // MARK: Programmatic snapping

    @Test func snapToHeightUpdatesPresentedViewFrame() {
        let pc = makeController(detents: [.custom(height: 200), .custom(height: 500)], selectedIndex: 0)
        #expect(pc.frameOfPresentedViewInContainerView.height == 200)

        // Manually drive the snap so the test is deterministic and fast.
        pc.snapToHeight(500)
        TestHarness.flushRunLoop(seconds: 0.4)

        #expect(pc.presentedView?.frame.height == 500)
    }

    // MARK: Presentation wiring

    @Test func containerAndPresentedViewAreInstalled() {
        let pc = makeController()
        #expect(pc.containerView != nil)
        #expect(pc.presentedView != nil)
    }

    @Test func grabberGesturesAreInstalled() {
        let pc = makeController()
        guard let presentedView = pc.presentedView else {
            Issue.record("no presented view")
            return
        }
        let hasGrabber = presentedView.gestureRecognizers?.contains { $0 === pc.grabberPanGesture } ?? false
        let hasContent = presentedView.gestureRecognizers?.contains { $0 === pc.contentPanGesture } ?? false
        #expect(hasGrabber)
        #expect(hasContent)
    }

    @Test func grabberPillUsesConfiguredCornerRadius() {
        let pc = makeController(configure: { $0.grabberPillCornerRadius = 9 })
        // The pill is added to the presented view's hierarchy during install.
        guard let presentedView = pc.presentedView else {
            Issue.record("no presented view")
            return
        }
        let pill = findView(in: presentedView) { abs($0.layer.cornerRadius - 9) < 0.001 }
        #expect(pill != nil)
    }

    private func findView(in view: UIView, matching predicate: (UIView) -> Bool) -> UIView? {
        if predicate(view) { return view }
        for sub in view.subviews {
            if let found = findView(in: sub, matching: predicate) { return found }
        }
        return nil
    }
}
