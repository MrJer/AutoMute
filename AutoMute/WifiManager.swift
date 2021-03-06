//
//  WifiManager.swift
//  AutoMute
//
//  Created by Lorenzo Gentile on 2015-08-31.
//  Copyright © 2015 Lorenzo Gentile. All rights reserved.
//

import Foundation
import CoreWLAN

protocol WifiManagerDelegate: class {
    func performAction(action: Action)
}

class WifiManager: NSObject {
    private let wifiInterface = CWWiFiClient.shared().interface()
    private var lastSSID: String?
    weak var delegate: WifiManagerDelegate?
    static var networks = WifiManager.getUsedNetworks()
    private var dropCounter: Int?
    
    override init() {
        lastSSID = UserDefaults.standard.value(forKey: DefaultsKeys.lastSSID) as? String
    }
    
    // Retrieves network info from the user's preferences, returns only the networks that have been connected to and sorted by date last used
    // Also checks user defaults for the actions associated to that network and adds it as a property to the preferences
    private class func getUsedNetworks() -> [[String: AnyObject]] {
        var usedNetworks: [[String: AnyObject]] = [notConnectedWifiDictionary()]
        let airportPreferences = NSDictionary(contentsOfFile: Paths.airportPreferences) as? [String: AnyObject]
        guard let knownNetworks = airportPreferences?[NetworkKeys.knownNetworks] as? [String: AnyObject] else { return usedNetworks }
        for (_, object) in knownNetworks {
            if var network = object as? [String: AnyObject], let ssid = network[NetworkKeys.ssid] as? String {
                if network[NetworkKeys.lastConnected] != nil {
                    let action = UserDefaults.standard.object(forKey: ssid) as? Int ?? Action.DoNothing.rawValue
                    network[NetworkKeys.action] = action as AnyObject
                    usedNetworks += [network]
                }
            }
        }
        usedNetworks.sort { (first, second) -> Bool in
            if let firstDate = first[NetworkKeys.lastConnected] as? NSDate, let secondDate = second[NetworkKeys.lastConnected] as? NSDate {
                return firstDate.compare(secondDate as Date) == ComparisonResult.orderedDescending
            }
            return true
        }
        return usedNetworks
    }
    
    private class func notConnectedWifiDictionary() -> [String: AnyObject] {
        let ssid = NetworkNames.notConnectedDisplayName
        return [NetworkKeys.ssid: ssid as AnyObject,
                NetworkKeys.lastConnected: NSDate.distantFuture as AnyObject,
            NetworkKeys.action: (UserDefaults.standard.object(forKey: ssid) as? Int ?? Action.DoNothing.rawValue) as AnyObject]
    }
    
    class func updateActionForNetwork(action: Int, index: Int) {
        WifiManager.networks[index][NetworkKeys.action] = action as AnyObject
        if let ssid = WifiManager.networks[index][NetworkKeys.ssid] as? String {
            UserDefaults.standard.setValue(action, forKey: ssid)
            UserDefaults.standard.synchronize()
        }
    }
    
    func currentNetwork() -> String {
        return lastSSID ?? NetworkNames.notConnected
    }
    
    func currentAction() -> Action {
        var network = currentNetwork()
        if network == NetworkNames.notConnected {
            network = NetworkNames.notConnectedDisplayName
        }
        if let action = UserDefaults.standard.object(forKey: network) as? Int {
            return Action(rawValue: action) ?? Action.DoNothing
        }
        return Action.DoNothing
    }
    
    // MARK: Scanning current network
    
    func startWifiScanning() {
        checkSSID()
        let ssidTimer = Timer(timeInterval: Constants.wifiCheckTimeInterval, target: self, selector: Selector(("checkSSID")), userInfo: nil, repeats: true)
        RunLoop.main.add(ssidTimer, forMode: RunLoop.Mode.common)
    }
    
    func checkSSID() {
        let ssid = wifiInterface?.ssid()
        func updateSSID() {
            lastSSID = ssid
            delegate?.performAction(action: currentAction())
            UserDefaults.standard.setValue(lastSSID, forKey: DefaultsKeys.lastSSID)
            UserDefaults.standard.synchronize()
            dropCounter = nil
        }
        
        if lastSSID != ssid {
            if ssid != nil {
                updateSSID()
            } else {
                if let wifiIsOn = wifiInterface?.powerOn(), !wifiIsOn {
                    // Wifi got turned off, proceed normally
                    updateSSID()
                } else {
                    // Wifi got disconnected, add a counter to make sure it's not a quick drop
                    if let dc = dropCounter {
                        if dc == 0 {
                            updateSSID()
                        } else {
                            dropCounter = dc - 1
                        }
                    } else {
                        dropCounter = Constants.dropCounter
                    }
                }
            }
        } else {
            dropCounter = nil
        }
    }
}
