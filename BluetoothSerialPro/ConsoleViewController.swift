//
//  SerialViewController.swift
//  BluetoothSerialPro
//
//  Created by Alex on 27/11/2016.
//  Copyright © 2016 Hangar42. All rights reserved.
//
//  In order to hide the gradient background of the tableView, we add two white uitableviewcells
//  both with a height equal to that of the entire screen. So we also have to adjust the top/bottom
//  content insets (minus view.frame.bounds)
//
//  Sound tings: 1054 1313
//
//  For some unknown reason the textView only scrolls to the bottom if the last character is a
//  newLine character. Hence the workaround where the newline is added in addLineHeader and removed
//  in appendAttributedText. For this we also need previousLineSent to color the linebreak correctly.
//  Possibly related: https://stackoverflow.com/questions/46457660
//
//  textView contentinset in IB is set to 'never'; here done programatically for backwards-compatibility
//  with iOS 9/10
//
//  In displayOptionsChanged() we add scrollToBottom to the textCopy queue with a 0.5s delay as a workaround
//  for the unexplained erratic scrolling behaviour.
//

// TODO: Autoscroll not reliable bij veel chars per lijn???
// TODO: Scrollbar top / bottom inset??
// TODO: Alert icon less stroke width
// TODO: Fixed update intervals voor betere reliability???
// FIXME: Not able to scroll to bottom after tapping on the status bar (hence scrollsToTop disabled)

import UIKit
import CoreBluetooth
import AVFoundation
import Dispatch

class ConsoleViewController: UIViewController, BluetoothSerialDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    class Message {
        var data: Data
        var timeStamp: Date
        var sent: Bool
        
        init(data: Data, sent: Bool = false) {
            self.data = data
            self.timeStamp = Date()
            self.sent = sent
        }
    }
    
    
    // MARK: - Outlets
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var sideLineConstraint: NSLayoutConstraint!
    @IBOutlet weak var sideLine: UIView!
    
    
    // MARK: - Variables
    
    var tableView: UITableView!
    var isChatEnabled = false
    
    var messages = [Message]()
    var bytesOnLine = 0
    var lines = 0
    var previousLineSent = false
    
    var alerts = [DataAlert]()
    var triggeredAlerts = [DataAlert]()
    var isShowingAlert = false
    
    var displayStyle = DisplayStyle.console
    var displayFormat = String.Format.utf8
    var displaySent = true
    var displayNewlineRule = NewlineAfter.message
    var displayTimeStamp = true
    var displayMicroseconds = false
    var displayLineNumbers = false
    
    var autoScroll = true
    
    var inputFormat = String.Format(rawValue: Settings.inputFormat.value)!
    var inputPostfix = Settings.appendToInput.value
    
    var playSounds = true
    
    let dateFormatter = DateFormatter()
    var defaultAttributes = [NSAttributedStringKey: Any]()
    var sentAttributes = [NSAttributedStringKey: Any]()
    
    let bottomViewHeight: CGFloat = 49
    var topWhiteCellHeight: CGFloat { return UIScreen.main.bounds.height }
    var bottomWhiteCellHeight: CGFloat { return UIScreen.main.bounds.height*2 }
    
    
    // MARK: - Multi Threading
    
    let queues = (textCopy:   DispatchQueue(label: "nl.hangar42.bluetoothserialpro.attrtextqueue"),
                  textUpdate: DispatchQueue(label: "nl.hangar42.bluetoothserialpro.textupdatequeue"),
                  isWaiting:  DispatchQueue(label: "nl.hangar42.bluetoothserialpro.iswaitingqueue"))
    
    private var _attributedTextCopy = NSMutableAttributedString()
    private var _isWaitingForUpdate = false

    var isWaitingForUpdate: Bool {
        set {
            queues.isWaiting.async {
                self._isWaitingForUpdate = newValue
            }
        }
        get {
            var val = true
            queues.isWaiting.sync {
                val = self._isWaitingForUpdate
            }
            return val
        }
    }
    
    func appendToAttributedText(_ attr: NSAttributedString, _ preserveLinebreak: Bool) {
        queues.textCopy.async {
            if !preserveLinebreak && self._attributedTextCopy.length > 0 {
                let last = NSRange(location: self._attributedTextCopy.length-1, length: 1)
                self._attributedTextCopy.deleteCharacters(in: last)
            }
            self._attributedTextCopy.append(attr)
            
            guard !self.isWaitingForUpdate else { return }
            self.isWaitingForUpdate = true
            DispatchQueue.main.async {
                self.isWaitingForUpdate = false
                self.textView.attributedText = self.getAttributedText()
                self.scrollToBottom()
            }
        }
    }
    
    func getAttributedText() -> NSAttributedString {
        var attr: NSAttributedString!
        queues.textCopy.sync {
            attr = self._attributedTextCopy.copy() as! NSAttributedString
        }
        return attr
    }
    
    func clearAttributedText() {
        queues.textCopy.async {
            self._attributedTextCopy = NSMutableAttributedString()
        }
    }
    
    
    // MARK: - ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        serial.delegate = self
        clear()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide)
        NotificationCenter.default.addObserver(self, selector: #selector(inputOptionsChanged), name: .inputOptionsChanged)
        NotificationCenter.default.addObserver(self, selector: #selector(displayOptionsChanged), name: .displayOptionsChanged)
        NotificationCenter.default.addObserver(self, selector: #selector(clear), name: .clearScreen)
        NotificationCenter.default.addObserver(self, selector: #selector(serialDidSendData(_:)), name: .didSendData)
        NotificationCenter.default.addObserver(self, selector: #selector(alertsChanged), name: .alertsChanged)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        textView.textContainerInset.top = (navigationController?.navigationBar.frame.maxY ?? 64) + 5
        textView.textContainerInset.bottom = bottomViewHeight
        textView.scrollsToTop = false // auto scroll to top has buggy behaviour (screws up bottom inset)
        textView.text = ""
        
        let font = UIFont(name: "Menlo-Regular", size: 15)
        let paragraphStyle = NSMutableParagraphStyle()
        defaultAttributes[NSAttributedStringKey.font] = font
        defaultAttributes[NSAttributedStringKey.paragraphStyle] = paragraphStyle
        sentAttributes = defaultAttributes
        sentAttributes[NSAttributedStringKey.backgroundColor] = view.tintColor.withAlphaComponent(0.07)
        
        inputOptionsChanged()
        displayOptionsChanged()
        alertsChanged()
        
        let data = Settings.sendOnConnect.value
        if !data.isEmpty {
            serial.sendDataToDevice(data)
            messages.append(Message(data: data, sent: true))
            addText(forMessage: messages.last!)
            scrollToBottom()
            playSentSound()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        textView.isScrollEnabled = false // cuz bug in iOS
        textView.isScrollEnabled = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        textView.textContainerInset.top = (navigationController?.navigationBar.frame.maxY ?? 64) + 5
        
        if isChatEnabled {
            tableView.contentInset.top = (navigationController?.navigationBar.frame.maxY ?? 64) + 5 - topWhiteCellHeight
            tableView.contentInset.bottom = bottomViewHeight + 8 - bottomWhiteCellHeight
        }
    }
    
    @objc func alertsChanged() {
        do {
            alerts = try JSON.loadAlerts()
            alerts.removeAll { !$0.isActive || $0.trigger.isEmpty }
        } catch {
            alerts = []
            print("Error loading alerts: \(error.localizedDescription)")
        }
    }
    
    @objc func inputOptionsChanged() {
        inputField.text = ""
        serial.maxChunkSize = Settings.maxChunkSize.value
        inputFormat = String.Format(rawValue: Settings.inputFormat.value)!
        inputPostfix = Settings.appendToInput.value
    }
    
    @objc func displayOptionsChanged() {
        
        //
        // settings
        
        displayStyle = DisplayStyle(rawValue: Settings.displayStyle.value)!
        displayFormat = String.Format(rawValue: Settings.displayFormat.value)!
        displaySent = Settings.displaySentMessages.value
        displayNewlineRule = NewlineAfter(id: Settings.messageSeparation.value)
        displayTimeStamp = Settings.displayTimeStamps.value
        displayMicroseconds = Settings.displayMicroseconds.value
        displayLineNumbers = Settings.displayLineNumbers.value
        autoScroll = Settings.autoScroll.value
        playSounds = Settings.shouldPlaySounds.value
        
        
        //
        // date formatter
        
        if displayMicroseconds {
            dateFormatter.dateFormat = "HH:mm:ss.SSS"
        } else {
            dateFormatter.dateFormat = "HH:mm:ss"
        }
        
        
        //
        // calculate indent
        
        var indent: CGFloat = 0
        if displayTimeStamp { indent += 81 }
        if displayMicroseconds { indent += 37 }
        if displayLineNumbers { indent += 45 }
        
        
        //
        // paragraph style
        
        let paragraphStyle = defaultAttributes[NSAttributedStringKey.paragraphStyle] as! NSMutableParagraphStyle
        paragraphStyle.lineBreakMode = displayFormat == .utf8 ? .byCharWrapping : .byWordWrapping
        paragraphStyle.headIndent = indent
        
        
        //
        // side line
        
        sideLineConstraint.constant = indent
        
        if !isChatEnabled && (displayTimeStamp || displayLineNumbers) {
            sideLine.isHidden = false
        } else {
            sideLine.isHidden = true
        }
        
        
        //
        // display style
        
        if !isChatEnabled && displayStyle == .chatBox {
            createChatTableView()
        } else if isChatEnabled && displayStyle == .console {
            removeChatTableView()
        } else if isChatEnabled {
            tableView.reloadData()
        }
        
        
        //
        // reset and reload
        
        clearAttributedText()
        textView.text = ""
        bytesOnLine = 0
        lines = 0
        for m in messages {
            addText(forMessage: m, updateTableView: false)
        }

        queues.textCopy.async {
            delay(seconds: 0.5) {
                DispatchQueue.main.async {
                    self.scrollToBottom()
                }
            }
        }
    }
    
    func createChatTableView() {
        textView.isHidden = true
        sideLine.isHidden = true
        
        tableView = UITableView(frame: textView.frame)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset.top = (navigationController?.navigationBar.frame.maxY ?? 64) + 5 - topWhiteCellHeight
        tableView.contentInset.bottom = bottomViewHeight + 8 - bottomWhiteCellHeight
        tableView.register(ChatTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "whiteCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        
        view.insertSubview(tableView, aboveSubview: textView)
        
        let heightConstraint = NSLayoutConstraint(item: tableView, attribute: .height, relatedBy: .equal, toItem: textView, attribute: .height, multiplier: 1.0, constant: 0.0)
        let topConstraint = NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: textView, attribute: .top, multiplier: 1.0, constant: 0.0)
        let leftConstraint = NSLayoutConstraint(item: tableView, attribute: .left, relatedBy: .equal, toItem: textView, attribute: .left, multiplier: 1.0, constant: 8)
        let rightConstraint = NSLayoutConstraint(item: tableView, attribute: .right, relatedBy: .equal, toItem: textView, attribute: .right, multiplier: 1.0, constant: -8)
        
        view.addConstraints([heightConstraint, topConstraint, leftConstraint, rightConstraint])
        
        let gradientView = GradientView()
        gradientView.topColor = #colorLiteral(red: 0.3593252877, green: 0.8365120347, blue: 1, alpha: 1)
        gradientView.bottomColor = #colorLiteral(red: 0.06494087851, green: 0.516777352, blue: 0.9410062065, alpha: 1)
        tableView.backgroundView = gradientView
        
        tableView.reloadData()
        isChatEnabled = true
    }
    
    func removeChatTableView() {
        tableView.removeFromSuperview()
        tableView = nil
        isChatEnabled = false
        textView.isHidden = false
        sideLine.isHidden = false
    }
    
    
    // MARK: - Keyboard
    
    @objc func keyboardWillShow(_ notification: Notification) {
        var info = (notification as NSNotification).userInfo!
        let value = info[UIKeyboardFrameEndUserInfoKey] as! NSValue
        let keyboardFrame = value.cgRectValue
        
        //TODO: Not animating properly
        UIView.animate(withDuration: 1, delay: 0, options: .curveLinear, animations: {
            self.bottomConstraint.constant = keyboardFrame.size.height
        }, completion: { Bool -> Void in
            self.textView.textContainerInset.bottom = keyboardFrame.size.height + self.bottomViewHeight + 8
            if self.isChatEnabled {
                self.tableView.contentInset.bottom = keyboardFrame.size.height + self.bottomViewHeight + 8  - self.bottomWhiteCellHeight
            }
            self.scrollToBottom()
        })
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 1, delay: 0, options: .curveLinear, animations: {
            self.bottomConstraint.constant = 0
        }, completion: { Bool -> Void in
            self.textView.textContainerInset.bottom = self.bottomViewHeight + 8
            if self.isChatEnabled {
                self.tableView.contentInset.bottom = self.bottomViewHeight + 8 - self.bottomWhiteCellHeight
            }
        })
        
    }
    
    @objc func dismissKeyboard() {
        if inputField.isEditing {
            inputField.resignFirstResponder()
        }
    }
    
    
    // MARK: - TextField
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        var data = textField.text!.data(withFormat: inputFormat)
        if !data.isEmpty || !inputPostfix.isEmpty {
            if !inputPostfix.isEmpty {
                data.append(inputPostfix.data(withFormat: .utf8))
            }
            serial.sendDataToDevice(data)
            messages.append(Message(data: data, sent: true))
            addText(forMessage: messages.last!)
            scrollToBottom()
            playSentSound()
        } else {
            //print("No data sent")
        }
        
        textField.text = ""
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty {
            return true
        }
        
        if inputFormat == .utf8 { return true }
        
        var allowed = " ,.-01"
        if inputFormat == .hex { allowed += "23456789abcdef" }
        if inputFormat == .dec { allowed += "23456789" }
        if inputFormat == .oct { allowed += "234567" }
        
        for char in string {
            if !allowed.contains(char) {
                return false
            }
        }
        
        return true
    }
    
    
    // MARK: - TextView
    
    @objc func clear() {
        messages = []
        bytesOnLine = 0
        lines = 0
        
        if isChatEnabled {
            tableView.reloadData()
        }
        
        clearAttributedText()
        textView.text = ""
        
        alerts.forEach { $0.ignore = false }
        triggeredAlerts = []
    }
    
    func scrollToBottom() {
        guard autoScroll else { return }
        if isChatEnabled {
            guard !messages.isEmpty else { return }
            let indexPath = IndexPath(row: messages.count+1, section: 0) // +1 cuz of extra white cell
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        } else {
            UIView.setAnimationsEnabled(false) // for speed
            let range = NSMakeRange(NSString(string: textView.text).length - 1, 1)
            textView.scrollRangeToVisible(range)
            UIView.setAnimationsEnabled(true)
        }
    }
    
    func addText(forMessage msg: Message, updateTableView: Bool = true) {
        if !displaySent && msg.sent {
            return
        }
        
        if isChatEnabled && updateTableView {
            tableView.insertRows(at: [IndexPath(row: messages.count, section: 0)], with: .none) // not min one cuz of extra white celll
            //return - Still add text to textview for sharesheet function!
        }
        
        queues.textUpdate.async {
            self._addText(forMessage: msg)
        }
    }
    
    private func _addText(forMessage msg: Message) {
        var string = ""
        var preserveLinebreak = false
        
        func addLineHeader() {
            lines += 1
            
            if string.isEmpty {
                preserveLinebreak = true
            } else {
                string += "\n"
            }
            
            if displayLineNumbers {
                string += "\(lines)".leftPad("0", minCount: 4) + " "
            }
            
            if displayTimeStamp {
                string += dateFormatter.string(from: msg.timeStamp) + " "
            }
        }
        
        func append(string: String, attributes: [NSAttributedStringKey: Any]) {
            appendToAttributedText(NSAttributedString(string: string, attributes: attributes), preserveLinebreak)
        }
        
        if msg.sent {
            if bytesOnLine > 0 {
                append(string: "\n", attributes: defaultAttributes)
                bytesOnLine = 0
            }
            addLineHeader()
            string += msg.data.string(withFormat: displayFormat).removeNewline() + "\n"
            append(string: string, attributes: sentAttributes)
            return
        }
        
        switch displayNewlineRule {
        case .message:
            addLineHeader()
            string += msg.data.string(withFormat: displayFormat).removeNewline() /*+ "\n"*/
            
        case .count(let max):
            for b in msg.data {
                if bytesOnLine == 0 {
                    addLineHeader()
                }
                string += b.string(withFormat: displayFormat).removeNewline()
                if displayFormat != .utf8 {
                    string += " "
                }
                bytesOnLine += 1
                if bytesOnLine == max {
                    //string += "\n"
                    bytesOnLine = 0
                }
            }
            
        case .byte(let byte):
            for b in msg.data {
                if bytesOnLine == 0 {
                    addLineHeader()
                }
                string += b.string(withFormat: displayFormat).removeNewline()
                if displayFormat != .utf8 {
                    string += " "
                }
                bytesOnLine += 1
                if b == byte {
                    //string += "\n"
                    bytesOnLine = 0
                }
            }
            
        case .newLine:
            for b in msg.data {
                if bytesOnLine == 0 {
                    addLineHeader()
                }
                string += b.string(withFormat: displayFormat).removeNewline()
                if displayFormat != .utf8 {
                    string += " "
                }
                bytesOnLine += 1
                if b == 10 {
                    //string += "\n"
                    bytesOnLine = 0
                }
            }
        }

        string += "\n"
        append(string: string, attributes: defaultAttributes)
    }
    
    func playReceivedSound() {
        guard playSounds else { return }
        AudioServicesPlaySystemSound(1003)
    }
    
    func playSentSound() {
        guard playSounds else { return }
        AudioServicesPlaySystemSound(1004)
    }
    
    
    // MARK: - Alerts
    
    func checkAlerts(newByte byte: UInt8) {
        for alert in alerts {
            // inactive alerts and alerts with no trigger are removed when loading the alerts
            guard !alert.ignore else {
                continue
            }
            
            // out of bounds protection, should never happen
            guard alert.nextCompareIndex < alert.trigger.count else {
                print("Alert nextCompareIndex out of bounds.")
                alert.nextCompareIndex = 0
                continue
            }
            
            // check if new byte matches next byte of trigger
            if alert.trigger[alert.nextCompareIndex] == byte {
                alert.nextCompareIndex += 1
                
                // is full trigger received
                if alert.nextCompareIndex == alert.trigger.count {
                    // alert triggered
                    alert.nextCompareIndex = 0
                    
                    // sound
                    alert.sound.play()

                    // add as triggered alert and call shownext to trigger the alertview
                    triggeredAlerts.append(alert)
                    showNextAlert()
                }
            } else {
                // new byte does not match trigger, reset compare index to zero
                alert.nextCompareIndex = 0
            }
        }
    }
    
    func showNextAlert() {
        // check if no alert is shown and if there is another triggered alert
        guard !isShowingAlert, let alert = triggeredAlerts.first else {
            return
        }
    
        // no longer needed in array
        triggeredAlerts.removeFirst()

        // proceed to next alert if user pressed 'Ignore' or if no alertview is to be shown
        guard !alert.ignore, alert.showAlert else {
            showNextAlert()
            return
        }
        
        // show an alert
        isShowingAlert = true
        
        let alertController = UIAlertController(title: alert.title.isEmpty ? "Unnamed Alert" : alert.title, message: nil, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { _ in
            self.isShowingAlert = false
            self.showNextAlert()
        }))
        
        alertController.addAction(UIAlertAction(title: "Ignore", style: .cancel, handler: { _ in
            alert.ignore = true
            self.isShowingAlert = false
            self.showNextAlert()
        }))
        
        // TODO: Present on top of modal??
        present(alertController, animated: true)
    }
    
    
    // MARK: - TableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count + 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 || indexPath.row == messages.count+1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "whiteCell", for: indexPath)
            cell.selectionStyle = .none
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ChatTableViewCell
            cell.messageText = messages[indexPath.row-1].data.string(withFormat: displayFormat).removeNewline()
            cell.isSent = messages[indexPath.row-1].sent
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 || indexPath.row == messages.count+1 {
            return indexPath.row == 0 ? topWhiteCellHeight : bottomWhiteCellHeight
        } else {
            return ChatTableViewCell.calculateHeight(forText: messages[indexPath.row-1].data.string(withFormat: displayFormat).removeNewline())
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 || indexPath.row == messages.count+1 {
            return indexPath.row == 0 ? topWhiteCellHeight : bottomWhiteCellHeight
        } else {
            return ChatTableViewCell.calculateHeight(forText: messages[indexPath.row-1].data.string(withFormat: displayFormat).removeNewline())
        }
    }
    
    
    // MARK: - BluetoothSerial
    
    func serialDidReceiveData(_ data: Data) {
        playReceivedSound()
        let new = Message(data: data)
        messages.append(new)
        addText(forMessage: new)
        
        for byte in data {
            checkAlerts(newByte: byte)
        }
        
        // done in async queue
        //scrollToBottom()
    }
    
    func serialDidChangeState() {
        if serial.centralManager.state != .poweredOn {
            NotificationCenter.default.post(name: .disconnected)
        }
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: Error?) {
        NotificationCenter.default.post(name: .disconnected)
    }
    
    @objc func serialDidSendData(_ notification: Notification) {
        let data = notification.userInfo!["data"] as! Data
        messages.append(Message(data: data, sent: true))
        addText(forMessage: messages.last!)
        
        let sound = notification.userInfo!["playSound"] as! Bool
        if sound {
            playSentSound()
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func disconnect(_ sender: Any) {
        serial.disconnect()
    }
}


@IBDesignable class GradientView: UIView {
    @IBInspectable var topColor: UIColor = UIColor.white
    @IBInspectable var bottomColor: UIColor = UIColor.black
    
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        (layer as! CAGradientLayer).colors = [topColor.cgColor, bottomColor.cgColor]
    }
}

// Little Hack to make sure \n's get displayed with the correct head indent
extension String {
    fileprivate func removeNewline() -> String {
        return self.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "")
    }
}
