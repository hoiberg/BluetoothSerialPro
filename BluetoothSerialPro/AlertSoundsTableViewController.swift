//
//  AlertSoundsTableViewController.swift
//  BluetoothSerialPro
//
//  Created by Alex on 11/09/2019.
//  Copyright © 2019 Hangar42. All rights reserved.
//

import UIKit

class AlertSoundsTableViewController: UITableViewController {
    
    // MARK: - Variables
    
    var alert: DataAlert!
    
    var sounds: [DataAlertSound] {
        return DataAlertSound.all
    }
    
    var selectedSound: Int {
        return DataAlertSound.all.firstIndex(of: alert.sound)!
    }
    
    
    // MARK: - TableView DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sounds.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "soundCell", for: indexPath)
        cell.textLabel!.text = sounds[indexPath.row].name
        cell.accessoryType = indexPath.row == selectedSound ? .checkmark : .none
        return cell
    }
    
    
    // MARK: - TableView Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.cellForRow(at: indexPath)!.accessoryType = .checkmark
        tableView.cellForRow(at: IndexPath(row: selectedSound, section: 0))!.accessoryType = .none
        alert.sound = sounds[indexPath.row]
        alert.sound.play()
    }

}
