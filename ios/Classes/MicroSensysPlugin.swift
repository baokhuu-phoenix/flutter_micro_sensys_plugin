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
    var iosDevicesStreamHandler: MyStreamHandler?

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

        // iOS discovered devices
        instance.iosDevicesStreamHandler = MyStreamHandler()

        let eventChannelIOSDevices = FlutterEventChannel(
            name: "micro_sensys_events_ios_devices",
            binaryMessenger: registrar.messenger()
        )

        eventChannelIOSDevices.setStreamHandler(
            instance.iosDevicesStreamHandler
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

            logEvent("scanIOSDevices -> initializing SDK callbacks")
            initializeSDKCallbacks()

            logEvent("scanIOSDevices -> GetPairedDevices")
            BleRfidLib.shared.GetPairedDevices()

            logEvent("scanIOSDevices -> StartDeviceScan")
            BleRfidLib.shared.StartDeviceScan(
                scanDevice: .PenSolidPRO
            )

            logEvent("scanIOSDevices -> StartDeviceScan RETURNED")
            result(nil)

        case "connect":

            guard let arguments = call.arguments as? [String: Any],
                  let deviceIdentifier = arguments["deviceIdentifier"] as? String,
                  !deviceIdentifier.isEmpty else {

                logEvent(
                    "connect ERROR - deviceIdentifier missing"
                )

                result(false)
                return
            }

            connectDevice(
                deviceName: deviceIdentifier,
                result: result
            )

        case "getIOSPairedDevices":
            logEvent("getIOSPairedDevices -> initializing SDK callbacks")
            initializeSDKCallbacks()

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


    private func initializeSDKCallbacks() {

        if isInitialized {
            logEvent("SDK callbacks already initialized")
            return
        }

        logEvent("========== INITIALIZING SDK CALLBACKS ==========")

        BleRfidLib.shared.InitShowListFoundDevicesCallback(
            delegate: self
        )

        BleRfidLib.shared.InitShowListPairedDevicesCallback(
            delegate: self
        )

        BleRfidLib.shared.InitShowDeviceConnectionStatusCallback(
            delegate: self
        )

        BleRfidLib.shared.InitShowConnectedDeviceInformationCallback(
            delegate: self
        )

        BleRfidLib.shared.InitShowDeviceBatteryStatusCallback(
            delegate: self
        )

        BleRfidLib.shared.InitShowStatusMessageCallback(
            delegate: self
        )

        BleRfidLib.shared.InitShowResponseMessageCallback(
            delegate: self
        )

        isInitialized = true

        logState("SDK CALLBACKS INITIALIZED")
    }


    private func connectDevice(
        deviceName: String,
        result: @escaping FlutterResult
    ) {
        logEvent("========== connectDevice ENTER ==========")

        logEvent(
            "connectDevice -> deviceName=[\(deviceName)]"
        )

        currentDeviceName = deviceName

        logState("connectDevice ENTER")

        // Already connected
        if isConnected {
            logEvent(
                "connectDevice -> ALREADY CONNECTED"
            )

            result(true)
            return
        }

        // Connection already in progress
        if isConnecting {
            logEvent(
                "connectDevice -> CONNECTION ALREADY IN PROGRESS"
            )

            result(false)
            return
        }

        // Make sure SDK callbacks are registered.
        initializeSDKCallbacks()

        // TEMPORARY TEST:
        // Do not stop scanning before ConnectDeviceByName.
        // Restore the original behavior after this test.
        // Stop device scanning before attempting to connect.
        //logEvent(
        //    "connectDevice -> STOPPING SDK scan before connection"
        //)

        //BleRfidLib.shared.StopDeviceScan()

        // Start connection
        isConnecting = true

        logState(
            "connectDevice -> BEFORE ConnectDeviceByName"
        )

        logEvent(
            "connectDevice -> CALLING ConnectDeviceByName on MAIN thread"
        )

        DispatchQueue.main.asyncAfter(
            deadline: .now() + .milliseconds(50)
        ) {
            self.logEvent(
                "connectDevice -> ConnectDeviceByName CALL"
            )

            BleRfidLib.shared.ConnectDeviceByName(
                deviceName: deviceName
            )

            self.logEvent(
                "connectDevice -> ConnectDeviceByName RETURNED"
            )

            self.logState(
                "connectDevice -> AFTER ConnectDeviceByName"
            )
        }

        // The actual connection result comes asynchronously through:
        // ShowDeviceConnectionStatus(connected:)
        result(true)

        logEvent(
            "connectDevice -> result(true) returned to Flutter"
        )
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

        logEvent(
            "initIosReader -> deviceName=[\(deviceName)]"
        )

        connectDevice(
            deviceName: deviceName,
            result: result
        )
    }

    // =========================================================================
    // to read the RFID tag
    // =========================================================================
    private func identifyTag(result: @escaping FlutterResult) {
        logState("identifyTag ENTER")

        guard isConnected else {
            debugPrint(
                "MicroSensysPlugin: identifyTag - not connected"
            )
            result(nil)
            return
        }

        BleRfidLib.shared.Identify(
            info: AntennaInfo.Antenna_Info_On
        )

        logEvent("Identify() RETURNED")

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
        logEvent("SDK DEVICE INFO CALLBACK: \(info)")
    }

    // =========================================================================
    //
    // =========================================================================
    public func ShowDeviceBatteryStatus(
        status: String
    ) {

        print("🚨🚨🚨 BATTERY CALLBACK 🚨🚨🚨")
        print("status = \(status)")

        logState(
            "ShowDeviceBatteryStatus CALLBACK"
        )
    }

    // =========================================================================
    //
    // =========================================================================
    public func ShowStatusMessage(status: String) {

        logState("CONNECTION STATUS CHANGED")

        DispatchQueue.main.async {
            self.logEvent(
                "ShowStatusMessage -> sending Flutter event: \(status)"
            )

            self.statusStreamHandler?.eventSink?(
                status
            )
        }
    }

    //=====================
    //=====================
    public func ShowResponseMessage(data: [String]) {

        logEvent("SDK RESPONSE CALLBACK: \(data)")

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

        print("🚨 FOUND DEVICES CALLBACK: \(devices)")
        print("COUNT = \(devices.count)")

        for (index, device) in devices.enumerated() {
            print("[\(index)] = \(device)")
        }

        logState(
            "ShowListFoundDevices CALLBACK"
        )

        DispatchQueue.main.async {

            for device in devices {

                self.logEvent(
                    "ShowListFoundDevices -> sending device to Flutter: \(device)"
                )

                self.iosDevicesStreamHandler?.eventSink?(
                    device
                )
            }
        }
    }


    public func ShowListPairedDevices(devices: [[String: String]]) {
        print("🚨🚨🚨 PAIRED DEVICES CALLBACK 🚨🚨🚨")
        print("COUNT = \(devices.count)")

        DispatchQueue.main.async {
            for device in devices {
                print("Paired device: \(device)")

                guard let name = device["device"], !name.isEmpty else {
                    continue
                }

                self.logEvent(
                    "ShowListPairedDevices -> sending device to Flutter: \(name)"
                )

                self.iosDevicesStreamHandler?.eventSink?(name)
            }
        }

        logState("ShowListPairedDevices CALLBACK")
    }


    public func ShowDeviceConnectionStatus(connected: Bool) {
        logEvent("ShowDeviceConnectionStatus: connected=\(connected)")

        isConnected = connected
        isConnecting = false

        if connected {
            BleRfidLib.shared.StopDeviceScan()
        }

        logState("CONNECTION CALLBACK AFTER UPDATE")

        let status = connected ? "CONNECTED" : "DISCONNECTED"

        DispatchQueue.main.async {
            self.statusStreamHandler?.eventSink?(status)
        }
    }
}