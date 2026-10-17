//
//  ViewController.swift
//  BleRfidDemo
//
//  Created by Michel Rennert on 31.07.23.
//

import UIKit
import microsensys_lib

class PayloadCell: UITableViewCell {
    @IBOutlet var name : UILabel?
}

class ViewController: UIViewController, ShowConnectedDeviceInformationCallback, ShowDeviceBatteryStatusCallback, ShowStatusMessageCallback, ShowResponseMessageCallback, UITableViewDelegate, UITableViewDataSource  {
    
    
    /// Callback to get DEVICE information
    /// - Parameter info: device information
    func ShowConnectedDeviceInformation(info: [String:String]) {
        
        self.responseMessage.removeAll()
        
        for (key, value) in info {
            print("Device Information: \(key):\(value)")
            
            self.responseMessage.append("\(key):\(value)")
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    /// Callback to get Respone information
    /// - Parameter data: response information
    func ShowResponseMessage(data: [String]) {
        
        self.responseMessage = data
        
        for n in data {
            let buf: [UInt8] = Array(n.utf8)
            var recordHEx = buf.map { (data1) -> String in
                return String(format: "%02X ", data1)
            }.joined()
            
            recordHEx.remove(at: recordHEx.index(before: recordHEx.endIndex))
            
            print("Response: \(n)")
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    /// Callback to get BATTERY information
    /// - Parameter status: battery information
    func ShowDeviceBatteryStatus(status: String) {
        
        self.responseMessage.removeAll()
        
        print("Battery: \(status)")
        
        self.responseMessage.append("Battery: \(status)")
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    /// Callback to get STATUS information
    /// - Parameter status: status information
    func ShowStatusMessage(status: String) {
        print("Status: \(status)")
        
        if status.starts(with: "Disconnected") {
            DispatchQueue.main.async {
                self.updateNavigationItem(isConnected: false)
            }
        }
        if status.starts(with: "Connected") {
            DispatchQueue.main.async {
                self.updateNavigationItem(isConnected: true)
            }
        }
    }
    
    var responseMessage: [String] = [String]()
    
    // cell reuse id (cells that scroll out of view can be reused)
    let cellReuseIdentifier = "cell"
    
    @IBOutlet weak var footerImage: UIImageView!
    @IBOutlet var tableView: UITableView!
    
    func updateNavigationItem(isConnected: Bool) {
        let title = isConnected ? "Disconnect" : "Connect"
        let action = isConnected ? #selector(disconnectReader) : #selector(connectReader)
        
        // 1. Wir erstellen einen echten UIButton
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.tintColor = UIColor(named: "MssColor")
        button.addTarget(self, action: action, for: .touchUpInside)
        
        // 2. WICHTIG: Die Größe berechnen lassen
        button.sizeToFit()
        
        // 3. Den Button in ein UIBarButtonItem mit Custom View packen
        let barButtonItem = UIBarButtonItem(customView: button)
        
        // 4. Optional: Dem Button explizite Constraints geben, falls er zu klein ist
        // Aber meistens reicht sizeToFit() bei Custom Views aus, um den 0-Width-Error zu umgehen.
        
        self.navigationItem.setRightBarButtonItems([barButtonItem], animated: true)
    }
    
    
    /// Call view to connect reader via bluetooth
    @objc func connectReader() {
        if let selectServicesController = self.storyboard?.instantiateViewController(withIdentifier: "readerConnect") as? UITableViewController {
            self.present(selectServicesController, animated: true, completion: nil)
        }
    }
    
    /// Disconnect reader
    @objc func disconnectReader() {
        BleRfidLib.shared.DisconnectDevice()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate   = self
        self.tableView.dataSource = self
        
        self.tableView.allowsSelection = false
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = "BLE Reader Demo"
        
        self.updateNavigationItem(isConnected: false)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapFunction))
        self.footerImage.addGestureRecognizer(tap)
        
        
        BleRfidLib.shared.InitShowConnectedDeviceInformationCallback(delegate: self)
        BleRfidLib.shared.InitShowDeviceBatteryStatusCallback(delegate: self)
        BleRfidLib.shared.InitShowStatusMessageCallback(delegate: self)
        BleRfidLib.shared.InitShowResponseMessageCallback(delegate: self)
        
        print("Lib Version: \(microsensys_lib.microsensys_libVersionNumber)")
        
    }

    @objc func tapFunction(sender:UITapGestureRecognizer) {
        print("tap working")
        
        var customTitle: String = "Micro-Sensys GmbH\nIn der Hochstedter Ecke 2\n99098 Erfurt\n\nLibrary Version: \(microsensys_lib.microsensys_libVersionNumber)"
        
        if let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            customTitle += "\nApp Version: \(appVersion)"
        }
        
        let alert = UIAlertController(title: "Information", message: customTitle, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        return
    }
    
    
    /// Read BATTERY information -> Response via Callback
    /// - Parameter sender: sender
    @IBAction func batteryStatus(_ sender: Any) {
        DispatchQueue.main.async {
            
            self.responseMessage.removeAll()
            self.tableView.reloadData()
            
            BleRfidLib.shared.ReadBatteryStatus()
        }
    }
    
    
    /// Read DEVICE information -> Response via Callback
    /// - Parameter sender: sender
    @IBAction func readerInformation(_ sender: Any) {
        DispatchQueue.main.async {
            
            self.responseMessage.removeAll()
            self.tableView.reloadData()
            
            BleRfidLib.shared.ReadDeviceInformation()
        }
    }
    
    @IBAction func antenna1(_ sender: Any) {
        DispatchQueue.main.async {
            
            self.responseMessage.removeAll()
            self.tableView.reloadData()
            
            BleRfidLib.shared.SelectAntenna(antenna: Antenna.Antenna_1)
        }
    }
    
    @IBAction func antenna2(_ sender: Any) {
        DispatchQueue.main.async {
            
            self.responseMessage.removeAll()
            self.tableView.reloadData()
            
            BleRfidLib.shared.SelectAntenna(antenna: Antenna.Antenna_2)
        }
    }
    
    @IBAction func antennaAll(_ sender: Any) {
        DispatchQueue.main.async {
            
            self.responseMessage.removeAll()
            self.tableView.reloadData()
            
            BleRfidLib.shared.SelectAntenna(antenna: Antenna.Antenna_All)
        }
    }
    
    
    /// Read EPC information -> Response via Callback
    /// Function only works if PENsolid PRO in DOC-MODE
    /// - Parameter sender: sender
    @IBAction func identify_withInfo(_ sender: Any) {
        DispatchQueue.main.async {
            
            self.responseMessage.removeAll()
            self.tableView.reloadData()
            
            BleRfidLib.shared.Identify(info: AntennaInfo.Antenna_Info_On)
        }
    }
    
    /// Read EPC information -> Response via Callback
    /// Function only works if PENsolid PRO in DOC-MODE
    /// - Parameter sender: sender
    @IBAction func identify_withoutInfo(_ sender: Any) {
        DispatchQueue.main.async {
            
            self.responseMessage.removeAll()
            self.tableView.reloadData()
                        
            BleRfidLib.shared.Identify(info: AntennaInfo.Antenna_Info_Off)
        }
    }
    
    
    
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///TableView
    // UITableViewAutomaticDimension calculates height of label contents/text
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Swift 4.2 onwards
        return UITableView.automaticDimension
    }
    
    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.responseMessage.count
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // create a new cell if needed or reuse an old one
        guard let cell: PayloadCell = self.tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier, for: indexPath) as? PayloadCell
        else {
            return UITableViewCell()
        }
        
        // set the text from the data model
        cell.name?.text = self.responseMessage[indexPath.row]
        cell.tintColor = .black
        cell.sizeToFit()
        
        return cell
    }
}
