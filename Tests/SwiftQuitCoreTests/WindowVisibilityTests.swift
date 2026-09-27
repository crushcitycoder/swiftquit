import XCTest
@testable import SwiftQuitCore

final class WindowVisibilityTests: XCTestCase {
    func testDetectsNormalVisibleWindowForTheTargetApplication() {
        let records = [
            WindowVisibility.Record(ownerPID: 42, layer: 0, alpha: 1),
            WindowVisibility.Record(ownerPID: 99, layer: 0, alpha: 1)
        ]

        XCTAssertTrue(WindowVisibility.hasUserVisibleWindow(for: 42, in: records))
    }

    func testIgnoresWindowsOwnedByOtherApplications() {
        let records = [WindowVisibility.Record(ownerPID: 99, layer: 0, alpha: 1)]

        XCTAssertFalse(WindowVisibility.hasUserVisibleWindow(for: 42, in: records))
    }

    func testIgnoresNonUserFacingAndTransparentWindows() {
        let records = [
            WindowVisibility.Record(ownerPID: 42, layer: 25, alpha: 1),
            WindowVisibility.Record(ownerPID: 42, layer: 0, alpha: 0)
        ]

        XCTAssertFalse(WindowVisibility.hasUserVisibleWindow(for: 42, in: records))
    }

    func testIdentifiesTheRedWindowCloseButton() {
        XCTAssertTrue(WindowVisibility.isWindowCloseButton(subrole: "AXCloseButton"))
    }

    func testRejectsOtherTrafficLightAndUnrelatedControls() {
        XCTAssertFalse(WindowVisibility.isWindowCloseButton(subrole: "AXMinimizeButton"))
        XCTAssertFalse(WindowVisibility.isWindowCloseButton(subrole: nil))
    }

    func testExclusionMatchesStandardizedPathWithSpaces() {
        let shouldClose = ApplicationExclusions.shouldCloseApplication(
            at: URL(fileURLWithPath: "/Applications/Hidden Bar.app"),
            excludeBehaviour: "excludeApps",
            configuredPaths: ["/Applications/Hidden Bar.app/"]
        )

        XCTAssertFalse(shouldClose)
    }

    func testIncludedAppModeClosesOnlyConfiguredApps() {
        let hiddenBarURL = URL(fileURLWithPath: "/Applications/Hidden Bar.app")
        let configuredPaths = ["file:///Applications/Hidden%20Bar.app/"]

        XCTAssertTrue(
            ApplicationExclusions.shouldCloseApplication(
                at: hiddenBarURL,
                excludeBehaviour: "includeApps",
                configuredPaths: configuredPaths
            )
        )
        XCTAssertFalse(
            ApplicationExclusions.shouldCloseApplication(
                at: URL(fileURLWithPath: "/Applications/Swift Quit Fork.app"),
                excludeBehaviour: "includeApps",
                configuredPaths: configuredPaths
            )
        )
    }

    func testUnknownExclusionModeNeverClosesAnApp() {
        XCTAssertFalse(
            ApplicationExclusions.shouldCloseApplication(
                at: URL(fileURLWithPath: "/Applications/Hidden Bar.app"),
                excludeBehaviour: nil,
                configuredPaths: []
            )
        )
    }

    func testIdentifiesApplicationBundledHelpers() {
        XCTAssertTrue(
            ApplicationBundles.containsEmbeddedApplication(
                URL(fileURLWithPath: "/Applications/Adobe Photoshop 2025/Adobe Photoshop 2025.app/Contents/Frameworks/AdobeCrashReporter.framework/Versions/A/Adobe Crash Processor.app"),
                in: URL(fileURLWithPath: "/Applications/Adobe Photoshop 2025/Adobe Photoshop 2025.app")
            )
        )
    }

    func testDoesNotTreatAdjacentApplicationBundlesAsEmbedded() {
        XCTAssertFalse(
            ApplicationBundles.containsEmbeddedApplication(
                URL(fileURLWithPath: "/Applications/Adobe Photoshop 2025/Adobe Photoshop 2025 Plus.app"),
                in: URL(fileURLWithPath: "/Applications/Adobe Photoshop 2025/Adobe Photoshop 2025.app")
            )
        )
    }
}
