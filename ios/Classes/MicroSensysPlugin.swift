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
    // Diagnostic logging
    // =========================================================================

    private func logState(_ location: String) {
        let thread = Thread.isMainThread ? "MAIN" : "BACKGROUND"

        debugPrint(
            """
            🔍 [STATE] \(location)
            🔍 [STATE] thread       = \(thread)
            🔍 [STATE] initialized  = \(isInitialized)
            🔍 [STATE] connecting   = \(isConnecting)
            🔍 [STATE] connected    = \(isConnected)
            🔍 [STATE] device       = \(currentDeviceName ?? "nil")
            """
        )
    }

    private func logEvent(_ message: String) {
        let thread = Thread.isMainThread ? "MAIN" : "BACKGROUND"

        debugPrint(
            "🔍 [EVENT] \(message) | thread=\(thread)"
        )
    }

    // =========================================================================
    // Registration
    // =========================================================================

    public static func register(with registrar: FlutterPluginRegistrar) {

        debugPrint("🔍 [REGISTER] MicroSensysPlugin.register()")

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

        debugPrint("🔍 [REGISTER] MicroSensysPlugin.register() COMPLETE")
    }

    // =========================================================================
    // Method channel
    // =========================================================================

    public func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {

        debugPrint(
            "🔍 [HANDLE] MicroSensysPlugin.handle(): \(call.method)"
        )

        logState("BEFORE handle(\(call.method))")

        switch call.method {

        case "initIOSReader":
            initIosReader(
                call: call,
                result: result
            )

        case "scanIOSDevices":
            logEvent("scanIOSDevices -> StartDeviceScan")

            BleRfidLib.shared.StartDeviceScan(
                scanDevice: .PenSolidPRO
            )

            result(nil)

        case "getIOSPairedDevices":
            logEvent("getIOSPairedDevices -> GetPairedDevices")

            BleRfidLib.shared.GetPairedDevices()

            result(nil)

        case "disConnect":
            debugPrint(
                "MicroSensysPlugin: disConnect requested"
            )

            logEvent("disConnect -> manually resetting state")

            isConnecting = false
            isConnected = false

            logState("AFTER manual state reset in disConnect")

            logEvent("disConnect -> CALLING DisconnectDevice()")

            BleRfidLib.shared.DisconnectDevice()

            logEvent("disConnect -> DisconnectDevice() RETURNED")

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

            logState("checkConnected")

            result(isConnected)

        case "checkConnecting":
            debugPrint(
                "MicroSensysPlugin: checkConnecting = \(isConnecting)"
            )

            logState("checkConnecting")

            result(isConnecting)

        case "checkInitialized":
            debugPrint(
                "MicroSensysPlugin: checkInitialized = \(isInitialized)"
            )

            logState("checkInitialized")

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

        logEvent("========== initIosReader ENTER ==========")

        guard let arguments = call.arguments as? [String: Any],
              let deviceName = arguments["deviceName"] as? String,
              !deviceName.isEmpty else {

            logEvent(
                "initIosReader ERROR - deviceName missing"
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

        logState("initIosReader ENTER")

        currentDeviceName = deviceName

        logEvent(
            "currentDeviceName set to \(deviceName)"
        )

        // ---------------------------------------------------------------------
        // Already connected
        // ---------------------------------------------------------------------

        if isConnected {

            logEvent(
                "initIosReader -> ALREADY CONNECTED -> returning true"
            )

            result(true)
            return
        }

        // ---------------------------------------------------------------------
        // Connection already in progress
        // ---------------------------------------------------------------------

        if isConnecting {

            logEvent(
                "initIosReader -> CONNECTION ALREADY IN PROGRESS -> returning false"
            )

            logState("initIosReader blocked by isConnecting")

            result(false)
            return
        }

        // ---------------------------------------------------------------------
        // Initialize SDK callbacks only once
        // ---------------------------------------------------------------------

        if !isInitialized {

            logEvent(
                "initIosReader -> STARTING SDK CALLBACK INITIALIZATION"
            )

            logEvent(
                "InitShowListFoundDevicesCallback"
            )

            BleRfidLib.shared.InitShowListFoundDevicesCallback(
                delegate: self
            )

            logEvent(
                "InitShowListFoundDevicesCallback RETURNED"
            )

            logEvent(
                "InitShowListPairedDevicesCallback"
            )

            BleRfidLib.shared.InitShowListPairedDevicesCallback(
                delegate: self
            )

            logEvent(
                "InitShowListPairedDevicesCallback RETURNED"
            )

            logEvent(
                "InitShowDeviceConnectionStatusCallback"
            )

            BleRfidLib.shared.InitShowDeviceConnectionStatusCallback(
                delegate: self
            )

            logEvent(
                "InitShowDeviceConnectionStatusCallback RETURNED"
            )

            logEvent(
                "InitShowConnectedDeviceInformationCallback"
            )

            BleRfidLib.shared
            .InitShowConnectedDeviceInformationCallback(
                delegate: self
            )

            logEvent(
                "InitShowConnectedDeviceInformationCallback RETURNED"
            )

            logEvent(
                "InitShowDeviceBatteryStatusCallback"
            )

            BleRfidLib.shared
            .InitShowDeviceBatteryStatusCallback(
                delegate: self
            )

            logEvent(
                "InitShowDeviceBatteryStatusCallback RETURNED"
            )

            logEvent(
                "InitShowStatusMessageCallback"
            )

            BleRfidLib.shared
            .InitShowStatusMessageCallback(
                delegate: self
            )

            logEvent(
                "InitShowStatusMessageCallback RETURNED"
            )

            logEvent(
                "InitShowResponseMessageCallback"
            )

            BleRfidLib.shared
            .InitShowResponseMessageCallback(
                delegate: self
            )

            logEvent(
                "InitShowResponseMessageCallback RETURNED"
            )

            isInitialized = true

            logState(
                "SDK CALLBACKS INITIALIZED"
            )

        } else {

            logEvent(
                "initIosReader -> SDK callbacks already initialized"
            )
        }

        // ---------------------------------------------------------------------
        // Start connection
        // ---------------------------------------------------------------------

        logEvent(
            "initIosReader -> setting isConnecting = true"
        )

        isConnecting = true

        logState(
            "AFTER setting isConnecting = true"
        )

        debugPrint(
            "MicroSensysPlugin: CONNECT START -> \(deviceName)"
        )

        // =========================================================================
        // TEST 1
        //
        // Previously ConnectDeviceByName() was called from:
        //
        // DispatchQueue.global().asyncAfter(...)
        //
        // That meant the SDK connection call happened on a background thread.
        //
        // For this test, call ConnectDeviceByName() directly on the main thread.
        // This lets us determine whether the MicroSensys SDK requires its
        // connection API to be called from the main thread.
        // =========================================================================

        logEvent(
            "TEST 1 -> CALLING ConnectDeviceByName on MAIN thread"
        )

        logState(
            "TEST 1 -> BEFORE ConnectDeviceByName"
        )

        debugPrint(
            "MicroSensysPlugin: TEST 1 -> CALLING ConnectDeviceByName"
        )

        BleRfidLib.shared.ConnectDeviceByName(
            deviceName: deviceName
        )

        logEvent(
            "TEST 1 -> ConnectDeviceByName RETURNED"
        )

        logState(
            "TEST 1 -> AFTER ConnectDeviceByName"
        )

        // This means the connect request was started.
        logEvent(
            "initIosReader -> returning result(true)"
        )

        result(true)

        logState(
            "initIosReader EXIT"
        )
    }

    // =========================================================================
    // RFID identification
    // =========================================================================

    private func identifyTag(
        result: @escaping FlutterResult
    ) {

        logState("identifyTag ENTER")

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

        logEvent(
            "Identify() CALL"
        )

        BleRfidLib.shared.Identify(
            info: AntennaInfo.Antenna_Info_On
        )

        logEvent(
            "Identify() RETURNED"
        )

        result(nil)
    }

    // =========================================================================
    // Disconnect
    // =========================================================================

    private func disconnect(
        result: @escaping FlutterResult
    ) {

        logEvent("disconnect() ENTER")

        logState("disconnect BEFORE")

        isConnecting = false
        isConnected = false

        logState("disconnect AFTER state reset")

        logEvent(
            "disconnect -> CALLING DisconnectDevice()"
        )

        BleRfidLib.shared.DisconnectDevice()

        logEvent(
            "disconnect -> DisconnectDevice() RETURNED"
        )

        statusStreamHandler?.eventSink?(
            "Disconnected"
        )

        result(nil)

        logEvent("disconnect() EXIT")
    }

    // =========================================================================
    // Reader initialization
    // =========================================================================

    private func initReader(
        result: FlutterResult
    ) {

        logEvent("initReader()")

        debugPrint(
            "MicroSensysPlugin: initReader"
        )

        result(true)
    }

    // =========================================================================
    // Device discovery / debug
    // =========================================================================

    private func showDevice() {

        logEvent("showDevice()")

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
        info: [String: String]
    ) {

        print("🚨🚨🚨 CONNECTED DEVICE INFO CALLBACK 🚨🚨🚨")
        print("info = \(info)")

        logState(
            "ShowConnectedDeviceInformation CALLBACK"
        )
    }

    public func ShowDeviceBatteryStatus(
        status: String
    ) {

        print("🚨🚨🚨 BATTERY CALLBACK 🚨🚨🚨")
        print("status = \(status)")

        logState(
            "ShowDeviceBatteryStatus CALLBACK"
        )
    }

    public func ShowStatusMessage(
        status: String
    ) {

        print("🚨🚨🚨 STATUS MESSAGE CALLBACK 🚨🚨🚨")
        print("status = [\(status)]")
        print("device = \(currentDeviceName ?? "nil")")

        logState(
            "ShowStatusMessage CALLBACK"
        )

        DispatchQueue.main.async {
            self.logEvent(
                "ShowStatusMessage -> sending Flutter event: \(status)"
            )

            self.statusStreamHandler?.eventSink?(
                status
            )
        }
    }

    public func ShowResponseMessage(
        data: [String]
    ) {

        print("🚨🚨🚨 RESPONSE MESSAGE CALLBACK 🚨🚨🚨")
        print("data = \(data)")

        logState(
            "ShowResponseMessage CALLBACK"
        )

        guard let first = data.first,
              !first.isEmpty else {

            logEvent(
                "ShowResponseMessage -> empty response"
            )

            return
        }

        DispatchQueue.main.async {

            self.logEvent(
                "ShowResponseMessage -> sending Flutter RFID event: \(first)"
            )

            self.streamHandler?.eventSink?(
                first.uppercased()
            )
        }
    }

    public func ShowListFoundDevices(
        devices: [String]
    ) {

        print("🚨🚨🚨 FOUND DEVICES CALLBACK 🚨🚨🚨")
        print("COUNT = \(devices.count)")

        for (index, device) in devices.enumerated() {
            print("[\(index)] = \(device)")
        }

        logState(
            "ShowListFoundDevices CALLBACK"
        )
    }

    public func ShowListPairedDevices(
        devices: [[String: String]]
    ) {

        print("🚨🚨🚨 PAIRED DEVICES CALLBACK 🚨🚨🚨")
        print("COUNT = \(devices.count)")

        for (index, device) in devices.enumerated() {
            print("[\(index)] = \(device)")
        }

        logState(
            "ShowListPairedDevices CALLBACK"
        )
    }

    public func ShowDeviceConnectionStatus(
        connected: Bool
    ) {

        print("🚨🚨🚨 CONNECTION STATUS CALLBACK 🚨🚨🚨")
        print("connected = \(connected)")
        print("device = \(currentDeviceName ?? "nil")")
        print("isConnecting BEFORE = \(isConnecting)")
        print("isConnected BEFORE = \(isConnected)")

        logEvent(
            "ShowDeviceConnectionStatus CALLBACK ENTER: connected=\(connected)"
        )

        logState(
            "ShowDeviceConnectionStatus BEFORE state update"
        )

        // ---------------------------------------------------------------------
        // SDK has reported the connection result.
        // ---------------------------------------------------------------------

        isConnected = connected
        isConnecting = false

        let status = connected
                ? "CONNECTED"
                : "DISCONNECTED"

        print("STATUS = \(status)")
        print("isConnecting AFTER = \(isConnecting)")
        print("isConnected AFTER = \(isConnected)")

        logState(
            "ShowDeviceConnectionStatus AFTER state update"
        )

        DispatchQueue.main.async {

            self.logEvent(
                "ShowDeviceConnectionStatus -> sending Flutter event: \(status)"
            )

            self.statusStreamHandler?.eventSink?(
                status
            )
        }

        logEvent(
            "ShowDeviceConnectionStatus CALLBACK EXIT"
        )
    }
}