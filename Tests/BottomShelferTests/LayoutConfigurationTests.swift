import Testing
import UIKit
@testable import BottomShelfer

/// Unit tests for `BottomShelferLayoutConfiguration` and the package defaults in
/// `BottomShelferLayout`.
@MainActor
struct LayoutConfigurationTests {

    // MARK: Defaults mirror the static constants

    @Test func defaultsMatchStaticConstants() {
        let config = BottomShelferLayoutConfiguration()
        #expect(config.maxSheetWidth == BottomShelferLayout.maxSheetWidth)
        #expect(config.maxHeightFraction == BottomShelferLayout.maxHeightFraction)
        #expect(config.grabberHitAreaHeight == BottomShelferLayout.grabberHitAreaHeight)
        #expect(config.grabberPillSize == BottomShelferLayout.grabberPillSize)
        #expect(config.grabberPillBottomOffset == BottomShelferLayout.grabberPillBottomOffset)
        #expect(config.grabberPillCornerRadius == BottomShelferLayout.grabberPillCornerRadius)
    }

    @Test func defaultPresetEqualsDefaultInit() {
        #expect(BottomShelferLayoutConfiguration.default == BottomShelferLayoutConfiguration())
    }

    // MARK: Mutation

    @Test func propertiesAreMutableAndIndependent() {
        var config = BottomShelferLayoutConfiguration()
        config.maxSheetWidth = 500
        config.grabberPillSize = CGSize(width: 60, height: 8)
        config.grabberPillBottomOffset = 14
        config.grabberPillCornerRadius = 4
        config.grabberHitAreaHeight = 60
        config.maxHeightFraction = 0.75

        #expect(config.maxSheetWidth == 500)
        #expect(config.grabberPillSize == CGSize(width: 60, height: 8))
        #expect(config.grabberPillBottomOffset == 14)
        #expect(config.grabberPillCornerRadius == 4)
        #expect(config.grabberHitAreaHeight == 60)
        #expect(config.maxHeightFraction == 0.75)

        // Untouched global default stays intact.
        let fresh = BottomShelferLayoutConfiguration()
        #expect(fresh.maxSheetWidth == BottomShelferLayout.maxSheetWidth)
    }

    @Test func initOverridesEachParameter() {
        let config = BottomShelferLayoutConfiguration(
            maxSheetWidth: 700,
            maxHeightFraction: 0.6,
            grabberHitAreaHeight: 50,
            grabberPillSize: CGSize(width: 50, height: 6),
            grabberPillBottomOffset: 10,
            grabberPillCornerRadius: 3
        )
        #expect(config.maxSheetWidth == 700)
        #expect(config.maxHeightFraction == 0.6)
        #expect(config.grabberHitAreaHeight == 50)
        #expect(config.grabberPillSize == CGSize(width: 50, height: 6))
        #expect(config.grabberPillBottomOffset == 10)
        #expect(config.grabberPillCornerRadius == 3)
    }

    // MARK: Equatable

    @Test func equality() {
        var a = BottomShelferLayoutConfiguration()
        let b = BottomShelferLayoutConfiguration()
        #expect(a == b)
        a.maxSheetWidth += 1
        #expect(a != b)
    }

    // MARK: sheetWidth(in:)

    @Test func sheetWidthClampsToContainerWhenNarrowerThanCap() {
        let config = BottomShelferLayoutConfiguration(maxSheetWidth: 430)
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 800))
        // Container (300) < screen width < cap → result is the container width.
        #expect(config.sheetWidth(in: container) == 300)
    }

    @Test func sheetWidthClampsToConfiguredCap() {
        let config = BottomShelferLayoutConfiguration(maxSheetWidth: 250)
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 800))
        // Container is wide, but the configured cap (250) wins over the package
        // default (430) because it's smaller.
        #expect(config.sheetWidth(in: container) == 250)
    }

    @Test func staticSheetWidthMatchesDefaultConfig() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        #expect(BottomShelferLayout.sheetWidth(in: container)
                == BottomShelferLayoutConfiguration().sheetWidth(in: container))
    }
}
