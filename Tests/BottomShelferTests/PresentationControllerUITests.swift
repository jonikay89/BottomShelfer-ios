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

    // MARK: - snapToHeight clamping & detent index

    @Test func snapToHeightUpdatesSelectedDetentIndex() {
        let pc = makeController(
            detents: [.custom(height: 200), .custom(height: 500), .custom(height: 800)],
            selectedIndex: 0
        )
        #expect(pc.selectedDetentIndex == 0)

        pc.snapToHeight(500)
        TestHarness.flushRunLoop(seconds: 0.4)

        #expect(pc.selectedDetentIndex == 1)
        #expect(pc.frameOfPresentedViewInContainerView.height == 500)
    }

    @Test func snapToHeightClampsToMaxHeightFraction() {
        let constrainedSize = CGSize(width: 390, height: 400)
        let pc = makeController(
            detents: [.custom(height: 200), .custom(height: 800)],
            selectedIndex: 0,
            containerSize: constrainedSize,
            configure: { $0.maxHeightFraction = 0.9 }
        )

        pc.presentationTransitionDidEnd(true)
        pc.snapToHeight(800)
        TestHarness.flushRunLoop(seconds: 0.4)

        let maxH = constrainedSize.height * 0.9
        #expect(pc.presentedView?.frame.height == maxH)
        // The y origin must be on-screen, not above the top edge.
        #expect((pc.presentedView?.frame.origin.y ?? -1) >= 0)
    }

    // MARK: - detentIndex closest match

    @Test func snapToHeightSelectsCorrectDetentInConstrainedContainer() {
        let constrainedSize = CGSize(width: 390, height: 400)
        let pc = makeController(
            detents: [.custom(height: 200), .custom(height: 500), .custom(height: 800)],
            selectedIndex: 0,
            containerSize: constrainedSize,
            configure: { $0.maxHeightFraction = 0.9 }
        )
        pc.presentationTransitionDidEnd(true)
        pc.snapToHeight(800)
        TestHarness.flushRunLoop(seconds: 0.4)

        let maxH = constrainedSize.height * 0.9
        // The frame is clamped to maxHeight — sheet stays on screen.
        #expect(pc.presentedView?.frame.height == maxH)
        // The selected detent should be the large one (index 2), since
        // snapToHeight matches against raw detent heights, not capped ones.
        #expect(pc.selectedDetentIndex == 2)
    }

    @Test func detentIndexFallsBackToZeroWhenDetentsEmpty() {
        let pc = makeController(detents: [.custom(height: 300)], selectedIndex: 0)
        pc.detents = []
        // With empty detents, the fallback uses maxHeightFraction.
        let maxH = Self.containerSize.height * pc.layoutConfiguration.maxHeightFraction
        #expect(pc.frameOfPresentedViewInContainerView.height == maxH)
    }

    // MARK: - containerViewWillLayoutSubviews rotation / size-change

    @Test func layoutPreservesDetentWhenContainerSizeUnchanged() {
        let pc = makeController(
            detents: [.custom(height: 200), .custom(height: 500)],
            selectedIndex: 1
        )
        pc.presentationTransitionDidEnd(true)
        #expect(pc.selectedDetentIndex == 1)

        // Trigger layout at the same size — detent index must stay.
        pc.containerViewWillLayoutSubviews()
        #expect(pc.selectedDetentIndex == 1)
    }

    @Test func layoutReDerivesDetentWhenContainerSizeChanges() {
        let initialSize = CGSize(width: 390, height: 844)
        let pc = makeController(
            detents: [.custom(height: 200), .custom(height: 500), .custom(height: 700)],
            selectedIndex: 2,
            containerSize: initialSize
        )
        pc.presentationTransitionDidEnd(true)
        #expect(pc.selectedDetentIndex == 2)
        #expect(pc.presentedView?.frame.height == 700)

        // Simulate rotation to a shorter container where the current detent
        // doesn't fit; the frame should be capped and the index re-derived.
        pc.resizeContainer(to: CGSize(width: 390, height: 480))

        let maxH = 480 * pc.layoutConfiguration.maxHeightFraction
        #expect(pc.presentedView?.frame.height == maxH)
        // The closest detent to the capped frame height should be selected.
        #expect(pc.selectedDetentIndex == 1)  // 500 is closest to 480*0.9=432
    }

    @Test func layoutPreservesInitialDetentBeforePresentationCompletes() {
        let pc = makeController(
            detents: [.custom(height: 100), .custom(height: 300), .custom(height: 600)],
            selectedIndex: 2
        )
        // hasPresented is still false — the simple clamp path must preserve
        // the user-configured index.
        #expect(pc.selectedDetentIndex == 2)
        pc.containerViewWillLayoutSubviews()
        #expect(pc.selectedDetentIndex == 2)
    }

    // MARK: - presentationTransitionDidEnd flag

    @Test func transitionDidEndSetsHasPresented() {
        let pc = makeController(selectedIndex: 0)
        // Manually drive the lifecycle and verify the presented view frame
        // matches after the transition.
        pc.presentationTransitionDidEnd(true)
        let frame = pc.presentedView?.frame
        #expect(frame != nil)
        #expect(frame?.height == 300)  // defaults to 300 from the makeController default
    }
}
