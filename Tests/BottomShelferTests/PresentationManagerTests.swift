import Testing
import UIKit
@testable import BottomShelfer

/// Tests for `BottomShelferPresentationManager` — configuration ownership and
/// how it builds the presentation/animator controllers.
@MainActor
struct PresentationManagerTests {

    // MARK: Defaults

    @Test func defaultConfiguration() {
        let manager = BottomShelferPresentationManager()
        #expect(manager.detents == [.large()])
        #expect(manager.selectedDetentIndex == 0)
        #expect(manager.cornerRadius == 20)
        #expect(manager.isDimmingViewEnabled)
        #expect(manager.isDraggingEnabled)
        #expect(manager.allowGrabbingNonScrollViews == false)
        #expect(manager.layoutConfiguration == .default)
    }

    // MARK: currentDetentHeight

    @Test func currentDetentHeightRespectsSelectedIndex() {
        let manager = BottomShelferPresentationManager()
        manager.detents = [.custom(height: 200), .custom(height: 400), .custom(height: 600)]
        manager.selectedDetentIndex = 1
        #expect(manager.currentDetentHeight == 400)
    }

    @Test func currentDetentHeightClampsSelectedIndex() {
        let manager = BottomShelferPresentationManager()
        manager.detents = [.custom(height: 200), .custom(height: 400)]
        manager.selectedDetentIndex = 99   // out of bounds
        #expect(manager.currentDetentHeight == 400)
    }

    @Test func currentDetentHeightEmptyDetentsUsesMaxFraction() {
        let manager = BottomShelferPresentationManager()
        manager.detents = []
        manager.layoutConfiguration.maxHeightFraction = 0.5
        let expected = UIScreen.main.bounds.height * 0.5
        #expect(manager.currentDetentHeight == expected)
    }

    // MARK: presentationController(forPresented:presenting:source:)

    @Test func presentationControllerCopiesAllConfig() {
        let manager = BottomShelferPresentationManager()
        manager.detents = [.custom(height: 123), .custom(height: 456)]
        manager.selectedDetentIndex = 1
        manager.cornerRadius = 12
        manager.isDimmingViewEnabled = false
        manager.isDraggingEnabled = false
        manager.allowGrabbingNonScrollViews = true
        manager.dimmingColor = .red
        var layout = BottomShelferLayoutConfiguration()
        layout.maxSheetWidth = 333
        manager.layoutConfiguration = layout

        let host = UIViewController()
        let sheet = UIViewController()
        let pc = manager.presentationController(forPresented: sheet, presenting: host, source: host)
        guard let controller = pc as? BottomShelferPresentationController else {
            Issue.record("expected a BottomShelferPresentationController")
            return
        }

        #expect(controller.detents == [.custom(height: 123), .custom(height: 456)])
        #expect(controller.selectedDetentIndex == 1)
        #expect(controller.cornerRadius == 12)
        #expect(controller.isDimmingViewEnabled == false)
        #expect(controller.isDraggingEnabled == false)
        #expect(controller.allowGrabbingNonScrollViews == true)
        #expect(controller.dimmingColor == .red)
        #expect(controller.layoutConfiguration.maxSheetWidth == 333)
    }

    @Test func returnsPresentationControllerSubclass() {
        let manager = BottomShelferPresentationManager()
        let host = UIViewController()
        let sheet = UIViewController()
        let pc = manager.presentationController(forPresented: sheet, presenting: host, source: host)
        #expect(pc is BottomShelferPresentationController)
    }

    // MARK: animation controllers

    @Test func animationControllerForPresentIsPresentingTrue() {
        let manager = BottomShelferPresentationManager()
        let host = UIViewController()
        let sheet = UIViewController()
        let animator = manager.animationController(forPresented: sheet, presenting: host, source: host)
        #expect((animator as? BottomShelferPresentationAnimator)?.isPresenting == true)
    }

    @Test func animationControllerForDismissIsPresentingFalse() {
        let manager = BottomShelferPresentationManager()
        let sheet = UIViewController()
        let animator = manager.animationController(forDismissed: sheet)
        #expect((animator as? BottomShelferPresentationAnimator)?.isPresenting == false)
    }

    @Test func animatorInheritsLayoutConfiguration() {
        let manager = BottomShelferPresentationManager()
        manager.layoutConfiguration.maxSheetWidth = 700
        let host = UIViewController()
        let sheet = UIViewController()
        let animator = manager.animationController(forPresented: sheet, presenting: host, source: host) as? BottomShelferPresentationAnimator
        #expect(animator?.layoutConfiguration.maxSheetWidth == 700)
    }
}
