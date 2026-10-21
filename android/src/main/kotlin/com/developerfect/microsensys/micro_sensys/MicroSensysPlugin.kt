package com.developerfect.microsensys.micro_sensys

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import de.microsensys.exceptions.MssException
import de.microsensys.functions.RFIDFunctions
import de.microsensys.utils.ProtocolTypeEnum
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class MicroSensysPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var reader: RFIDFunctions? = null

    override fun onAttachedToEngine(
        flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "micro_sensys"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE} - OK-")
            }

            "initReader" -> initReader(result, call)
            "connect" -> connect(result, call)
            "identifyTag" -> identifyTag(result)
            "checkConnected" -> checkConnected(result)
            "checkInitialized" -> checkInitialized(result)
            "checkConnecting" -> checkConnecting(result)
            "disConnect" -> disConnect(result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(
        binding: FlutterPlugin.FlutterPluginBinding
    ) {
        channel.setMethodCallHandler(null)
        try {
            reader?.let {
                if (it.isConnected) {
                    it.terminate()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error while closing RFID reader", e)
        } finally {
            reader = null
        }
    }

    // -------------------------------------------------------------------------
    // Reader initialization
    // -------------------------------------------------------------------------

    @SuppressLint("LongLogTag")
    private fun initReader(result: Result, call: MethodCall) {
        try {
            val args = call.arguments as? Map<*, *>
            if (args == null) {
                result.error("INVALID_ARGUMENTS", "Expected a map of reader arguments", null)
                return
            }

            val interfaceTypeString = args["frequencyType"] as? String
            val portTypeString = args["communicationType"] as? String
            val deviceIdentifier = args["deviceIdentifier"] as? String

            if (interfaceTypeString.isNullOrBlank()) {
                result.error("INVALID_FREQUENCY_TYPE", "frequencyType is required", null)
                return
            }
            if (portTypeString.isNullOrBlank()) {
                result.error("INVALID_COMMUNICATION_TYPE", "communicationType is required", null)
                return
            }
            if (deviceIdentifier.isNullOrBlank()) {
                result.error("INVALID_DEVICE_IDENTIFIER", "deviceIdentifier is required", null)
                return
            }

            Log.d(TAG, "initReader(): frequencyType=$interfaceTypeString")
            Log.d(TAG, "initReader(): communicationType=$portTypeString")
            Log.d(TAG, "initReader(): deviceIdentifier=$deviceIdentifier")

            val newReader = RFIDFunctions(
                context,
                HelperFunctions().getPortTypeFromString(portTypeString)
            )
            newReader.protocolType = ProtocolTypeEnum.Protocol_v4
            newReader.interfaceType =
                HelperFunctions().getInterfaceTypeFromString(interfaceTypeString)

            // Set the port name before initialize().
            newReader.setPortName(deviceIdentifier)
            Log.d(TAG, "initReader(): portName=${newReader.portName}")

            newReader.initialize()
            reader = newReader

            result.success(true)
        } catch (e: MssException) {
            Log.e(TAG, "initReader(): MicroSensys exception", e)
            result.error("INIT_READER_ERROR", e.message ?: e.toString(), e.toString())
        } catch (e: Exception) {
            Log.e(TAG, "initReader(): unexpected exception", e)
            result.error("INIT_READER_ERROR", e.message ?: e.toString(), e.toString())
        }
    }

    // -------------------------------------------------------------------------
    // Connect
    // -------------------------------------------------------------------------

    @SuppressLint("LongLogTag")
    private fun connect(result: Result, call: MethodCall) {
        try {
            val args = call.arguments as? Map<*, *>
            val deviceIdentifier = args?.get("deviceIdentifier") as? String

            if (deviceIdentifier.isNullOrBlank()) {
                result.error(
                    "CONNECT_INVALID_IDENTIFIER",
                    "deviceIdentifier is null or empty",
                    null
                )
                return
            }

            Log.d(TAG, "connect(): deviceIdentifier=$deviceIdentifier")

            val newReader = RFIDFunctions(
                context,
                HelperFunctions().getPortTypeFromString("BLE")
            )
            newReader.protocolType = ProtocolTypeEnum.Protocol_v4
            newReader.interfaceType =
                HelperFunctions().getInterfaceTypeFromString("UHF")
            newReader.setPortName(deviceIdentifier)

            Log.d(TAG, "connect(): portName=${newReader.portName}")
            newReader.initialize()
            reader = newReader

            Log.d(TAG, "connect(): initialize() completed")
            result.success(true)
        } catch (e: MssException) {
            Log.e(TAG, "connect(): MicroSensys exception", e)
            result.error("CONNECT_ERROR", e.message ?: e.toString(), e.toString())
        } catch (e: Exception) {
            Log.e(TAG, "connect(): unexpected exception", e)
            result.error("CONNECT_ERROR", e.message ?: e.toString(), e.toString())
        }
    }

    // -------------------------------------------------------------------------
    // Identify RFID tag
    // -------------------------------------------------------------------------

    @SuppressLint("LongLogTag")
    private fun identifyTag(result: Result) {
        val activeReader = reader
        if (activeReader == null) {
            result.error("IDENTIFY_READER_NULL", "Reader is not initialized", null)
            return
        }

        if (!activeReader.isConnected) {
            result.error("IDENTIFY_NOT_CONNECTED", "Reader is not connected", null)
            return
        }

        Log.d(TAG, "identifyTag(): calling reader.identify()")

        try {
            // Call identify() once and return the tag ID to Flutter.
            val uid: ByteArray? = activeReader.identify()

            if (uid == null || uid.isEmpty()) {
                Log.w(TAG, "identifyTag(): identify() returned no UID")
                result.error("IDENTIFY_EMPTY", "identify() returned no UID", null)
                return
            }

            Log.d(TAG, "identifyTag(): UID bytes=${uid.contentToString()}")
            Log.d(TAG, "identifyTag(): UID size=${uid.size}")

            val rfid = HelperFunctions().bytesToHexStr(uid)
                ?: run {
                    Log.e(TAG, "identifyTag(): failed to convert UID to HEX")
                    result.error("IDENTIFY_ERROR", "Failed to convert UID to HEX", null)
                    return
                }

            Log.d(TAG, "identifyTag(): RFID HEX=[$rfid], length=${rfid.length}")

            result.success(rfid)
        } catch (e: MssException) {
            Log.e(TAG, "identifyTag(): MicroSensys exception", e)
            result.error("IDENTIFY_ERROR", e.message ?: e.toString(), e.toString())
        } catch (e: Exception) {
            Log.e(TAG, "identifyTag(): unexpected exception", e)
            result.error("IDENTIFY_ERROR", e.message ?: e.toString(), e.toString())
        }
    }

    // -------------------------------------------------------------------------
    // Reader status
    // -------------------------------------------------------------------------

    private fun checkConnected(result: Result) {
        result.success(reader?.isConnected == true)
    }

    private fun checkInitialized(result: Result) {
        result.success(reader != null)
    }

    private fun checkConnecting(result: Result) {
        result.success(reader?.isConnecting == true)
    }

    // -------------------------------------------------------------------------
    // Disconnect
    // -------------------------------------------------------------------------

    private fun disConnect(result: Result) {
        val activeReader = reader
        if (activeReader == null) {
            result.success(false)
            return
        }

        try {
            if (activeReader.isConnected) {
                activeReader.terminate()
                Log.d(TAG, "disConnect(): reader terminated")
                result.success(true)
            } else {
                Log.d(TAG, "disConnect(): reader is not connected")
                result.success(false)
            }
        } catch (e: Exception) {
            Log.e(TAG, "disConnect(): error while terminating reader", e)
            result.error("DISCONNECT_ERROR", e.message ?: e.toString(), e.toString())
        } finally {
            reader = null
        }
    }

    private companion object {
        const val TAG = "MicroSensysPlugin"
    }
}

