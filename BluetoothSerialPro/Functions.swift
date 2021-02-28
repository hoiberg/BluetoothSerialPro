//
//  Functions.swift
//  BluetoothSerialPro
//
//  Created by Alex on 03/03/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//
//  Version 2:
//      - Addition of "format" value to ButtonFunction and "onFormat" + "offFormat"
//        to SwitchFunction (backwards-compatible)
//      - Addition of "repeats" (Hz) value to ButtonFunction (backwards-compatible)
//
//  Version 3:
//      - Addition of ClearElement function (backwards-compatible)
//      - (APP) Added optional URL parameter to load function, added
//        createFunctionsCopy(), made init(json:) failable and idiot-proof,
//        added readableName variable to FunctionType.
//

import UIKit

fileprivate let CURRENT_VERSION = 3

enum FunctionType: String {
    case button = "button"
    case toggleSwitch = "toggleSwitch"
    case clearElement = "clearElement"
    
    var readableName: String {
        switch self {
        case .button:       return "Button"
        case .toggleSwitch: return "Toggle Switch"
        case .clearElement: return "Clear Element"
        }
    }
}

protocol Function: AnyObject {
    var type: FunctionType { get }
    var title: String { get set }
    var order: Int { get set }
    init(json: JSON) throws // TODO: Add init(order:) ??
    func json() -> JSON
}

class ButtonFunction: Function {
    let type = FunctionType.button
    var title = ""
    var order = 0
    var message = Data()
    var format: String.Format
    var color: UIColor
    var repeats = 0
    var timer: Timer?
    
    init(order o: Int) {
        // version 1
        title = "New Function"
        message = "42".data(using: .utf8)!
        order = o
        color = #colorLiteral(red: 0, green: 0.568627451, blue: 0.9176470588, alpha: 1)
        
        // version 2
        format = .hex
        repeats = 0
    }
    
    required init(json: JSON) throws {
        // version 1
        guard let title = json["title"].string,
            let order = json["order"].int,
            let message = json["message"].string?.data(withFormat: .hex),
            let colorString = json["color"].string else {
                throw JSONError.invalidJSON
        }
        
        self.title = title
        self.order = order
        self.message = message
        self.color = UIColor(hexString: colorString)
        
        // version 2
        format = String.Format(rawValue: json["format"].int ?? 1)!
        repeats = json["repeats"].int ?? 0
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func json() -> JSON {
        var top = [String: Any]()
        
        // version 1
        top["type"] = type.rawValue
        top["title"] = title
        top["order"] = order
        top["message"] = message.string(withFormat: .hex)
        top["color"] = color.hexString
        
        // version 2
        top["format"] = format.rawValue
        top["repeats"] = repeats
        
        return JSON(top)
    }
    
    @objc func action() {
        var data = message
        let suffix = Settings.appendToFunction.value
        if suffix.count > 0 {
            data.append(suffix.data(using: .utf8)!)
        }
        
        serial.sendDataToDevice(data)
        NotificationCenter.default.post(name: .didSendData, object: self, userInfo: ["data": data, "playSound": false])
    }
    
    func startAction() {
        guard !message.isEmpty else { return }
        
        var data = message
        let suffix = Settings.appendToFunction.value
        if suffix.count > 0 {
            data.append(suffix.data(using: .utf8)!)
        }
        
        serial.sendDataToDevice(data)
        NotificationCenter.default.post(name: .didSendData, object: self, userInfo: ["data": data, "playSound": true]) // true ipv false!!

        if repeats > 0 {
            timer?.invalidate()
            timer = Timer.scheduledTimer(timeInterval: 1.0/Double(repeats), target: self, selector: #selector(action), userInfo: nil, repeats: true)
        }
    }
    
    func stopAction() {
        guard !message.isEmpty else { return }

        timer?.invalidate()
    }
}

class SwitchFunction: Function {
    let type = FunctionType.toggleSwitch
    var title = ""
    var order = 0
    var initialState = true
    var onMessage = Data()
    var offMessage = Data()
    var onFormat: String.Format
    var offFormat: String.Format
    
    init(order o: Int) {
        // version 1
        title = "New Function"
        initialState = true
        onMessage = "on".data(using: .utf8)!
        offMessage = "off".data(using: .utf8)!
        order = o
        
        // version 2
        onFormat = .hex
        offFormat = .hex
    }
    
    required init(json: JSON) throws {
        // version 1
        guard let title = json["title"].string,
            let order = json["order"].int,
            let initialState = json["initialstate"].bool,
            let onMessage = json["onmessage"].string?.data(withFormat: .hex),
            let offMessage = json["offmessage"].string?.data(withFormat: .hex) else {
                throw JSONError.invalidJSON
        }
        
        self.title = title
        self.order = order
        self.initialState = initialState
        self.onMessage = onMessage
        self.offMessage = offMessage
        
        // version 2
        onFormat = String.Format(rawValue: json["onformat"].int ?? 1)!
        offFormat = String.Format(rawValue: json["offformat"].int ?? 1)!
    }
    
    func json() -> JSON {
        var top = [String: Any]()
        
        // version 1
        top["type"] = type.rawValue
        top["title"] = title
        top["order"] = order
        top["initialstate"] = initialState
        top["onmessage"] = onMessage.string(withFormat: .hex)
        top["offmessage"] = offMessage.string(withFormat: .hex)
        
        // version 2
        top["onformat"] = onFormat.rawValue
        top["offformat"] = offFormat.rawValue
        
        return JSON(top)
    }
    
    func onAction() {
        var data = onMessage
        let suffix = Settings.appendToFunction.value
        if suffix.count > 0 {
            data.append(suffix.data(using: .utf8)!)
        }
        
        serial.sendDataToDevice(data)
        NotificationCenter.default.post(name: .didSendData, object: self, userInfo: ["data": data, "playSound": true])
    }
    
    func offAction() {
        var data = offMessage
        let suffix = Settings.appendToFunction.value
        if suffix.count > 0 {
            data.append(suffix.data(using: .utf8)!)
        }
        
        serial.sendDataToDevice(data)
        NotificationCenter.default.post(name: .didSendData, object: self, userInfo: ["data": data, "playSound": true])
    }
}

// Added in version 3
class ClearElement: Function {
    let type = FunctionType.clearElement
    var title = "Clear Element"
    var order = 0
    
    init(order o: Int) {
        order = o
    }
    
    required init(json: JSON) throws {
        // version 3
        guard let title = json["title"].string,
            let order = json["order"].int else {
                throw JSONError.invalidJSON
        }
        
        self.title = title
        self.order = order
    }
    
    func json() -> JSON {
        var top = [String: Any]()
        
        // version 3
        top["type"] = type.rawValue
        top["title"] = title
        top["order"] = order
        
        return JSON(top)
    }
}


extension JSON {
    static private var functionsURL: URL {
        let fm = FileManager.default
        let url = try! fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return url.appendingPathComponent("functions.json")
    }
    
    static func loadFunctions(url: URL = functionsURL) throws -> [Function] {
        if !FileManager.default.fileExists(atPath: url.path) {
            return []
        }
        
        let top = JSON(data: try Data(contentsOf: url))
        
        guard let version = top["version"].int else { throw JSONError.invalidJSON }
        guard version <= CURRENT_VERSION else { throw JSONError.invalidVersion }
        guard let arr = top["functions"].array else { throw JSONError.invalidJSON }

        var functions = [Function]()
        
        for val in arr {
            guard let typeString = val["type"].string else { throw JSONError.invalidJSON }
            guard let type = FunctionType(rawValue: typeString) else { throw JSONError.invalidJSON }
            
            switch type {
            case .button:
                functions.append(try ButtonFunction(json: val))
            case .toggleSwitch:
                print("ToggleSwitch not implemented")
            case .clearElement:
                functions.append(try ClearElement(json: val))
            }
        }
        
        functions.sort { $0.order < $1.order }
        return functions
    }
    
    static func saveFunctions(_ functions: [Function]) throws {
        let json: JSON = ["version": CURRENT_VERSION, "functions": functions.map { $0.json() }]
        try (try json.rawData()).write(to: functionsURL) //TODO: Overwrite??
    }
    
    static func createFunctionsCopy() throws -> URL {
        let fm = FileManager.default
        let url = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let copyURL = url.appendingPathComponent("exportedfunctions.json")

        if fm.fileExists(atPath: copyURL.path) {
            try fm.removeItem(at: copyURL)
        }

        try fm.copyItem(at: functionsURL, to: copyURL)
        return copyURL
    }
}

enum JSONError: Error {
    case invalidJSON
    case invalidVersion
}

extension JSONError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidJSON: return "Invalid JSON"
        case .invalidVersion: return "The JSON version is not compatible with this version of Bluetooth Serial Pro"
        }
    }
}
