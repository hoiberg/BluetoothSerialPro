//
//  EditFunctionsTableViewController.swift
//  BluetoothSerialPro
//
//  Created by Alex on 03/03/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//

import UIKit

class NeverClearView: UIView {
    override var backgroundColor: UIColor? {
        didSet {
            if backgroundColor != nil && backgroundColor!.cgColor.alpha == 0 {
                backgroundColor = oldValue
            }
        }
    }
}

protocol EditIndividualFunction {
    var functions: [Function] { get set }
    var functionIndex: Int { get set }
}

class EditFunctionsTableViewController: UITableViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var addFunctionButton: UIBarButtonItem!
    
    
    // MARK: - Variables
    
    var functions = [Function]()
    
    
    // MARK: - ViewController

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        do {
            functions = try JSON.loadFunctions()
        } catch {
            functions = []
            print("Error loading functions: \(error.localizedDescription)")
        }
        
        tableView.reloadData()
    }
    
    private func save() {
        do {
            try JSON.saveFunctions(functions)
        } catch {
            print("Error saving functions: \(error.localizedDescription)")
        }
    }


    // MARK: - TableView DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return functions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "functionCell", for: indexPath)
        let titleLabel = cell.viewWithTag(1) as! UILabel
        let detailLabel = cell.viewWithTag(2) as! UILabel
        let colorView = cell.viewWithTag(3)! as! NeverClearView
        let function = functions[indexPath.row]
        
        titleLabel.text = function.title
        detailLabel.text = function.type.readableName

        if function.type == .button {
            colorView.isHidden = false
            colorView.backgroundColor = (function as! ButtonFunction).color
            colorView.layer.cornerRadius = colorView.bounds.height/2
            colorView.layer.masksToBounds = true
        } else {
            colorView.isHidden = true
        }
        
        if function.type == .clearElement {
            cell.selectionStyle = .none
            cell.accessoryType = .none
        } else {
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
        }

        return cell
    }
    
    
    // MARK: - TableView Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch functions[indexPath.row].type {
        case .button:
            performSegue(withIdentifier: "showEditButtonFunction", sender: self)
        case .toggleSwitch:
            print("ToggleSwitch function not implemented")
        case .clearElement:
            break // not editable
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            functions.remove(at: indexPath.row)
            for i in 0 ..< functions.count {
                functions[i].order = i
            }
            save()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let function = functions[fromIndexPath.row]
        functions.remove(at: fromIndexPath.row)
        functions.insert(function, at: to.row)
        
        for i in 0 ..< functions.count {
            functions[i].order = i
        }
        
        save()
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }


    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier != "showFunctionOptions" {
            var dest = segue.destination as! EditIndividualFunction
            dest.functions = functions
            dest.functionIndex = tableView.indexPathForSelectedRow!.row
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func done(_ sender: Any) {
        NotificationCenter.default.post(name: .functionsChanged)
        dismiss(animated: true)
    }
    
    @IBAction func add(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Button Function", style: .default) { _ in
            self.functions.append(ButtonFunction(order: self.functions.count))
            self.save()
            self.tableView.reloadData()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Clear Element", style: .default) { _ in
            self.functions.append(ClearElement(order: self.functions.count))
            self.save()
            self.tableView.reloadData()
        })
        
        if UIDevice.isPhone {
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        }
        
        if let popover = actionSheet.popoverPresentationController {
            popover.barButtonItem = addFunctionButton // TODO: verander naar sender
        }
        
        present(actionSheet, animated: true)
    }
    
    @IBAction func edit(_ sender: UIBarButtonItem) {
        tableView.setEditing(!tableView.isEditing, animated: true)
        sender.title = tableView.isEditing ? "Done" : "Edit"
    }
}
