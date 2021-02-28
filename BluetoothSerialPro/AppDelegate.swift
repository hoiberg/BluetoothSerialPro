//
//  AppDelegate.swift
//  BluetoothSerialPro
//
//  Created by Alex on 27/11/2016.
//  Copyright © 2016 Hangar42. All rights reserved.
//
//  • RappleActivityIndicatorView is aangepast voor touch selector!
//  • iCloud is toegevoegd voor gebruik UIDocumentPickerViewController
//
// TODO's:
// v Bubble shape
// v Sounds
// v Input chars allowed
// v Finals overal ? Cell leading margin
// v Chunking-up
// v Function Selection cell
// v App Info / Feedback
// x Function collectioncell reorder
// x Function with/without response
// x NMEA String
// v Scan reset om de seconde voor als peripherals weg gaan..
// v BLE Device info's
// v Function lighter color
// v Loading animation
// v RSSI indicator
// v Share Sheet
// v Analysis RSSI
// v Auto Write with/without response
// v Scan 'connectable' ad info
// v Button Function UI
// v Dismiss keyboard tap events
// v iPhone orientation changes
// v Segments icons bij iphone
// - Testen segments displayoptions iphone5
//
//
// Before Release:
// - Update info text (every minor release)
//
//
// Version 1.2.0
// > Function append \n\r in function settings
// > Separate UUID settings for read/write (test!)
// > Auto Reconnect
// > Clear Element function
// > Import/Export functions

// TODO: Update info text!!!

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        Settings.registerDefaultValues()
        Settings.migrateToLatest()
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // note: there's a copy of this in the function options screen

        func importFunctions(replace: Bool) {
            do {
                // try to load & save (takes care of migration too)
                let imported = try JSON.loadFunctions(url: url)
                
                if replace {
                    try JSON.saveFunctions(imported)
                } else {
                    let existing = try JSON.loadFunctions()
                    var i = existing.count
                    imported.forEach { $0.order = i; i += 1; }
                    try JSON.saveFunctions(existing + imported)
                }
                
                let alert = UIAlertController(title: "Success", message: "Imported \(imported.count) Functions", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                present(alert, animated: true)
                
                NotificationCenter.default.post(name: .functionsChanged)
            } catch {
                print("Failed to import: \(error.localizedDescription)")
                let alert = UIAlertController(title: "Failed to load functions", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                present(alert, animated: true)
            }
        }
        
        func add(_: UIAlertAction) {
            importFunctions(replace: false)
        }
        func replace(_: UIAlertAction) {
            importFunctions(replace: true)
        }
        
        // create alert
        let alert = UIAlertController(title: "Import Functions", message: "Add to existing functions or replace all? This cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: add))
        alert.addAction(UIAlertAction(title: "Replace", style: .destructive, handler: replace))
        
        // present
        present(alert, animated: true)

        return true
    }
    
    private func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        // create temporary window, will be deallocated automatcially after dismissal
        let tempWindow = UIWindow(frame: UIScreen.main.bounds)
        tempWindow.rootViewController = UIViewController()
        tempWindow.windowLevel = UIWindowLevelAlert + 1
        tempWindow.makeKeyAndVisible() // TODO: Attempting to load the view of a view controller while it is deallocating is not allowed and may result in undefined behavior
        
        // present
        tempWindow.rootViewController?.present(viewController, animated: true, completion: completion)
    }

}
