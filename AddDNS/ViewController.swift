//
//  ViewController.swift
//  AddDNS
//
//  Created by Yathish on 1/15/17.
//  Copyright © 2017 Yathish. All rights reserved.
//

import UIKit
import Foundation
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
        let manager = NEVPNManager.shared()
        manager.loadFromPreferences { error in
            if let saveError = error {
                NSLog("Error in loading preferences : \(saveError)")
                return
            }
            
            if manager.protocolConfiguration == nil {
                let newIPSec = NEVPNProtocolIPSec()
                newIPSec.username = "Yathish"
                newIPSec.serverAddress = "127.0.0.1"
                newIPSec.passwordReference = self.getPersistanceRef()
                newIPSec.authenticationMethod = NEVPNIKEAuthenticationMethod.sharedSecret
                newIPSec.sharedSecretReference = self.getPersistanceRef()
                newIPSec.useExtendedAuthentication = true
                
                manager.protocolConfiguration = newIPSec
                manager.localizedDescription = "Add DNS"
                
                manager.saveToPreferences(completionHandler: { error in
                    if let saveError = error {
                        NSLog("Error in saving preferences : \(saveError)")
                        return
                    }
                    
                    NSLog("Successfully created a dummy VPN configuration")
                })
                
            }
        }
    }
    
    func getPersistanceRef() -> Data? {

        guard let passwordData = "Password".data(using: String.Encoding.utf8) else { return nil }
        var status = errSecSuccess
        
        let attributes: [AnyHashable: Any] = [
            kSecAttrService as AnyHashable : UUID().uuidString as AnyObject,
            kSecValueData as AnyHashable : passwordData as AnyObject,
            kSecAttrAccessible as AnyHashable : kSecAttrAccessibleAlways,
            kSecClass as AnyHashable : kSecClassGenericPassword,
            kSecReturnPersistentRef as AnyHashable : kCFBooleanTrue
        ]
        
        var result: AnyObject?
        status = SecItemAdd(attributes as CFDictionary, &result)
        
        if let newPersistentReference = result as? Data , status == errSecSuccess {
            return newPersistentReference
        }
        
        return nil
    }
    
    @IBAction func addDNSEntry(_ sender: AnyObject) {
        
        let dns = dnsAddress.text!
        
        let manager = NEVPNManager.shared()
        manager.loadFromPreferences { error in
            if let saveError = error {
                NSLog("Error in loading preferences : \(saveError)")
                return
            }
            
            if manager.protocolConfiguration != nil {
                
                let onDemandRule = NEOnDemandRuleEvaluateConnection()
                let evaluationRule = NEEvaluateConnectionRule(matchDomains: ["*.com"], andAction: .connectIfNeeded)
                evaluationRule.useDNSServers = [dns]
                
                onDemandRule.connectionRules = [evaluationRule]
                onDemandRule.interfaceTypeMatch = NEOnDemandRuleInterfaceType.any   // Rule is applicable to all types of interfaces (WiFI/Cellular)

                manager.onDemandRules = [onDemandRule]
                manager.isOnDemandEnabled = true
                manager.isEnabled = true
                
                NSLog("manager >>> %@", manager)
                print("manager >>> \(manager)")
                
                manager.saveToPreferences(completionHandler: { (error) in
                    if let saveError = error {
                        NSLog("Error in saving the OnDemandRules : \(saveError)")
                        return
                    }
                    
                    NSLog("DNS address \(dns) added to OnDemand Rule : \(onDemandRule)")
                    
                    let alertVC = UIAlertController(title: "Success", message: "DNS address \"\(dns)\" added to WiFi/Cellular settings", preferredStyle: UIAlertControllerStyle.alert)
                    let okButton = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
                    alertVC.addAction(okButton)
                    self.present(alertVC, animated: true, completion: nil)
                })
            }
        }
    }

}

