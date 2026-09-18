import XCTest
@testable import SwiftQuitCore

final class WindowClosureMonitorTests: XCTestCase {
    func testClosesOnlyAfterAVisibleToHiddenTransition() {
        var monitor = WindowClosureMonitor()

        XCTAssertFalse(monitor.observe(processIdentifier: 42, hasVisibleWindow: true))
        XCTAssertTrue(monitor.observe(processIdentifier: 42, hasVisibleWindow: false))
        XCTAssertFalse(monitor.observe(processIdentifier: 42, hasVisibleWindow: false))
    }

    func testDoesNotCloseAProcessThatStartedWithoutAVisibleWindow() {
        var monitor = WindowClosureMonitor()

        XCTAssertFalse(monitor.observe(processIdentifier: 42, hasVisibleWindow: false))
    }

    func testForgetsProcessesThatHaveStoppedRunning() {
        var monitor = WindowClosureMonitor()
        _ = monitor.observe(processIdentifier: 42, hasVisibleWindow: true)
        monitor.removeStoppedProcesses([])

        XCTAssertFalse(monitor.observe(processIdentifier: 42, hasVisibleWindow: false))
    }
}
