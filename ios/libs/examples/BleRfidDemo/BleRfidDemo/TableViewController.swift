//
//  TableViewController.swift
//  TELIDnfcDemo
//
//  Created by Michel Rennert on 16.02.23.
//

import UIKit
import microsensys_lib

class TableViewController: UITableViewController, ShowListPairedDevicesCallback, ShowListFoundDevicesCallback, ShowDeviceConnectionStatusCallback {
    
    
    func ShowListPairedDevices(devices: [[String : String]]) {
        print("\(devices)")
        for dev in devices {
            if let index: Int = self.devices.firstIndex(where: { $0["name"] == dev["device"] }) {
                self.devices[index]["status"] = dev["status"]
            } else {
                if let n = dev["device"], let s = dev["status"] {
                    let dict: [String:String] = ["name":n,"status":s]
                    self.devices.append(dict)
                }
            }
        }
        self.devices = (self.devices as NSArray).sortedArray(using: [NSSortDescriptor(key: "name", ascending: true)]) as! [[String:String]]

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func ShowListFoundDevices(devices: [String]) {
        
        let status: String = "Not paired"
        for dev in devices {
            
            if let index: Int = self.devices.firstIndex(where: { $0["name"] == dev }) {
                self.devices[index]["status"] = status
            } else {
                let dict: [String:String] = ["name":dev,"status":status]
                self.devices.append(dict)
            }
        }
        self.devices = (self.devices as NSArray).sortedArray(using: [NSSortDescriptor(key: "name", ascending: true)]) as! [[String:String]]
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func ShowDeviceConnectionStatus(connected: Bool) {
        
        print("Connected: \(connected)")
        
        if !connected {
            self.timer.invalidate()
            // BleRfidLib.shared.StartDeviceScan(scanDevice: ScanDevice.PenSolidPRO)
        } else {
            BleRfidLib.shared.StopDeviceScan()
            DispatchQueue.main.async {
                // start the timer
                self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.cancelConnectionController), userInfo: nil, repeats: false)
            }
        }
    }
    
    // called every time interval from the timer
    @objc func cancelConnectionController() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    var devices: [[String:String]] = [[String:String]]() //["name":"devName","status":"status"]
    var timer: Timer               = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.devices.removeAll()
        
        BleRfidLib.shared.InitShowListPairedDevicesCallback(delegate: self)
        BleRfidLib.shared.InitShowListFoundDevicesCallback(delegate: self)
        BleRfidLib.shared.InitShowDeviceConnectionStatusCallback(delegate: self)
        
        BleRfidLib.shared.GetPairedDevices()
        
        BleRfidLib.shared.StartDeviceScan(scanDevice: ScanDevice.PenSolidPRO)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        BleRfidLib.shared.StopDeviceScan()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Found Devices"
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.devices.count // (section == 0) ? self.scannedDevices.count : self.connectedDevices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text       = self.devices[indexPath.row]["name"]
        cell.detailTextLabel?.text = self.devices[indexPath.row]["status"]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        DispatchQueue.global().asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(50), execute: {
            if let n = self.devices[indexPath.row]["name"] {
                BleRfidLib.shared.ConnectDeviceByName(deviceName: n)
            }
        })
    }
}
