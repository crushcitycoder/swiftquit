import Foundation

/// Detects a transition from at least one visible user window to none.
/// This is a fallback for apps that do not emit a useful Accessibility close event.
struct WindowClosureMonitor {
    private var processesWithVisibleWindows: Set<pid_t> = []

    mutating func observe(processIdentifier: pid_t, hasVisibleWindow: Bool) -> Bool {
        if hasVisibleWindow {
            processesWithVisibleWindows.insert(processIdentifier)
            return false
        }

        return processesWithVisibleWindows.remove(processIdentifier) != nil
    }

    mutating func removeStoppedProcesses(_ activeProcessIdentifiers: Set<pid_t>) {
        processesWithVisibleWindows.formIntersection(activeProcessIdentifiers)
    }
}
