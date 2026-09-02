import Flutter
import UIKit
import microsensys_lib

public class MicroSensysPlugin: NSObject,
    FlutterPlugin,
    ShowListFoundDevicesCallback,
    ShowListPairedDevicesCallback,
    ShowDeviceConnectionStatusCallback,
    ShowConnectedDeviceInformationCallback,
    ShowDeviceBatteryStatusCallback,
    ShowStatusMessageCallback,
    ShowResponseMessageCallback {

    // =========================================================================
    // State
    // =========================================================================

    var isInitialized = false
    var isConnecting = false
    var isConnected = false

    var currentDeviceName: String?

    var streamHandler: MyStreamHandler?
    var statusStreamHandler: MyStreamHandler?

    // =========================================================================
    // Registration
    // =========================================================================

    public static func register(with registrar: FlutterPluginRegistrar) {

        let channel = FlutterMethodChannel(
            name: "micro_sensys",
            binaryMessenger: registrar.messenger()
        )

        let instance = MicroSensysPlugin()

        registrar.addMethodCallDelegate(
            instance,
            channel: channel
        )

        // RFID tag events
        instance.streamHandler = MyStreamHandler()

        let eventChannel = FlutterEventChannel(
            name: "micro_sensys_events",
            binaryMessenger: registrar.messenger()
        )

        eventChannel.setStreamHandler(instance.streamHandler)

        // Status events
        instance.statusStreamHandler = MyStreamHandler()

        let eventChannelStatus = FlutterEventChannel(
            name: "micro_sensys_events_status",
            binaryMessenger: registrar.messenger()
        )

        eventChannelStatus.setStreamHandler(
            instance.statusStreamHandler
        )
    }

    // =========================================================================
    // Method channel
    // =========================================================================

    public func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {

        debugPrint(
            "MicroSensysPlugin.handle(): \(call.method)"
        )

        switch call.method {

        case "initIOSReader":
            initIosReader(call: call, result: result)

        case "scanIOSDevices":
            print("MicroSensysPlugin: Starting iOS PENsolid scan")
            BleRfidLib.shared.StartDeviceScan(scanDevice: .PenSolidPRO)
            result(nil)

        case "getIOSPairedDevices":
            print("MicroSensysPlugin: Getting iOS paired devices")
            BleRfidLib.shared.GetPairedDevices()
            result(nil)

        case "disConnect":
            debugPrint(
                "MicroSensysPlugin: disConnect requested"
            )

    isConnecting = false
    isConnected = false

    BleRfidLib.shared.DisconnectDevice()

    DispatchQueue.main.async {
        self.statusStreamHandler?.eventSink?(
            "Disconnected"
        )
    }

    result(nil)

case "identifyTag":
    identifyTag(result: result)

case "checkConnected":
    debugPrint(
        "MicroSensysPlugin: checkConnected = \(isConnected)"
    )

    result(isConnected)

case "checkConnecting":
    result(isConnecting)

case "checkInitialized":
    result(isInitialized)

        default:

            result(FlutterMethodNotImplemented)
        }
    }

    // =========================================================================
    // iOS reader initialization
    // =========================================================================
    public func initIosReader(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
) {
    guard let arguments = call.arguments as? [String: Any],
          let deviceName = arguments["deviceName"] as? String,
          !deviceName.isEmpty else {

        debugPrint(
            "MicroSensysPlugin: initIOSReader ERROR - deviceName missing"
        )

        result(false)
        return
    }

    debugPrint("==============================================")
    debugPrint("MicroSensysPlugin: initIOSReader")
    debugPrint("DeviceName: \(deviceName)")
    debugPrint("isInitialized: \(isInitialized)")
    debugPrint("isConnecting: \(isConnecting)")
    debugPrint("isConnected: \(isConnected)")
    debugPrint("==============================================")

    currentDeviceName = deviceName

    // Already connected
    if isConnected {
        debugPrint(
            "MicroSensysPlugin: ALREADY CONNECTED"
        )

        result(true)
        return
    }

    // Connection already in progress
    if isConnecting {
        debugPrint(
            "MicroSensysPlugin: CONNECTION ALREADY IN PROGRESS"
        )

        result(false)
        return
    }

    // Initialize SDK callbacks only once
    if !isInitialized {

        BleRfidLib.shared.InitShowListFoundDevicesCallback(delegate: self)
        BleRfidLib.shared.InitShowListPairedDevicesCallback(delegate: self)
        BleRfidLib.shared.InitShowDeviceConnectionStatusCallback(delegate: self)

        debugPrint(
            "MicroSensysPlugin: INITIALIZING SDK CALLBACKS"
        )

        BleRfidLib.shared
            .InitShowConnectedDeviceInformationCallback(
                delegate: self
            )

        BleRfidLib.shared
            .InitShowDeviceBatteryStatusCallback(
                delegate: self
            )

        BleRfidLib.shared
            .InitShowStatusMessageCallback(
                delegate: self
            )

        BleRfidLib.shared
            .InitShowResponseMessageCallback(
                delegate: self
            )

        isInitialized = true

        debugPrint(
            "MicroSensysPlugin: SDK CALLBACKS INITIALIZED"
        )
    }

    isConnecting = true

    debugPrint(
        "MicroSensysPlugin: CONNECT START -> \(deviceName)"
    )

    DispatchQueue.main.async {
        debugPrint(
            "MicroSensysPlugin: CALLING ConnectDeviceByName"
        )

        BleRfidLib.shared.ConnectDeviceByName(
            deviceName: deviceName
        )

        debugPrint(
            "MicroSensysPlugin: ConnectDeviceByName RETURNED"
        )
    }

    // This only means the connect request was started.
    result(true)
}


    // =========================================================================
    // RFID identification
    // =========================================================================

    private func identifyTag(
        result: @escaping FlutterResult
    ) {

        guard isConnected else {

            debugPrint(
                "MicroSensysPlugin: identifyTag - not connected"
            )

            result(nil)
            return
        }

        debugPrint(
            "MicroSensysPlugin: identifyTag"
        )

        BleRfidLib.shared.Identify(
            info: AntennaInfo.Antenna_Info_On
        )

        // The actual RFID response comes through:
        //
        // ShowResponseMessage(data:)
        //
        // Therefore the MethodChannel result is only acknowledging
        // that the command was sent.
        result(nil)
    }

    // =========================================================================
    // Disconnect
    // =========================================================================

    private func disconnect(
        result: @escaping FlutterResult
    ) {

        debugPrint(
            "MicroSensysPlugin: disconnect"
        )

        isConnecting = false
        isConnected = false

        BleRfidLib.shared.DisconnectDevice()

        statusStreamHandler?.eventSink?(
            "Disconnected"
        )

        result(nil)
    }

    // =========================================================================
    // Reader initialization
    // =========================================================================

    private func initReader(
        result: FlutterResult
    ) {

        debugPrint(
            "MicroSensysPlugin: initReader"
        )

        result(true)
    }

    // =========================================================================
    // Device discovery / debug
    // =========================================================================

    private func showDevice() {

        debugPrint(
            "MicroSensysPlugin: showDevice"
        )

        streamHandler?.eventSink?(
            "SHOWDEVICE"
        )
    }

    // =========================================================================
    // MicroSensys callbacks
    // =========================================================================

    public func ShowConnectedDeviceInformation(
    info: [String : String]
) {
    debugPrint(
        "========== MICRO SENSYS CONNECTED =========="
    )

    debugPrint(
        "Connected Device Info: \(info)"
    )

    debugPrint(
        "============================================="
    )

    isConnecting = false
    isConnected = true

    DispatchQueue.main.async {
        self.statusStreamHandler?.eventSink?(
            "CONNECTED"
        )
    }
}

    public func ShowDeviceBatteryStatus(
        status: String
    ) {

        debugPrint(
            "MicroSensysPlugin: Device Battery Status: \(status)"
        )
    }

public func ShowStatusMessage(
    status: String
) {
    debugPrint("==============================================")
    debugPrint("MICRO SENSYS STATUS CALLBACK")
    debugPrint("STATUS: [\(status)]")
    debugPrint("isConnecting BEFORE: \(isConnecting)")
    debugPrint("isConnected BEFORE: \(isConnected)")
    debugPrint("==============================================")

    let normalizedStatus = status.lowercased()

    if normalizedStatus.contains("disconnect") {
        isConnected = false
        isConnecting = false

        debugPrint(
            "MicroSensysPlugin: DISCONNECTED -> resetting state"
        )
    }

    DispatchQueue.main.async {
        self.statusStreamHandler?.eventSink?(
            status
        )
    }
}

    public func ShowResponseMessage(
        data: [String]
    ) {

        debugPrint(
            "MicroSensysPlugin: Response Message: \(data)"
        )

        guard let first = data.first,
              !first.isEmpty else {
            return
        }

        let tag = first.uppercased()

        debugPrint(
            "MicroSensysPlugin: RFID TAG = \(tag)"
        )

        DispatchQueue.main.async {
            self.streamHandler?.eventSink?(
                tag
            )
        }
    }

public func ShowListFoundDevices(devices: [String]) {
    print("========== MicroSensys FOUND DEVICES ==========")
    print("Count: \(devices.count)")

    for (index, device) in devices.enumerated() {
        print("[\(index)] \(device)")
    }

    print("================================================")
}

public func ShowListPairedDevices(devices: [[String: String]]) {
    print("========== MicroSensys PAIRED DEVICES ==========")
    print("Count: \(devices.count)")

    for (index, device) in devices.enumerated() {
        print("[\(index)] \(device)")
    }

    print("=================================================")
}

public func ShowDeviceConnectionStatus(connected: Bool) {
    print("========== MicroSensys CONNECTION STATUS ==========")
    print("Connected: \(connected)")
    print("====================================================")

    isConnected = connected
    isConnecting = !connected
}

}