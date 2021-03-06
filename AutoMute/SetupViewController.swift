//
//  SetupViewController.swift
//  AutoMute
//
//  Created by Lorenzo Gentile on 2015-08-30.
//  Copyright © 2015 Lorenzo Gentile. All rights reserved.
//

import Cocoa

class SetupViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var tableView: NSTableView!
    
    // MARK: NSTableViewDataSource
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return WifiManager.networks.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        if tableColumn?.identifier.rawValue == ColumnIds.network {
            return WifiManager.networks[row][NetworkKeys.ssid]
        } else if tableColumn?.identifier.rawValue == ColumnIds.action {
            if let action = WifiManager.networks[row][NetworkKeys.action] as? Int, action == -1 {
                WifiManager.networks[row][NetworkKeys.action] = Action.DoNothing.rawValue as AnyObject
            }
            return WifiManager.networks[row][NetworkKeys.action]
        }
        return nil
    }
    
    func tableView(tableView: NSTableView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, row: Int) {
        if let selectedSegment = object as? Int, tableColumn?.identifier.rawValue == ColumnIds.action {
            WifiManager.updateActionForNetwork(action: selectedSegment, index: row)
        }
    }
    
    // MARK: NSTableViewDelegate
    
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
    
    func tableView(tableView: NSTableView, shouldTrackCell cell: NSCell, forTableColumn tableColumn: NSTableColumn?, row: Int) -> Bool {
        return true
    }
}
