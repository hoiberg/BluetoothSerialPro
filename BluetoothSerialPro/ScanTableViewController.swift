//
//  ScannerTableViewController.swift
//  BluetoothSerialPro
//
//  Created by Alex on 27/11/2016.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit
import CoreBluetooth

class ScanTableViewController: UITableViewController, BluetoothSerialDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    // MARK: - Variables
    
    let codeAttributes = [NSAttributedStringKey.font: UIFont(name: "Menlo-Regular", size: 12)!]
    let plainAttributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12)]
    
    var peripherals = [(peripheral: CBPeripheral, ad: [String: Any]?, RSSI: NSNumber?, lastUpdate: Date?)]()
    var inactivityTimer: Timer?
    var connectionID: UInt32 = 0
    var lastUserTriggeredDisconnect: Date?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    
    // MARK: - ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
      /*  let fileManager = FileManager.default
        var documentsURL = URL(string: "/System/Library/Audio/UISounds/")!
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            print(fileURLs)
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
        
        documentsURL = URL(string: "/System/Library/Audio/UISounds/nano/")!
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            print(fileURLs)
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
        
        documentsURL = URL(string: "/System/Library/Audio/UISounds/new/")!
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            print(fileURLs)
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
        
        documentsURL = URL(string: "/System/Library/Audio/UISounds/modern/")!
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            print(fileURLs)
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }

*/


        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: .UIApplicationWillEnterForeground)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: .UIApplicationWillResignActive)
        NotificationCenter.default.addObserver(self, selector: #selector(settingsChanged), name: .settingsChanged)
        NotificationCenter.default.addObserver(self, selector: #selector(activityIndicatorTouch), name: .activityIndicatorViewTouch)
        
        setNeedsStatusBarAppearanceUpdate()
        
        serial = BluetoothSerial(delegate: self)
        serial.serviceUUID = CBUUID(string: Settings.serviceUUID.value)
        serial.readCharacteristicUUID = CBUUID(string: Settings.readCharacteristicUUID.value)
        serial.writeCharacteristicUUID = CBUUID(string: Settings.writeCharacteristicUUID.value)
        serial.startScan() // TODO: Start inactivityTimer ?????
        
        tableView.contentInset.top = -36
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // show update info for every new minor version (1.x.0)
        let bundleVersion = Version(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)
        let lastVersion = Version(Settings.lastVersionUpdateInfoShown.value)
        
        // TODO: Will show on first launch, no solution as of yet :(
        if /*!Settings.isFirstLaunch.value && <- won't work in 1.2.0 because isFirstLaunch will always be true*/
           (bundleVersion.major > lastVersion.major || bundleVersion.minor > lastVersion.minor) {
            performSegue(withIdentifier: "showUpdateInfo", sender: self)
        }
        
        Settings.isFirstLaunch.value = false
        Settings.lastVersionUpdateInfoShown.value = bundleVersion.stringValue // here to prevent showing at 2nd launch
    }
        
    @objc func appWillEnterForeground() {
        if navigationController!.topViewController == self {
            serialDidChangeState()
        }
    }
    
    @objc func appWillResignActive() {
        serialDidChangeState()
    }
    
    @objc func settingsChanged() {
        serial.serviceUUID = CBUUID(string: Settings.serviceUUID.value)
        serial.readCharacteristicUUID = CBUUID(string: Settings.readCharacteristicUUID.value)
        serial.writeCharacteristicUUID = CBUUID(string: Settings.writeCharacteristicUUID.value)

        if serial.isScanning {
            peripherals = []
            tableView.reloadData()
            serial.stopScan()
            serial.startScan()
        }
    }
    
    @objc func activityIndicatorTouch() {
        serial.disconnect()
        RappleActivityIndicatorView.stopAnimation()
    }
    
    @objc func inactivityCheck() {
        for i in (0..<peripherals.count).reversed() {
            if peripherals[i].RSSI != nil && peripherals[i].lastUpdate!.timeIntervalSinceNow < -2 {
                peripherals.remove(at: i)
                tableView.reloadData()
            }
        }
    }

    // MARK: - BluetoothSerial
    
    func serialDidChangeState() {
        if serial.centralManager.state != .poweredOn || UIApplication.shared.applicationState == .background {
            if RappleActivityIndicatorView.isVisible() {
                RappleActivityIndicatorView.stopAnimation(completionIndicator: .failed, completionLabel: "¯\\_(ツ)_/¯", completionTimeout: 1.0)
            }
            statusLabel.text = "Bluetooth Disabled"
            activityIndicator.stopAnimating()
            peripherals = []
            tableView.reloadData()
            inactivityTimer?.invalidate()
        } else {
            statusLabel.text = "Scanning..."
            activityIndicator.startAnimating()
            peripherals = []
            tableView.reloadData()
            serial.stopScan()
            serial.startScan()
            inactivityTimer?.invalidate()
            inactivityTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(inactivityCheck), userInfo: nil, repeats: true)
        }
    }
    
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: [String : Any]?, RSSI: NSNumber?) {
        if let i = peripherals.index(where: ({ $0.peripheral === peripheral })) {
            peripherals[i].ad = advertisementData
            peripherals[i].RSSI = RSSI
            peripherals[i].lastUpdate = Date()
            tableView.reloadData()
        } else {
            // this part will be triggered after each serialDidChange() call
            // (NOT only on the actual first discovery)
            peripherals.append((peripheral, advertisementData, RSSI, Date()))
            peripherals.sort { ($0.RSSI?.floatValue ?? 0) > ($1.RSSI?.floatValue ?? 0) }
            tableView.reloadData()
            
            // don't reconnect immediately after disconnecting
            if (lastUserTriggeredDisconnect == nil || Date().timeIntervalSince(lastUserTriggeredDisconnect!) > 1) &&
               Settings.autoReconnect.value &&
               Settings.autoReconnectUUID.value.count > 0 &&
               UUID(uuidString: Settings.autoReconnectUUID.value) == peripheral.identifier &&
               presentedViewController == nil {
                let index = peripherals.index { $0.peripheral === peripheral }
                let indexPath = IndexPath(row: index!, section: 0)
                self.tableView(tableView, didSelectRowAt: indexPath)
            }
        }
    }
    
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: Error?) {
        if RappleActivityIndicatorView.isVisible() {
            RappleActivityIndicatorView.stopAnimation(completionIndicator: .failed, completionLabel: "Failed", completionTimeout: 2.0)
        }
        
        serialDidChangeState()
        
        if let err = error {
            print("Failed to Connect: \(err.localizedDescription)")
        }
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: Error?) {
        serialDidFailToConnect(peripheral, error: error)
    }
    
    func serialIsReady(_ peripheral: CBPeripheral) {
        RappleActivityIndicatorView.stopAnimation()
        performSegue(withIdentifier: "ShowSerial", sender: self)
    }
    
    
    // MARK: - TableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "peripheralCell", for: indexPath),
            peripheral = peripherals[indexPath.row]
        
        let attributedString = NSMutableAttributedString(string: "")
        
        let servicesPlain = NSAttributedString(string: "Services: ", attributes: plainAttributes)
        attributedString.append(servicesPlain)

        var serviceUUIDsString = ""
        if let ad = peripheral.ad {
            if let uuids = ad[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                uuids.forEach {
                    serviceUUIDsString += /*"0x" +*/ $0.uuidString + " "
                }
            } else {
                serviceUUIDsString = "nil"
            }
        } else {
            if let services = peripheral.peripheral.services {
                services.forEach {
                    serviceUUIDsString += /*"0x" +*/ $0.uuid.uuidString + " "
                }
            } else {
                serviceUUIDsString = "nil"
            }
        }
        
        let serviceCode = NSAttributedString(string: serviceUUIDsString, attributes: codeAttributes)
        attributedString.append(serviceCode)
        
        let manPlain = NSAttributedString(string: "\nManufacturer: ", attributes: plainAttributes)
        attributedString.append(manPlain)

        var manCodeString = ""
        if let ad = peripheral.ad {
            if let man = ad[CBAdvertisementDataManufacturerDataKey] as? Data {
                manCodeString = "0x"
                man.forEach {
                    manCodeString += $0.string(withFormat: .hex)
                }
            } else {
                manCodeString = "nil"
            }
        } else {
            manCodeString = "nil"
        }
        
        let manCode = NSAttributedString(string: manCodeString, attributes: codeAttributes)
        attributedString.append(manCode)
        
        let rssiPlain = NSAttributedString(string: "\nRSSI: ", attributes: plainAttributes)
        attributedString.append(rssiPlain)
        
        var rssiCodeString = ""
        if let rssi = peripheral.RSSI {
            rssiCodeString = "\(rssi.intValue)dB"
        } else {
            rssiCodeString = "nil"
        }
        
        let rssiCode = NSAttributedString(string: rssiCodeString, attributes: codeAttributes)
        attributedString.append(rssiCode)
        
        (cell.viewWithTag(2) as! UILabel).text = peripheral.peripheral.name ?? ((peripheral.ad?[CBAdvertisementDataLocalNameKey] as? String) ?? "Unidentified")
        (cell.viewWithTag(3) as! UILabel).attributedText = attributedString
        (cell.viewWithTag(4) as! UIImageView).isHidden = (peripheral.ad?[CBAdvertisementDataIsConnectable] as? Bool) ?? true
        
        let indicator = cell.viewWithTag(1) as! RSSIIndicatorView
        let rssi = peripheral.RSSI?.intValue ?? -100 // from -100 (low) to -40 (high)
        indicator.currentLevel = CGFloat(ceil((Double(rssi+100) / 60.0) * Double(indicator.numberOfBars)))

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        inactivityTimer?.invalidate()
        serial.stopScan()
        serial.connectToPeripheral(peripherals[indexPath.row].peripheral)
        RappleActivityIndicatorView.startAnimatingWithLabel("Connecting...", attributes: RappleModernAttributes)
        
        connectionID = arc4random()
        let thisConnectionID = connectionID
        delay(seconds: 5) {
            guard !serial.isReady && self.connectionID == thisConnectionID else { return }
            RappleActivityIndicatorView.stopAnimation(completionIndicator: .incomplete, completionLabel: "Timeout", completionTimeout: 2.0)
            serial.disconnect()
        }
        
        //if Settings.autoReconnect.value {
            Settings.autoReconnectUUID.value = peripherals[indexPath.row].peripheral.identifier.uuidString
        //}
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "showAnalysis" {
            inactivityTimer?.invalidate()
            serial.stopScan()
            let nv = segue.destination as! UINavigationController
            let vc = nv.viewControllers.first as! DeviceAnalysisTableViewController
            let pr = peripherals[tableView.indexPath(for: sender as! UITableViewCell)!.row]
            vc.peripheral = pr.peripheral
            vc.advertisementDataDict = pr.ad
        }
    }
    
    @IBAction func unwindToScan(_ segue: UIStoryboardSegue) {
        if let source = segue.source as? SerialViewController, source.disconnectWasUserTriggered {
            lastUserTriggeredDisconnect = Date()
        }
        
        serial.delegate = self
        serialDidChangeState()
    }
}
