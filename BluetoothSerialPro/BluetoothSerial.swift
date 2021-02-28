//
//  BluetoothSerial.swift (originally DZBluetoothSerialHandler.swift)
//  HM10 Serial
//
//  Created by Alex on 09-08-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//
//  IMPORTANT: Don't forget to set the variable 'writeType' or else the whole thing might not work.
//

import UIKit
import CoreBluetooth

/// Global serial handler, don't forget to initialize it with init(delgate:)
var serial: BluetoothSerial!

// Delegate functions
protocol BluetoothSerialDelegate {
    // ** Required **
    
    /// Called when de state of the CBCentralManager changes (e.g. when bluetooth is turned on/off)
    func serialDidChangeState()
    
    // ** Optionals **
    
    /// Called when a peripheral disconnected
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: Error?)
    
    /// Called when a message is received
    func serialDidReceiveString(_ message: String)
    
    /// Called when a message is received
    func serialDidReceiveBytes(_ bytes: [UInt8])
    
    /// Called when a message is received
    func serialDidReceiveData(_ data: Data)
    
    /// Called when the RSSI of the connected peripheral is read
    func serialDidReadRSSI(_ rssi: NSNumber)
    
    /// Called when a new peripheral is discovered while scanning. Also gives the RSSI (signal strength)
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: [String : Any]?, RSSI: NSNumber?)
    
    /// Called when a peripheral is connected (but not yet ready for cummunication)
    func serialDidConnect(_ peripheral: CBPeripheral)
    
    /// Called when a pending connection failed
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: Error?)
    
    /// Called when a peripheral is ready for communication
    func serialIsReady(_ peripheral: CBPeripheral)
}

// Make some of the delegate functions optional
extension BluetoothSerialDelegate {
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: Error?) {}
    func serialDidReceiveString(_ message: String) {}
    func serialDidReceiveBytes(_ bytes: [UInt8]) {}
    func serialDidReceiveData(_ data: Data) {}
    func serialDidReadRSSI(_ rssi: NSNumber) {}
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: [String : Any]?, RSSI: NSNumber?) {}
    func serialDidConnect(_ peripheral: CBPeripheral) {}
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: Error?) {}
    func serialIsReady(_ peripheral: CBPeripheral) {}
}


class BluetoothSerial: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Variables
    
    /// The delegate object the BluetoothDelegate methods will be called upon
    var delegate: BluetoothSerialDelegate!
    
    /// The CBCentralManager this bluetooth serial handler uses for... well, everything really // better weak?
    var centralManager: CBCentralManager!
    
    /// The peripheral we're trying to connect to (nil if none)
    var pendingPeripheral: CBPeripheral?
    
    /// The connected peripheral (nil if none is connected)
    var connectedPeripheral: CBPeripheral?
    
    /// The characteristic we need to write to, of the connectedPeripheral
    weak var writeCharacteristic: CBCharacteristic?
    
    /// Whether this serial is ready to send and receive data
    var isReady: Bool {
        get {
            return centralManager.state == .poweredOn &&
                connectedPeripheral != nil &&
                writeCharacteristic != nil
        }
    }
    
    var isScanning: Bool {
        return centralManager.isScanning
    }
    
    /// UUID of the service to look for.
    var serviceUUID = CBUUID(string: "FFE0")
    
    /// UUID of the read characteristic to look for.
    var readCharacteristicUUID = CBUUID(string: "FFE1")
    
    /// UUID of the write characteristic to look for.
    var writeCharacteristicUUID = CBUUID(string: "FFE1")
    
    /// Max size of messages sent
    var maxChunkSize = 50
    
    /// Buffer of data to be sent
    private var buffer = Data()
    
    /// Time interval between chunks of max size (seconds)
    private let chunkInterval = 0.2
    
    /// Time next chunk may be sent
    private var nextChunkTime = Date()
    
    /// Required Write Type (selected automatically)
    private var writeType = CBCharacteristicWriteType.withoutResponse
    
    
    //MARK: - Functions
    
    /// Always use this to initialize an instance
    init(delegate: BluetoothSerialDelegate) {
        super.init()
        self.delegate = delegate
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Start scanning for peripherals
    func startScan() {
        guard centralManager.state == .poweredOn else { return }
        
        // start scanning for peripherals with correct service UUID
        let options = [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        let uuids: [CBUUID]? = Settings.scanAllDevices.value ? nil : [serviceUUID]
        centralManager.scanForPeripherals(withServices: uuids, options: options)
        
        // retrieve peripherals that are already connected
        // see this stackoverflow question http://stackoverflow.com/questions/13286487
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])
        for peripheral in peripherals {
            delegate.serialDidDiscoverPeripheral(peripheral, advertisementData: nil, RSSI: nil)
        }
    }
    
    /// Stop scanning for peripherals
    func stopScan() {
        centralManager.stopScan()
    }
    
    /// Try to connect to the given peripheral
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        pendingPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    /// Disconnect from the connected peripheral or stop connecting to it
    func disconnect() {
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
        } else if let p = pendingPeripheral {
            centralManager.cancelPeripheralConnection(p) //TODO: Test whether its neccesary to set p to nil
        }
    }
    
    /// The didReadRSSI delegate function will be called after calling this function
    func readRSSI() {
        guard isReady else { return }
        connectedPeripheral!.readRSSI()
    }
    
    /// Send a string to the device
    func sendMessageToDevice(_ message: String) {
        guard isReady else { return }
        
        if let data = message.data(using: String.Encoding.utf8) {
            addToBuffer(data)
        }
    }
    
    /// Send an array of bytes to the device
    func sendBytesToDevice(_ bytes: [UInt8]) {
        guard isReady else { return }
        
        let data = Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        addToBuffer(data)
    }
    
    /// Send data to the device
    func sendDataToDevice(_ data: Data) {
        guard isReady else { return }
        
        addToBuffer(data)
    }
    
    private func addToBuffer(_ data: Data) {
        buffer.append(data)
        
        if nextChunkTime < Date() {
            sendNextChunk()
        }
    }
    
    private func sendNextChunk() {
        guard isReady else { return }
        let willBeLast = buffer.count <= maxChunkSize
        let start = buffer.startIndex
        let end = buffer.endIndex
        let chunkEnd = willBeLast ? end : start.advanced(by: maxChunkSize)
        let chunk = buffer.subdata(in: start..<chunkEnd)
        let newBuffer = willBeLast ? Data() : buffer.subdata(in: chunkEnd..<end)
        
        buffer = newBuffer
        
        connectedPeripheral!.writeValue(chunk, for: writeCharacteristic!, type: writeType)
        
        if !buffer.isEmpty {
            nextChunkTime = Date.init(timeIntervalSinceNow: chunkInterval)
            delay(seconds: chunkInterval, callback: sendNextChunk)
        }
    }
    
    
    // MARK: - CBCentralManager Delegate
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // just send it to the delegate
        delegate.serialDidDiscoverPeripheral(peripheral, advertisementData: advertisementData, RSSI: RSSI)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // set some stuff right
        peripheral.delegate = self
        pendingPeripheral = nil
        connectedPeripheral = peripheral
        
        // send it to the delegate
        delegate.serialDidConnect(peripheral)
        
        // Okay, the peripheral is connected but we're not ready yet!
        // First get the 0xFFE0 service
        // Then get the 0xFFE1 characteristic of this service
        // Subscribe to it & create a weak reference to it (for writing later on),
        // and then we're ready for communication
        
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        pendingPeripheral = nil
        
        // send it to the delegate
        delegate.serialDidDisconnect(peripheral, error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        pendingPeripheral = nil
        
        // just send it to the delegate
        delegate.serialDidFailToConnect(peripheral, error: error)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // note that "didDisconnectPeripheral" won't be called if BLE is turned off while connected
        connectedPeripheral = nil
        pendingPeripheral = nil
        
        // send it to the delegate
        delegate.serialDidChangeState()
    }
    
    
    // MARK: - CBPeripheral Delegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // discover the 0xFFE1 characteristic for all services (though there should only be one)
        for service in peripheral.services! {
            peripheral.discoverCharacteristics([readCharacteristicUUID, writeCharacteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        var foundRead = false
        var foundWrite = false
        
        // check whether the characteristics we're looking for are present - just to be sure
        for characteristic in service.characteristics! {
            if characteristic.uuid == readCharacteristicUUID {
                foundRead = true
                
                // subscribe to this value (so we'll get notified when there is serial data for us..)
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            if characteristic.uuid == writeCharacteristicUUID {
                foundWrite = true
                
                // find out how to write to this characteristic
                writeType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                
                // keep a reference to this characteristic so we can write to it
                writeCharacteristic = characteristic
            }
        }
        
        if foundRead && foundWrite {
            // notify the delegate we're ready for communication
            delegate.serialIsReady(peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // notify the delegate in different ways
        // if you don't use one of these, just comment it (for optimum efficiency :])
        let data = characteristic.value
        guard data != nil && !data!.isEmpty else { return }
        
        // first the data
        delegate.serialDidReceiveData(data!)
        
        // then the string
        //if let str = String(data: data!, encoding: String.Encoding.utf8) {
        //    delegate.serialDidReceiveString(str)
        //} else {
        //    //print("Received an invalid string!") uncomment for debugging
        //}
        
        // now the bytes array
        //var bytes = [UInt8](repeating: 0, count: data!.count / MemoryLayout<UInt8>.size)
        //(data! as NSData).getBytes(&bytes, length: data!.count)
        //delegate.serialDidReceiveBytes(bytes)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        delegate.serialDidReadRSSI(RSSI)
    }
}
