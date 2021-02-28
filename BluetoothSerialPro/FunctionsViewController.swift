//
//  FunctionsCollectionViewController.swift
//  BluetoothSerialPro
//
//  Created by Alex on 02/03/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//

import UIKit
import QuartzCore

class ButtonCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    private var isOn = false // TODO: Kan verwijderd worden
    
    var function: ButtonFunction? {
        didSet {
            label.text = function!.title
            label.textColor = function!.color.isLight ? UIColor.black : UIColor.white
            selectedBackgroundView?.backgroundColor = function!.color.lighter(by: 60) // was 40
            (backgroundView as! GradientView).topColor = function!.color.lighter(by: 20)
            (backgroundView as! GradientView).bottomColor = function!.color
            (backgroundView as! GradientView).setNeedsLayout()
            
            if Settings.buttonSize.value == 0 {
                label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            } else {
                label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
            }
        }
    }
    
    private func setup() {
        isMultipleTouchEnabled = false
    
        backgroundColor = UIColor.clear
        clipsToBounds = false
        
        contentView.clipsToBounds = false
        contentView.layer.masksToBounds = false
        
        layer.masksToBounds = false
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 1.0
        
        selectedBackgroundView = UIView()
        selectedBackgroundView?.layer.masksToBounds = true
        selectedBackgroundView?.layer.cornerRadius = 8
        
        backgroundView = GradientView()
        backgroundView?.layer.masksToBounds = true
        backgroundView?.layer.cornerRadius = 8
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted != oldValue {
                if isHighlighted {
                    function?.startAction()
                } else {
                    function?.stopAction()
                }
            }
        }
    }
}


class FunctionsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var padding: CGFloat {
        if Settings.buttonSize.value == 0 {
            // normal
            return UIScreen.main.bounds.width * 0.02
        } else {
            // big
            return UIScreen.main.bounds.width * 0.028
        }
    }
    
    var cellsPerRow: CGFloat {
        if Settings.buttonsPerRow.value == 0 {
            // auto
            if UIDevice.isPhone {
                return UIApplication.shared.statusBarOrientation.isPortrait ? 1 : 2
            } else {
                return UIApplication.shared.statusBarOrientation.isPortrait ? 2 : 3
            }
        } else {
            // manual
            return CGFloat(Settings.buttonsPerRow.value)
        }
    }
    
    let buttonCellIdentifier = "buttonCell"
    let clearElementIdentifier = "clearElementCell"
    var functions = [Function]()
    
    
    // MARK: - ViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(functionsChanged), name: .functionsChanged)
        
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        
        collectionView.contentInset.top = navigationController?.navigationBar.frame.maxY ?? 64
        
        do {
            functions = try JSON.loadFunctions()
        } catch {
            functions = []
            print("Error loading functions: \(error.localizedDescription)")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.reloadData()
    }
    
    @objc func functionsChanged() {
        do {
            functions = try JSON.loadFunctions()
        } catch {
            functions = []
            print("Error loading functions: \(error.localizedDescription)")
        }
        
        collectionView?.reloadData()
    }

    
    // MARK: - CollectionView DataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return functions.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let function = functions[indexPath.row]
        switch function.type {
        case .button:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: buttonCellIdentifier, for: indexPath) as! ButtonCell
            cell.function = function as? ButtonFunction
            return cell
            
        case .clearElement:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: clearElementIdentifier, for: indexPath)
            return cell
            
        case .toggleSwitch:
            print("Unsupported function type (switch) in collectionView:cellForItemAt:")
        }
        
        return collectionView.dequeueReusableCell(withReuseIdentifier: buttonCellIdentifier, for: indexPath)
    }
    
    
    // MARK: - CollectionView Delegate
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return functions[indexPath.row] is ButtonFunction
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    /*func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let function = functions[sourceIndexPath.row]
        functions.remove(at: sourceIndexPath.row)
        functions.insert(function, at: destinationIndexPath.row)
        
        for i in 0 ..< functions.count {
            functions[i].order = i
        }
        
        JSON.saveFunctions(functions)
    }*/
    
    
    // MARK: - FlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - padding*(cellsPerRow+1))/cellsPerRow - 3
        let height = Settings.buttonSize.value == 0 ? CGFloat(50) : CGFloat(70)
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return padding
    }
}
