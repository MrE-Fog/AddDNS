//
//  ViewController.swift
//  AddDNS
//
//  Created by Yathish on 1/15/17.
//  Copyright © 2017 Yathish. All rights reserved.
//

import UIKit
import NetworkExtension

class ViewController: UIViewController {

    @IBOutlet weak var dnsAddress: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.installDummyVPN()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func installDummyVPN() {
        let manager = NEVPNManager.sharedManager()
        manager.loadFromPreferencesWithCompletionHandler { error in
            if let saveError = error {
                NSLog("Error in loading preferences : \(saveError)")
                return
            }
            
            if manager.protocolConfiguration == nil {
                let newIPSec = NEVPNProtocolIPSec()
                newIPSec.serverAddress = "127.0.0.1"
                
                manager.protocolConfiguration = newIPSec
                manager.enabled = true
                
                manager.saveToPreferencesWithCompletionHandler({ error in
                    if let saveError = error {
                        NSLog("Error in saving preferences : \(saveError)")
                        return
                    }
                    
                    NSLog("Successfully created a dummy VPN configuration")
                })
                
            }
        }
    }
    
    @IBAction func addDNSEntry(sender: AnyObject) {
        
        let dns = dnsAddress.text!
        
        let manager = NEVPNManager.sharedManager()
        manager.loadFromPreferencesWithCompletionHandler { error in
            if let saveError = error {
                NSLog("Error in loading preferences : \(saveError)")
                return
            }
            
            if manager.protocolConfiguration != nil {
                
                // Create an OnDemandRule to connect for the array of DNS addresses
                let onDemandRule = NEOnDemandRuleConnect()
                onDemandRule.DNSServerAddressMatch = [dns]
                onDemandRule.interfaceTypeMatch = NEOnDemandRuleInterfaceType.Any   // Rule is applicable to all types of interfaces (WiFI/Cellular)
                
                manager.onDemandRules = [onDemandRule]
                manager.onDemandEnabled = true
                
                manager.saveToPreferencesWithCompletionHandler({ (error) in
                    if let saveError = error {
                        NSLog("Error in saving the OnDemandRules : \(saveError)")
                        return
                    }
                    
                    NSLog("DNS address \(dns) added to OnDemand Rule : \(onDemandRule)")
                    
                    let alertVC = UIAlertController(title: "Success", message: "DNS address \"\(dns)\" added to WiFi/Cellular settings", preferredStyle: UIAlertControllerStyle.Alert)
                    let okButton = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
                    alertVC.addAction(okButton)
                    self.presentViewController(alertVC, animated: true, completion: nil)
                })
            }
        }
    }

}

