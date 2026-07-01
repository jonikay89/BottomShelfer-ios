import Testing
import UIKit
@testable import BottomShelfer

/// Unit tests for `BottomShelferDetent` — the pure-logic snap-point model.
///
/// `@MainActor` because the system-detent factories read `UIScreen.main`.
@MainActor
struct DetentTests {

    // MARK: Construction

    @Test func customDetentStoresHeight() {
        let detent = BottomShelferDetent(height: 250)
        #expect(detent.height == 250)
    }

    @Test func customFactoryMatchesInit() {
        #expect(BottomShelferDetent.custom(height: 480).height == 480)
    }

    // MARK: System-detent ratios

    @Test func systemDetentRatios() {
        let screenH = UIScreen.main.bounds.height
        #expect(BottomShelferDetent.small().height == screenH * 0.25)
        #expect(BottomShelferDetent.medium().height == screenH * 0.5)
        #expect(BottomShelferDetent.large().height == screenH * 0.9)
    }

    // MARK: detents(forContentHeight:)

    @Test func detentsForContentHeightAreAscending() {
        let detents = BottomShelferDetent.detents(forContentHeight: 420)
        #expect(detents.count == 3)
        #expect(detents[0].height < detents[1].height)
        #expect(detents[1].height < detents[2].height)
    }

    @Test func detentsForContentHeightClampTo90Percent() {
        let screenH = UIScreen.main.bounds.height
        let cap = screenH * 0.9
        let detents = BottomShelferDetent.detents(forContentHeight: 1_000)
        // Every produced height must obey the 90% screen cap.
        for d in detents {
            #expect(d.height <= cap)
        }
        #expect(detents.last?.height == cap)
    }

    @Test func detentsForContentHeightSmallFloorIs200() {
        let detents = BottomShelferDetent.detents(forContentHeight: 100)
        // small = contentHeight*0.4 clamped to a 200pt minimum.
        #expect(detents[0].height == 200)
    }

    // MARK: Equatable / Hashable

    @Test func equatableByHeight() {
        #expect(BottomShelferDetent(height: 100) == BottomShelferDetent(height: 100))
        #expect(BottomShelferDetent(height: 100) != BottomShelferDetent(height: 101))
    }

    @Test func hashableInSet() {
        let set: Set<BottomShelferDetent> = [.custom(height: 100), .custom(height: 100), .custom(height: 200)]
        #expect(set.count == 2)
    }
}
