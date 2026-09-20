//
//  SwiftQuit.swift
//  Swift Quit
//
//  Created by Johnny Baird on 5/25/22.
//

import Foundation
import AppKit
import AXSwift

class SwiftQuit {
    private static var pendingApplicationClosures: Set<pid_t> = []
    
    /*
     Settings
     */
    
    @objc class func getSettings() -> [String:String] {
        return userDefaults.object(forKey: "SwiftQuitSettings") as? [String:String] ?? ["launchAtLogin":"false","menubarIconEnabled":"true","excludeBehaviour":"excludeApps","launchHidden":"true","closeDelay":"2"]
    }
    
    @objc class func updateSettings(){
        userDefaults.set(swiftQuitSettings, forKey: "SwiftQuitSettings")
    }
    
    @objc class func getExcludedApps() -> [String] {
        return userDefaults.object(forKey: "SwiftQuitExcludedApps") as? [String] ?? []
    }
    
    @objc class func updateExcludedApps(){
        userDefaults.set(swiftQuitExcludedApps, forKey: "SwiftQuitExcludedApps")
    }
    
    @objc class func enableExcludedApps(){
        swiftQuitSettings["excludeBehaviour"] = "excludeApps"
        updateSettings()
    }
    
    @objc class func enableIncludedApps(){
        swiftQuitSettings["excludeBehaviour"] = "includeApps"
        updateSettings()
    }
    
    @objc class func enableMenubarIcon(){
        swiftQuitSettings["menubarIconEnabled"] = "true"
        updateSettings()
    }
    @objc class func disableMenubarIcon(){
        swiftQuitSettings["menubarIconEnabled"] = "false"
        updateSettings()
    }
    
    @objc class func enableLaunchAtLogin(){
        swiftQuitSettings["launchAtLogin"] = "true"
        updateSettings()
    }
    @objc class func disableLaunchAtLogin(){
        swiftQuitSettings["launchAtLogin"] = "false"
        updateSettings()
    }
    
    @objc class func enableLaunchHidden(){
        swiftQuitSettings["launchHidden"] = "true"
        updateSettings()
    }
    @objc class func disableLaunchHidden(){
        swiftQuitSettings["launchHidden"] = "false"
        updateSettings()
    }

    @objc class func setCloseDelay(_ delay: String){
        swiftQuitSettings["closeDelay"] = delay
        updateSettings()
    }

    @objc class func activateAutomaticAppClosing() -> Bool {
        CloseButtonMonitor.start { processIdentifier in
            closeApplication(pid: processIdentifier)
        }
    }
    
    class func closeApplication(pid:Int32) {
        let myAppPid = ProcessInfo.processInfo.processIdentifier

        guard let app = AppKit.NSRunningApplication.init(processIdentifier: pid) else {
            print("Application with PID \(pid) no longer running")
            return
        }

        guard let bundleURL = app.bundleURL else {
            print("Application with PID \(pid) has no bundle URL")
            return
        }
        var applicationName = bundleURL.absoluteString

        guard app.isFinishedLaunching,
              app.activationPolicy == .regular else { return }

        applicationName.remove(at: applicationName.index(before: applicationName.endIndex))
        applicationName = applicationName.replacingOccurrences(of: "file://", with: "")
        applicationName = applicationName.replacingOccurrences(of: "%20", with: " ")

        guard myAppPid != pid else { return }

        let excludedServices:[String] = ["/System/Library/CoreServices/Spotlight.app","/System/Library/CoreServices/Finder.app","/System/Library/CoreServices/NotificationCenter.app"]

        guard !excludedServices.contains(applicationName),
              shouldCloseApplication(applicationName: applicationName) else { return }

        guard !pendingApplicationClosures.contains(pid) else { return }
        pendingApplicationClosures.insert(pid)

        let closeDelay = Int(swiftQuitSettings["closeDelay"] ?? "2") ?? 2
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(closeDelay)) {
            defer { pendingApplicationClosures.remove(pid) }

            guard !app.isTerminated else { return }

            if WindowVisibility.hasUserVisibleWindow(for: pid) {
                print("Application still has a user-visible window; aborting")
                return
            }

            terminateApplication(app: app)
        }
    }

    class func shouldCloseApplication(applicationName:String) -> Bool {
        return (swiftQuitSettings["excludeBehaviour"] == "excludeApps" && !swiftQuitExcludedApps.contains(applicationName)) || (swiftQuitSettings["excludeBehaviour"] == "includeApps" && swiftQuitExcludedApps.contains(applicationName))
    }
    
    class func terminateApplication(app:NSRunningApplication) {
        print("Terminated " + (app.localizedName ?? "<no_name>"))
        app.terminate()
    }
    
    class func hideMenu(){
        statusItem.isVisible = false
    }
    
    class func showMenu(){
        statusItem.isVisible = true
    }
    
    
}

private enum CloseButtonMonitor {
    private static var eventTap: CFMachPort?
    private static var eventTapRunLoopSource: CFRunLoopSource?
    private static var closeButtonClickHandler: ((pid_t) -> Void)?

    static func start(onCloseButtonClick: @escaping (pid_t) -> Void) -> Bool {
        guard eventTap == nil else { return true }
        guard CGPreflightListenEventAccess() || CGRequestListenEventAccess() else { return false }

        closeButtonClickHandler = onCloseButtonClick
        let eventMask = CGEventMask(1) << CGEventType.leftMouseDown.rawValue
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: nil
        ) else {
            closeButtonClickHandler = nil
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        self.eventTap = eventTap
        eventTapRunLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        return true
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, _ in
        if type == .tapDisabledByTimeout, let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }

        if type == .leftMouseDown {
            let point = event.location
            DispatchQueue.main.async {
                guard let processIdentifier = processIdentifierOfCloseButton(at: point) else {
                    return
                }
                closeButtonClickHandler?(processIdentifier)
            }
        }

        return Unmanaged.passUnretained(event)
    }

    private static func processIdentifierOfCloseButton(at point: CGPoint) -> pid_t? {
        var element: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(
            AXUIElementCreateSystemWide(),
            Float(point.x),
            Float(point.y),
            &element
        )

        guard result == .success,
              let element,
              WindowVisibility.isWindowCloseButton(subrole: stringAttribute(kAXSubroleAttribute, of: element))
        else {
            return nil
        }

        var processIdentifier: pid_t = 0
        guard AXUIElementGetPid(element, &processIdentifier) == .success else {
            return nil
        }

        return processIdentifier
    }

    private static func stringAttribute(_ attribute: String, of element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value
        else {
            return nil
        }

        return value as? String
    }
}
