//
//  Settings.swift
//  BluetoothSerialPro
//
//  Created by Alex on 24/02/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//

import Foundation

enum NewlineAfter {
    case message
    case count(Int)
    case byte(UInt8)
    case newLine
    
    var id: Int {
        switch self {
        case .message:  return 0
        case .count(_): return 1
        case .byte(_):  return 2
        case .newLine:  return 3
        }
    }
    
    init(id: Int) {
        switch id {
        case 0: self = .message
        case 1: self = .count(Settings.messageSeparationByteCount.value)
        case 2: self = .byte(UInt8(Settings.messageSeparationByte.value))
        case 3: self = .newLine
        default: self = .message
        }
    }
}

enum Mode: Int {
    case console = 0
    case serial = 1
}

enum DisplayStyle: Int {
    case console = 0
    case chatBox = 1
}

class Preset<ValueType> {
    var key: String
    var defaultValue: ValueType
    
    var value: ValueType {
        get { return UserDefaults.standard.value(forKey: key) as! ValueType }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
    
    init(key: String, defaultValue: ValueType) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

class Settings {
    static let scanAllDevices = Preset<Bool>(key: "scanAllDevices", defaultValue: true)
    static let autoReconnect = Preset<Bool>(key: "autoReconnect", defaultValue: false)
    static let autoReconnectUUID = Preset<String>(key: "autoReconnectUUID", defaultValue: "")
    static let serviceUUID = Preset<String>(key: "serviceUUID", defaultValue: "FFE0")
    static private let characteristicUUID = Preset<String>(key: "characteristicUUID", defaultValue: "") // depreciated v1.2.0, leave default empty for correct migration
    static let readCharacteristicUUID = Preset<String>(key: "readCharacteristicUUID", defaultValue: "FFE1")
    static let writeCharacteristicUUID = Preset<String>(key: "writeCharacteristicUUID", defaultValue: "FFE1")

    
    static let appendToInput = Preset<String>(key: "appendToInput", defaultValue: "")
    static let inputFormat = Preset<Int>(key: "inputFormat", defaultValue: String.Format.utf8.rawValue)
    static let autoScroll = Preset<Bool>(key: "autoScroll", defaultValue: true)
    
    static let displayStyle = Preset<Int>(key: "displayStyle", defaultValue: 0)
    static let displayFormat = Preset<Int>(key: "displayFormat", defaultValue: String.Format.utf8.rawValue)
    static let displaySentMessages = Preset<Bool>(key: "displaySentMessages", defaultValue: true)
    static let displayLineNumbers = Preset<Bool>(key: "displayLineNumbers", defaultValue: true)
    static let displayTimeStamps = Preset<Bool>(key: "displayTimeStamps", defaultValue: true)
    static let displayMicroseconds = Preset<Bool>(key: "displayMicroseconds", defaultValue: false)
    static let messageSeparation = Preset<Int>(key: "messageSeparation", defaultValue: 0)
    static let messageSeparationByteCount = Preset<Int>(key: "messageSeparationByteCount", defaultValue: 4)
    static let messageSeparationByte = Preset<Int>(key: "messageSeparationByte", defaultValue: 0)
    
    static let shouldPlaySounds = Preset<Bool>(key: "shouldPlaySounds", defaultValue: true)
    
    static let mode = Preset<Int>(key: "mode", defaultValue: Mode.console.rawValue)
    
    static let maxChunkSize = Preset<Int>(key: "maxChunkSize", defaultValue: 50)
    
    static let buttonsPerRow = Preset<Int>(key: "buttonsPerRow", defaultValue: 0)
    static let buttonSize = Preset<Int>(key: "buttonSize", defaultValue: 0)
    static let appendToFunction = Preset<String>(key: "appendToFunction", defaultValue: "")

    static let sendOnConnect = Preset<Data>(key: "sendOnConnect", defaultValue: Data())
    static let sendOnConnectFormat = Preset<Int>(key: "sendOnConnectFormat", defaultValue: String.Format.hex.rawValue)

    static let isFirstLaunch = Preset<Bool>(key: "isFirstLaunch", defaultValue: true)
    static let lastVersionUpdateInfoShown = Preset<String>(key: "lastVersionUpdateInfoShown", defaultValue: "1.1.1")

    
    class func registerDefaultValues() {
        var defaults = [String: Any]()
        
        defaults.add(scanAllDevices)
        defaults.add(autoReconnect)
        defaults.add(autoReconnectUUID)
        defaults.add(serviceUUID)
        defaults.add(characteristicUUID) // depreciated, only for migration still here
        defaults.add(readCharacteristicUUID)
        defaults.add(writeCharacteristicUUID)
        
        defaults.add(appendToInput)
        defaults.add(inputFormat)
        defaults.add(autoScroll)
        
        defaults.add(displayStyle)
        defaults.add(displayFormat)
        defaults.add(displaySentMessages)
        defaults.add(displayLineNumbers)
        defaults.add(displayTimeStamps)
        defaults.add(displayMicroseconds)
        defaults.add(messageSeparation)
        defaults.add(messageSeparationByteCount)
        defaults.add(messageSeparationByte)
        
        defaults.add(shouldPlaySounds)
        
        defaults.add(mode)
        
        defaults.add(maxChunkSize)
        
        defaults.add(buttonsPerRow)
        defaults.add(buttonSize)
        defaults.add(appendToFunction)
        
        defaults.add(sendOnConnect)
        defaults.add(sendOnConnectFormat)
        
        defaults.add(isFirstLaunch)
        defaults.add(lastVersionUpdateInfoShown)
        
        UserDefaults.standard.register(defaults: defaults)
    }
    
    class func migrateToLatest() {
        // upgrade from 1.1.1 to 1.2.0+: replacing charUUID with read+writeUUID
        if characteristicUUID.value != "" && characteristicUUID.value != "FFE1" {
            readCharacteristicUUID.value = characteristicUUID.value
            writeCharacteristicUUID.value = characteristicUUID.value
            characteristicUUID.value = ""
        }
    }
}

fileprivate extension Dictionary where Key == String, Value == Any {
    mutating func add<T>(_ preset: Preset<T>) {
        self[preset.key] = preset.defaultValue
    }
}
