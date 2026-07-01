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

    @Test func bundledLogoImageLoadsFromAssetCatalog() {
        // Confirms the BottomShelfer.svg was compiled into the framework's
        // asset catalog and is resolvable via Bundle.module at runtime.
        let logo = BottomShelferAssets.logo
        #expect(logo != nil)
        #expect((logo?.size.width ?? 0) > 0)
    }
}
