//
//  FunctionOptionsTableViewController.swift
//  BluetoothSerialPro
//
//  Created by Alex on 14/11/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//

import UIKit

class FunctionOptionsTableViewController: UITableViewController, SelectionTableViewControllerDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var buttonsPerRowLabel: UILabel!
    @IBOutlet weak var buttonSizeSegments: UISegmentedControl!
    @IBOutlet weak var appendToEndSegments: UISegmentedControl!
    
    
    // MARK: - Variables
    
    let buttonsPerRowOptions = ["AUTO", "1", "2", "3", "4", "5"]
    let appendToEndOptions = ["", "\n", "\r", "\r\n"] // duplicate in InputOptionsTVC
    
    
    // MARK: - ViewController
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        buttonsPerRowLabel.text = buttonsPerRowOptions[Settings.buttonsPerRow.value]
        buttonSizeSegments.selectedSegmentIndex = Settings.buttonSize.value
        appendToEndSegments.selectedSegmentIndex = appendToEndOptions.index(of: Settings.appendToFunction.value)!
    }
    

    // MARK: - TableView
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            let selection = SelectionTableViewController()
            selection.delegate = self
            selection.items = buttonsPerRowOptions
            selection.selectedItem = Settings.buttonsPerRow.value
            show(selection, sender: self)
        }
    }
    
    
    // MARK: - SelectionTable
    
    func selectionTableWithTag(_ tag: Int, didSelectItem item: Int) {
        Settings.buttonsPerRow.value = item
        buttonsPerRowLabel.text = buttonsPerRowOptions[item]
    }
    
    
    // MARK: - Actions
    
    @IBAction func buttonSizeChanged(_ sender: Any) {
        Settings.buttonSize.value = buttonSizeSegments.selectedSegmentIndex
    }
    
    @IBAction func appendToEndChanged(_ sender: Any) {
        Settings.appendToFunction.value = appendToEndOptions[appendToEndSegments.selectedSegmentIndex]
    }
    
}
