//
//  AlertsTableViewController.swift
//  BluetoothSerialPro
//
//  Created by Alex on 16/04/2019.
//  Copyright © 2019 Hangar42. All rights reserved.
//

import UIKit

class AlertsTableViewController: UITableViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var addAlertButton: UIBarButtonItem!
    
    
    // MARK: - Variables
    
    var alerts = [DataAlert]()
    
    
    // MARK: - ViewController
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        do {
            alerts = try JSON.loadAlerts() // TODO: Sort? Alfabetisch?
        } catch {
            alerts = []
            print("Error loading alerts: \(error.localizedDescription)")
        }
        
        tableView.reloadData()
    }
    
    private func save() {
        do {
            try JSON.saveAlerts(alerts)
        } catch {
            print("Error saving alerts: \(error.localizedDescription)")
        }
    }
    
    
    // MARK: - TableView DataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alerts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "alertCell", for: indexPath)
        let alert = alerts[indexPath.row]
        
        cell.textLabel!.text = alert.title.isEmpty ? "Unnamed Alert" : alert.title
        cell.detailTextLabel!.text = alert.isActive ? "Active" : "Inactive"
        
        return cell
    }
    
    
    // MARK: - TableView Delegate
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            alerts.remove(at: indexPath.row)
            save()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAlertDetail" {
            let dest = segue.destination as! AlertDetailTableViewController
            dest.alerts = alerts
            dest.alert = alerts[tableView.indexPathForSelectedRow!.row]
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func done(_ sender: Any) {
        NotificationCenter.default.post(name: .alertsChanged)
        dismiss(animated: true)
    }
    
    @IBAction func add(_ sender: UIBarButtonItem) {
        alerts.append(DataAlert())
        save()
        tableView.reloadData()
    }
    
    @IBAction func edit(_ sender: UIBarButtonItem) {
        tableView.setEditing(!tableView.isEditing, animated: true)
        sender.title = tableView.isEditing ? "Done" : "Edit"
    }

}
