//
//  AppDelegate.swift
//  AutoMute
//
//  Created by Lorenzo Gentile on 2015-08-30.
//  Copyright © 2015 Lorenzo Gentile. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, WifiManagerDelegate {
    private let storyboard = NSStoryboard(name: Storyboards.setupWindow, bundle: nil)
    private var windowController: NSWindowController?
    private let wifiManager = WifiManager()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let currentNetworkItem = NSMenuItem(title: "", action: Selector(""), keyEquivalent: "")
    private let infoItem = NSMenuItem(title: "", action: Selector(""), keyEquivalent: "")
    private var lastActionDate: NSDate? = nil
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        wifiManager.delegate = self
        wifiManager.startWifiScanning()
        LaunchAtLoginController().setLaunchAtLogin(true, for: NSURL(fileURLWithPath: Bundle.main.bundlePath) as URL)
        configureStatusBarMenu()
        showSetupIfFirstLaunch()
    }
    
    private func configureStatusBarMenu() {
        statusItem.button?.image = NSImage(named: "StatusBarIcon")
        statusItem.button?.sendAction(on: NSEvent.EventTypeMask(rawValue: NSEvent.EventTypeMask.RawValue(Int(Float(NSEvent.EventTypeMask.leftMouseDown.rawValue)))))
        statusItem.button?.action = Selector("pressedStatusIcon")
        menu.addItem(currentNetworkItem)
        menu.addItem(infoItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: Selector("showSetupWindow"), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit AutoMute", action: Selector("terminate:"), keyEquivalent: ""))
    }
    
    private func showSetupIfFirstLaunch() {
        if !UserDefaults.standard.bool(forKey: DefaultsKeys.launchedBefore) {
            showSetupWindow()
            UserDefaults.standard.set(true, forKey: DefaultsKeys.launchedBefore)
            UserDefaults.standard.synchronize()
        }
    }
    
    // MARK: Button Handling
    
    func pressedStatusIcon() {
        updateCurrentNetworkItem()
        updateInfoItem()
        statusItem.popUpMenu(menu)
    }
    
    func showSetupWindow() {
        if let visible = windowController?.window?.isVisible, visible {
            NSApp.activate(ignoringOtherApps: true)
        } else {
            windowController = storyboard.instantiateInitialController() as? NSWindowController
            windowController?.showWindow(self)
            windowController?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func updateCurrentNetworkItem() {
        currentNetworkItem.title = "Current wifi network: \(wifiManager.currentNetwork())"
    }
    
    private func updateInfoItem() {
        if let date = lastActionDate {
            let action = wifiManager.currentAction()
            let actionDescription: String
            switch action {
            case .Mute: actionDescription = "Muted volume"
            case .Unmute: actionDescription = "Unmuted volume"
            default: actionDescription = wifiManager.currentNetwork() != NetworkNames.notConnected ? "Last connected" : "Disconnected"
            }
            infoItem.title = "\(actionDescription) \(date.naturalDate)"
        } else {
            infoItem.title = "Connecting to this network will: \(wifiManager.currentAction().description)"
        }
    }
    
    // MARK: WifiManagerDelegate
    
    func performAction(action: Action) {
        lastActionDate = NSDate()
        switch action {
        case .Mute: NSSound.applyMute(true)
        case .Unmute: NSSound.applyMute(false)
        default: break
        }
    }
}

extension NSDate {
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = NSTimeZone.default
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        return formatter
    }()
    
    private static var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var naturalDate: String {
        let dateString = NSDate.dateFormatter.string(from: self as Date)
        if dateString == "Today" {
            return "at \(NSDate.timeFormatter.string(from: self as Date))"
        }
        return "\(dateString) at \(NSDate.timeFormatter.string(from: self as Date))"
    }
}
