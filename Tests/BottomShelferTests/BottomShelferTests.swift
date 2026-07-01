import Testing
import UIKit
@testable import BottomShelfer

/// Smoke test: the module and its primary types are importable/instantiable.
@MainActor
struct BottomShelferSmokeTests {

    @Test func managerIsConstructable() {
        let manager = BottomShelferPresentationManager()
        #expect(manager.detents.count >= 1)
    }

    @Test func layoutConstantsArePositive() {
        #expect(BottomShelferLayout.maxSheetWidth > 0)
        #expect(BottomShelferLayout.maxHeightFraction > 0)
        #expect(BottomShelferLayout.grabberHitAreaHeight > 0)
    }
}
