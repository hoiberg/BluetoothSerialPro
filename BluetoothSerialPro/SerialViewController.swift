//
//  SerialViewController.swift
//  BluetoothSerialPro
//
//  Created by Alex on 27/11/2016.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit

class SerialViewController: UIViewController {
    
    // MARK: - Outlets

    @IBOutlet weak var segments: UISegmentedControl!
    
    
    // MARK: - Variables
    
    var mode = Mode.console
    var consoleViewController: ConsoleViewController!
    var functionsViewController: FunctionsViewController!
    var disconnectWasUserTriggered = false
    
    // MARK: - ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(disconnected), name: .disconnected)
        
        segments.selectedSegmentIndex = Settings.mode.value
        
        let sWidth = UIScreen.main.bounds.width
        let sHeight = UIScreen.main.bounds.height
        if sqrt(pow(sWidth, 2)+pow(sHeight, 2)) < 660 { // 4 inch = 652pt diagonal
            segments.setTitle(nil, forSegmentAt: 0) // used in DisplayOptions too
            segments.setTitle(nil, forSegmentAt: 1)
            segments.setImage(#imageLiteral(resourceName: "Console"), forSegmentAt: 0)
            segments.setImage(#imageLiteral(resourceName: "Actions"), forSegmentAt: 1)
        }
        
        if UIDevice.isPhone {
            // replace alerts and share button with actions button
            navigationItem.rightBarButtonItems!.removeAll {
                $0.tag == 1
            }
            
            let actionButton = UIBarButtonItem(image: UIImage(named: "Actions"), style: .plain, target: self, action: #selector(share(_:)))
            navigationItem.rightBarButtonItems?.insert(actionButton, at: 0)
        }

        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)

        consoleViewController = storyboard.instantiateViewController(withIdentifier: "ConsoleViewController") as! ConsoleViewController
        consoleViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(consoleViewController)
        view.addSubview(consoleViewController.view)
        
        let v = consoleViewController.view!
        let hc = NSLayoutConstraint(item: v, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1.0, constant: 0)
        let wc = NSLayoutConstraint(item: v, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1.0, constant: 0)
        let xc = NSLayoutConstraint(item: v, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0)
        let yc = NSLayoutConstraint(item: v, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0)
        view.addConstraints([hc, wc, xc, yc])
        consoleViewController.didMove(toParentViewController: self)
        
        functionsViewController = storyboard.instantiateViewController(withIdentifier: "FunctionsViewController") as! FunctionsViewController
        functionsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(functionsViewController)
        view.addSubview(functionsViewController.view)
        
        let fv = functionsViewController.view!
        let fhc = NSLayoutConstraint(item: fv, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1.0, constant: 0)
        let fwc = NSLayoutConstraint(item: fv, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1.0, constant: 0)
        let fxc = NSLayoutConstraint(item: fv, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0)
        let fyc = NSLayoutConstraint(item: fv, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0)
        view.addConstraints([fhc, fwc, fxc, fyc])
        functionsViewController.didMove(toParentViewController: self)

        reload()
    }
        
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    @objc func disconnected() {
        performSegue(withIdentifier: "unwindToScan", sender: self)
    }
    
    func reload() {
        mode = Mode(rawValue: Settings.mode.value)!
        if mode == .console {
            view.bringSubview(toFront: consoleViewController.view)
            consoleViewController.view.isHidden = false
            functionsViewController.view.isHidden = true
        } else {
            view.bringSubview(toFront: functionsViewController.view)
            functionsViewController.view.isHidden = false
            consoleViewController.view.isHidden = true
            consoleViewController.view.endEditing(true)
        }
    }
    

    // MARK: - Actions
    
    @IBAction func changeMode(_ sender: Any) {
        Settings.mode.value = segments.selectedSegmentIndex
        reload()
    }

    @IBAction func clearScreen(_ sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Clear Screen", style: .destructive) { _ in
                NotificationCenter.default.post(name: .clearScreen)
            })
        if UIDevice.isPhone {
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                self.dismiss(animated: true, completion: nil)
            })
        }
        sheet.popoverPresentationController?.barButtonItem = sender
        sheet.popoverPresentationController?.permittedArrowDirections = .up
        present(sheet, animated: true)
    }
    
    @IBAction func share(_ sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if UIDevice.isPhone {
            sheet.addAction(UIAlertAction(title: "Edit Alerts", style: .default) { _ in
                self.performSegue(withIdentifier: "showEditAlerts", sender: self)
            })
        }

        sheet.addAction(UIAlertAction(title: UIDevice.isPhone ? "Export Plain Text" : "Plain Text", style: .default) { _ in
            let activityView = UIActivityViewController(activityItems: [self.consoleViewController.textView.text], applicationActivities: nil)
            activityView.popoverPresentationController?.barButtonItem = sender
            activityView.popoverPresentationController?.permittedArrowDirections = .up
            self.present(activityView, animated: true)
        })
        
        sheet.addAction(UIAlertAction(title: UIDevice.isPhone ? "Export Attributed Text" : "Attributed Text", style: .default) { _ in
            let activityView = UIActivityViewController(activityItems: [self.consoleViewController.textView.attributedText], applicationActivities: nil)
            activityView.popoverPresentationController?.barButtonItem = sender
            activityView.popoverPresentationController?.permittedArrowDirections = .up
            self.present(activityView, animated: true)
        })
        
        if UIDevice.isPhone {
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                self.dismiss(animated: true)
            })
        }
        
        sheet.popoverPresentationController?.barButtonItem = sender
        sheet.popoverPresentationController?.permittedArrowDirections = .up
        present(sheet, animated: true)
    }
    
    @IBAction func alerts(_ sender: Any) {
        performSegue(withIdentifier: "showEditAlerts", sender: self)
    }
    
    @IBAction func options(_ sender: Any) {
        if mode == .console {
            performSegue(withIdentifier: "showDisplayOptions", sender: self)
        } else {
            performSegue(withIdentifier: "showEditFunctions", sender: self)
        }
    }
    
    @IBAction func disconnect(_ sender: Any) {
        disconnectWasUserTriggered = true
        serial.disconnect()
    }
}
