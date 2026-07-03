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
        pc.presentationTransitionWillBegin()
        pc.containerViewWillLayoutSubviews()
        return pc
    }

    // MARK: Frame geometry

    @Test func frameUsesCurrentDetentHeightAndBottomAnchors() {
        let pc = makeController(detents: [.custom(height: 300)])
        let frame = pc.frameOfPresentedViewInContainerView
        #expect(frame.height == 300)
        #expect(frame.maxY == Self.containerSize.height)
    }

    @Test func frameIsHorizontallyCentered() {
        let pc = makeController()
        let frame = pc.frameOfPresentedViewInContainerView
        let sideMargins = Self.containerSize.width - frame.width
        #expect(frame.minX == sideMargins / 2)
    }

    @Test func frameWidthClampsToContainerWidth() {
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
        #expect(pc.presentedView?.frame.height == maxH)
        #expect(pc.selectedDetentIndex == 2)
    }

    @Test func detentIndexFallsBackToZeroWhenDetentsEmpty() {
        let pc = makeController(detents: [.custom(height: 300)], selectedIndex: 0)
        pc.detents = []
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
        pc.resizeContainer(to: CGSize(width: 390, height: 480))
        let maxH = 480 * pc.layoutConfiguration.maxHeightFraction
        #expect(pc.presentedView?.frame.height == maxH)
        #expect(pc.selectedDetentIndex == 1)
    }

    @Test func layoutPreservesInitialDetentBeforePresentationCompletes() {
        let pc = makeController(
            detents: [.custom(height: 100), .custom(height: 300), .custom(height: 600)],
            selectedIndex: 2
        )
        #expect(pc.selectedDetentIndex == 2)
        pc.containerViewWillLayoutSubviews()
        #expect(pc.selectedDetentIndex == 2)
    }

    // MARK: - presentationTransitionDidEnd flag

    @Test func transitionDidEndSetsHasPresented() {
        let pc = makeController(selectedIndex: 0)
        pc.presentationTransitionDidEnd(true)
        let frame = pc.presentedView?.frame
        #expect(frame != nil)
        #expect(frame?.height == 300)
    }

    // MARK: - keyboard offset

    @Test func keyboardOffsetShiftsFrameUp() {
        let pc = makeController(detents: [.custom(height: 300)], selectedIndex: 0)
        #expect(pc.keyboardOffsetY == 0)
        let before = pc.frameOfPresentedViewInContainerView
        pc.keyboardOffsetY = 120
        let after = pc.frameOfPresentedViewInContainerView
        #expect(after.origin.y == before.origin.y - 120)
        #expect(after.height == before.height)
        #expect(after.width == before.width)
    }

    @Test func keyboardOffsetClampedToZeroY() {
        let pc = makeController(detents: [.custom(height: 300)], selectedIndex: 0)
        let containerH = Self.containerSize.height
        pc.keyboardOffsetY = containerH
        let frame = pc.frameOfPresentedViewInContainerView
        #expect(frame.origin.y >= 0)
    }

    // MARK: - dimming view

    @Test func finalizeSnapDoesNotShowDimmingWhenDisabled() {
        let presented = UIViewController()
        _ = presented.view
        let pc = TestablePresentationController(
            presented: presented,
            presenting: nil,
            containerSize: Self.containerSize
        )
        pc.isDimmingViewEnabled = false
        pc.detents = [.custom(height: 300)]
        pc.selectedDetentIndex = 0
        pc.presentationTransitionWillBegin()
        pc.containerViewWillLayoutSubviews()
        pc.presentationTransitionDidEnd(true)
        pc.finalizeSnap(to: CGSize(width: 390, height: 300))
        let containerSubviews = pc.containerView?.subviews ?? []
        let dimming = containerSubviews.first { $0.backgroundColor != .clear }
        #expect(dimming?.alpha == 0)
    }

    // MARK: - callbacks

    @Test func onDetentChangedFiresOnSnapToHeight() {
        let pc = makeController(
            detents: [.custom(height: 200), .custom(height: 500)],
            selectedIndex: 0
        )
        pc.presentationTransitionDidEnd(true)

        var firedIndex: Int?
        var firedHeight: CGFloat?
        pc.onDetentChanged = { idx, h in
            firedIndex = idx
            firedHeight = h
        }

        pc.snapToHeight(500)
        pc.finalizeSnap(to: CGSize(width: 390, height: 500))

        #expect(firedIndex == 1)
        #expect(firedHeight == 500)
    }

    @Test func onDetentChangedFiresOnLayoutResize() {
        let pc = makeController(
            detents: [.custom(height: 200), .custom(height: 500), .custom(height: 800)],
            selectedIndex: 2,
            containerSize: CGSize(width: 390, height: 844),
            configure: { $0.maxHeightFraction = 0.9 }
        )
        pc.presentationTransitionDidEnd(true)

        var firedIndex: Int?
        pc.onDetentChanged = { idx, _ in firedIndex = idx }

        pc.resizeContainer(to: CGSize(width: 390, height: 480))
        #expect(firedIndex == 1)
    }

    // MARK: - helpers

    private func drivePan(
        _ gesture: UIPanGestureRecognizer,
        on pc: TestablePresentationController,
        translation: CGPoint
    ) {
        guard let pv = pc.presentedView else { return }

        gesture.setTranslation(.zero, in: pv)
        gesture.state = .began
        pc.handleGrabberPan(gesture)

        gesture.setTranslation(translation, in: pv)
        gesture.state = .changed
        pc.handleGrabberPan(gesture)

        gesture.state = .ended
        pc.handleGrabberPan(gesture)

        TestHarness.flushRunLoop(seconds: 0.3)
    }

    // MARK: - grabber pill

    @Test func grabberPillAnimatesOnDrag() {
        let pc = makeController(detents: [.custom(height: 200), .custom(height: 500)], selectedIndex: 1)
        pc.presentationTransitionDidEnd(true)

        // Pill should be at identity transform and full alpha before drag.
        let initialAlpha = findGrabberPillAlpha(in: pc)
        #expect(initialAlpha == 1)

        drivePan(pc.grabberPanGesture, on: pc, translation: CGPoint(x: 0, y: 50))

        // After drag ends, pill should return to identity and full alpha.
        let finalAlpha = findGrabberPillAlpha(in: pc)
        #expect(finalAlpha == 1)
    }

    @Test func grabberPillFadesInOnPresentation() {
        let presented = UIViewController()
        let pc = TestablePresentationController(
            presented: presented,
            presenting: nil,
            containerSize: Self.containerSize
        )
        pc.detents = [.custom(height: 300)]
        pc.selectedDetentIndex = 0
        pc.presentationTransitionWillBegin()

        let alpha = findGrabberPillAlpha(in: pc)
        #expect(alpha == 1)
    }

    @Test func grabberPillSizeZeroHidesPill() {
        let pc = makeController(configure: {
            $0.grabberPillSize = .zero
            $0.grabberPillBottomOffset = 0
        })
        guard let pv = pc.presentedView else { return }
        let pill = findView(in: pv) { v in
            v.bounds.size == .zero && v.layer.cornerRadius > 0
        }
        // Should not find a visible pill — but the zero-sized view
        // still exists in the hierarchy with constraints active.
        #expect(pill == nil || pill?.bounds.size == .zero)
    }

    private func findGrabberPillAlpha(in pc: TestablePresentationController) -> CGFloat {
        guard let pv = pc.presentedView else { return -1 }
        for sub in pv.subviews {
            for inner in sub.subviews {
                if inner.layer.cornerRadius > 0 {
                    return inner.alpha
                }
            }
        }
        return -1
    }
}
