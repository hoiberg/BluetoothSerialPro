//
//  SelectionTableViewController.swift
//  CleanflightMobile
//
//  Created by Alex on 23-11-15.
//  Copyright © 2015 Hangar42. All rights reserved.
//
//  Different from the one in Eaze!

import UIKit

protocol SelectionTableViewControllerDelegate {
    func selectionTableWithTag(_ tag: Int, didSelectItem item: Int)
}

class SelectionTableViewController: UITableViewController {
    
    var delegate: SelectionTableViewControllerDelegate?,
        tag = 0,
        selectedItem: Int?,
        items: [String] = []
    

    // MARK: - Functions
    
    override func viewDidLoad() {
        tableView!.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    
    // MARK: - TableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        cell!.textLabel!.text = items[indexPath.row]
        
        if let i = selectedItem {
            if indexPath.row == i {
                cell!.accessoryType = .checkmark
            }
        }

        return cell!
    }
    
    
    // MARK: - TableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.selectionTableWithTag(tag, didSelectItem: indexPath.row)
        let _ = navigationController?.popViewController(animated: true)
    }
}
