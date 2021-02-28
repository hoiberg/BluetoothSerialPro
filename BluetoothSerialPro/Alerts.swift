//
//  Alerts.swift
//  BluetoothSerialPro
//
//  Created by Alex on 27/03/2019.
//  Copyright © 2019 Hangar42. All rights reserved.
//

// TODO: Later: Trigger ending \n \r ??

// TODO: Later: Export & Import alerts ?

import Foundation
import AudioToolbox

fileprivate let ALERTS_CURRENT_VERSION = 1

/*
 An alternative implementation of DataAlertSound that uses sounds present in
 the iOS operating system. Works in iOS 9 but these files were removed in a
 later version.
 
 enum DataAlertSound: Int {
    case none = 0
    case aurora = 1
    case bamboo = 2
    case circles = 3
    case complete = 4
    case hello = 5
    case input = 6
    case keys = 7
    case note = 8
    case popcorn = 9
    case synth = 10
    
    static let all = [none, aurora, bamboo, circles, complete, hello, input, keys, note, popcorn, synth]
    
    var name: String {
        switch self {
        case .none: return "None"
        case .aurora: return "Aurora"
        case .bamboo: return "Bamboo"
        case .circles: return "Circles"
        case .complete: return "Complete"
        case .hello: return "Hello"
        case .input: return "Input"
        case .keys: return "Keys"
        case .note: return "Note"
        case .popcorn: return "Popcorn"
        case .synth: return "Synth"
        }
    }
        
    var file: String {
        switch self {
        case .none: return ""
        case .aurora: return "Modern/sms_alert_aurora.caf"
        case .bamboo: return "Modern/sms_alert_bamboo.caf"
        case .circles: return "Modern/sms_alert_circles.caf"
        case .complete: return "Modern/sms_alert_complete.caf"
        case .hello: return "Modern/sms_alert_hello.caf"
        case .input: return "Modern/sms_alert_input.caf"
        case .keys: return "Modern/sms_alert_keys.caf"
        case .note: return "Modern/sms_alert_note.caf"
        case .popcorn: return "Modern/sms_alert_popcorn.caf"
        case .synth: return "Modern/sms_alert_synth.caf" // TODO: hiermee verder sounds werken niet in iOS13
        }
    }
    
    func play() {
        guard self != .none else { return }
        
        var soundID: SystemSoundID = 0
        
        AudioServicesCreateSystemSoundID(URL(string: "/System/Library/Audio/UISounds/" + file)! as CFURL, &soundID)
        
        AudioServicesAddSystemSoundCompletion(soundID, nil, nil, { (soundID, _) -> Void in
            AudioServicesDisposeSystemSoundID(soundID)
        }, nil)
        
        AudioServicesPlaySystemSound(soundID)
    }
}
*/

enum DataAlertSound: Int {
    case none = 0
    case up = 1
    case chime = 2
    case beep = 3
    case newmessage = 4
    case chime2 = 5
    case sonar = 6
    case hint = 7
    case ding = 8
    case levelup = 9
    case chime3 = 10
    
    static let all = [none, up, chime, beep, newmessage, chime2, sonar, hint, ding, levelup, chime3]
    
    var name: String {
        switch self {
        case .none: return "None"
        case .up: return "Up"
        case .chime: return "Chime 1"
        case .beep: return "Beep"
        case .newmessage: return "New Message"
        case .chime2: return "Chime 2"
        case .sonar: return "Sonar"
        case .hint: return "Keys"
        case .ding: return "Ding"
        case .levelup: return "Level Up"
        case .chime3: return "Chime 3"
        }
    }
        
    var file: (String, String) {
        switch self {
        case .none: return ("None", "None")
        case .up: return ("234524__foolboymedia__notification-up-louder", "wav")
        case .chime: return ("352661__foolboymedia__complete-chime", "mp3")
        case .beep: return ("258193__kodack__beep-beep", "wav")
        case .newmessage: return ("221359__melliug__newmessage", "mp3")
        case .chime2: return ("202029__hykenfreak__notification-chime", "wav")
        case .sonar: return ("70299__kizilsungur__sonar", "wav")
        case .hint: return ("320181__dland__hint", "wav")
        case .ding: return ("91926__tim-kahn__ding", "wav")
        case .levelup: return ("337049__shinephoenixstormcrow__320655-rhodesmas-level-up-01", "mp3")
        case .chime3: return ("80921__justinbw__buttonchime02up", "wav")
        }
    }
    
    func play() {
        guard self != .none else { return }
        
        var soundID: SystemSoundID = 0
        
        AudioServicesCreateSystemSoundID(Bundle.main.url(forResource: file.0, withExtension: file.1)! as CFURL, &soundID)
        
        AudioServicesAddSystemSoundCompletion(soundID, nil, nil, { (soundID, _) -> Void in
            AudioServicesDisposeSystemSoundID(soundID) // maybe it would be better to keep the soundID around?
        }, nil)
        
        AudioServicesPlaySystemSound(soundID)
    }
}


class DataAlert {
    
    var title: String
    
    var trigger: Data
    var format: String.Format
    
    var sound: DataAlertSound
    var showAlert: Bool
    
    var isActive: Bool
    
    // not permanently stored
    var nextCompareIndex = 0
    
    // set to true to ignore this alert for the rest of this session
    var ignore = false
        
    init() {
        title = "New Alert"
        trigger = "trigger".data(withFormat: .utf8)
        format = .utf8
        sound = .none
        showAlert = true
        isActive = true
    }

    init(json: JSON) throws {
        // version 1
        guard let title = json["title"].string,
            let trigger = json["trigger"].string?.data(withFormat: .hex),
            let formatValue = json["format"].int,
            let format = String.Format(rawValue: formatValue),
            let soundValue = json["sound"].int,
            let sound = DataAlertSound(rawValue: soundValue),
            let showAlert = json["showalert"].bool,
            let isActive = json["isactive"].bool else {
                throw JSONError.invalidJSON
        }
        
        self.title = title
        self.trigger = trigger
        self.format = format
        self.sound = sound
        self.showAlert = showAlert
        self.isActive = isActive
    }
    
    func json() -> JSON {
        var top = [String: Any]()
        
        // version 1
        top["title"] = title
        top["trigger"] = trigger.string(withFormat: .hex)
        top["format"] = format.rawValue
        top["sound"] = sound.rawValue
        top["showalert"] = showAlert
        top["isactive"] = isActive
        
        return JSON(top)
    }
}


extension JSON {
    static private var alertsURL: URL {
        let fm = FileManager.default
        let url = try! fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return url.appendingPathComponent("alerts.json")
    }
    
    static func loadAlerts(url: URL = alertsURL) throws -> [DataAlert] {
        if !FileManager.default.fileExists(atPath: url.path) {
            return []
        }
        
        let top = JSON(data: try Data(contentsOf: url))
        
        guard let version = top["version"].int else { throw JSONError.invalidJSON }
        guard version <= ALERTS_CURRENT_VERSION else { throw JSONError.invalidVersion }
        guard let arr = top["alerts"].array else { throw JSONError.invalidJSON }
        
        return try arr.map { try DataAlert(json: $0) }
    }
    
    static func saveAlerts(_ alerts: [DataAlert]) throws {
        let json: JSON = ["version": ALERTS_CURRENT_VERSION, "alerts": alerts.map { $0.json() }]
        try (try json.rawData()).write(to: alertsURL) //TODO: Overwrite??
    }
}
