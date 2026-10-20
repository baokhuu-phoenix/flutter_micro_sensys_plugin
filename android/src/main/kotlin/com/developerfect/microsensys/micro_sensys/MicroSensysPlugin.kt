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

/** MicroSensysPlugin */
class MicroSensysPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var reader: RFIDFunctions? = null

    override fun onAttachedToEngine(
        flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "micro_sensys"
        )

        context = flutterPluginBinding.applicationContext
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {

            "getPlatformVersion" -> {
                result.success(
                    "Android ${android.os.Build.VERSION.RELEASE} - OK-"
                )
            }

            "initReader" -> {
                initReader(result, call)
            }

            "connect" -> {
                connect(result, call)
            }

            "identifyTag" -> {
                identifyTag(result)
            }

            "checkConnected" -> {
                checkConnected(result)
            }

            "checkInitialized" -> {
                checkInitialized(result)
            }

            "checkConnecting" -> {
                checkConnecting(result)
            }

            "disConnect" -> {
                disConnect(result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(
        binding: FlutterPlugin.FlutterPluginBinding
    ) {
    @SuppressLint("LongLogTag")
    private fun connect(result: Result, call: MethodCall) {
        try {
            val args = call.arguments as? Map<String, Any>

            val deviceIdentifier =
                args?.get("deviceIdentifier") as? String

            if (deviceIdentifier.isNullOrEmpty()) {
                result.error(
                    "CONNECT_INVALID_IDENTIFIER",
                    "deviceIdentifier is null or empty",
                    null
                )
                return
            }

            Log.d(
                "MicroSensysPlugin",
                "connect(): deviceIdentifier=$deviceIdentifier"
            )

            reader = RFIDFunctions(
                context,
                HelperFunctions().getPortTypeFromString("BLE")
            )

            reader!!.protocolType =
                ProtocolTypeEnum.Protocol_v4

            reader!!.interfaceType =
                HelperFunctions().getInterfaceTypeFromString("UHF")

            reader!!.setPortName(deviceIdentifier)

            Log.d(
                "MicroSensysPlugin",
                "connect(): portName=${reader!!.portName}"
            )

            reader!!.initialize()

            Log.d(
                "MicroSensysPlugin",
                "connect(): initialize() completed"
            )

            result.success(true)

        } catch (e: MssException) {
            Log.e(
                "MicroSensysPlugin",
                "connect(): MssException",
                e
            )

            result.error(
                "CONNECT_ERROR",
                e.toString(),
                e.toString()
            )

        } catch (e: Exception) {
            Log.e(
                "MicroSensysPlugin",
                "connect(): Exception",
                e
            )

            result.error(
                "CONNECT_ERROR",
                e.toString(),
                e.toString()
            )
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // =========================================================================
    // RFID Functions
    // =========================================================================

    @SuppressLint("LongLogTag")
    private fun initReader(
        result: Result,
        call: MethodCall
    ) {
        try {
            val args = call.arguments as Map<String, Any>

            // UHF, HF
            val interfaceTypeString =
                args["frequencyType"] as String

            // BluetoothLE, BLE, USB
            val portTypeString =
                args["communicationType"] as String

            // DEVICE IDENTIFIER
            val deviceIdentifier =
                args["deviceIdentifier"] as? String ?: "PEN"

            if (deviceIdentifier.isNullOrEmpty()) {
                result.error(
                    "INVALID_DEVICE_IDENTIFIER",
                    "deviceIdentifier is required",
                    null
                )
                return
            }

            Log.d(
                "MicroSensysPlugin",
                "interfaceType=$interfaceTypeString"
            )

            Log.d(
                "MicroSensysPlugin",
                "portType=$portTypeString"
            )

            Log.d(
                "MicroSensysPlugin",
                "deviceIdentifier=$deviceIdentifier"
            )

            reader = RFIDFunctions(
                context,
                HelperFunctions().getPortTypeFromString(
                    portTypeString
                )
            )

            reader!!.protocolType =
                ProtocolTypeEnum.Protocol_v4

            reader!!.interfaceType =
                HelperFunctions().getInterfaceTypeFromString(
                    interfaceTypeString
                )

            // Must happen before initialize()
            reader!!.setPortName(deviceIdentifier)

            Log.d(
                "MicroSensysPlugin",
                "Initializing reader with portName=${reader!!.portName}"
            )

            reader!!.initialize()

            result.success(true)

        } catch (e: MssException) {

            Log.e(
                "MicroSensysPlugin",
                "initReader(): MssException",
                e
            )

            result.error(
                "1",
                e.toString(),
                e.toString()
            )

        } catch (e: Exception) {

            Log.e(
                "MicroSensysPlugin",
                "initReader(): Exception",
                e
            )

            result.error(
                "1",
                e.toString(),
                e.toString()
            )
        }
    }

    // =========================================================================
    // identifyTag
    // =========================================================================

    @SuppressLint("LongLogTag")
    private fun identifyTag(result: Result) {
        if (reader == null) {
            result.error(
                "IDENTIFY_READER_NULL",
                "Reader is not initialized",
                null
            )
            return
        }

        Log.d(
            "MicroSensysPlugin",
            "========== identifyTag() START =========="
        )

        try {

            // -----------------------------------------------------------------
            // Check reader
            // -----------------------------------------------------------------

            if (reader == null) {

                Log.e(
                    "MicroSensysPlugin",
                    "identifyTag(): reader == null"
                )

                result.error(
                    "IDENTIFY_ERROR",
                    "Reader is not initialized",
                    null
                )

                return
            }

        if (reader?.isConnected != true) {
            result.error(
                "IDENTIFY_NOT_CONNECTED",
                "Reader is not connected",
                null
            )
            return
        }
            // -----------------------------------------------------------------
            // Check connection
            // -----------------------------------------------------------------

            val connected =
                reader?.isConnected == true

            Log.d(
                "MicroSensysPlugin",
                "identifyTag(): reader.isConnected=$connected"
            )

            if (!connected) {

                Log.e(
                    "MicroSensysPlugin",
                    "identifyTag(): Reader is NOT connected"
                )

                result.error(
                    "IDENTIFY_NOT_CONNECTED",
                    "Reader is not connected",
                    null
                )

                return
            }

        try {
            // -----------------------------------------------------------------
            // Identify
            // -----------------------------------------------------------------

            // IMPORTANT:
            // Call identify() ONLY ONCE.
            Log.d(
                "MicroSensysPlugin",
                "identifyTag(): calling reader.identify()"
            )

            val uid = reader!!.identify()
            val uid: ByteArray? =
                reader!!.identify()

            Log.d(
                "MicroSensysPlugin",
                "identifyTag(): identify() returned ${uid?.size ?: 0} bytes"
            )

            // -----------------------------------------------------------------
            // Check result
            // -----------------------------------------------------------------

            if (uid == null) {

                Log.e(
                    "MicroSensysPlugin",
                    "identifyTag(): UID is NULL"
                )

                result.error(
                    "IDENTIFY_EMPTY",
                    "identify() returned null",
                    null
                )

                return
            }

            val uidHex = HelperFunctions().bytesToHexStr(uid)
            // -----------------------------------------------------------------
            // Log raw bytes
            // -----------------------------------------------------------------

            Log.d(
                "MicroSensysPlugin",
                "identifyTag(): UID bytes=${uid.contentToString()}"
            )

            Log.d(
                "MicroSensysPlugin",
                "identifyTag(): UID size=${uid.size}"
            )

            // -----------------------------------------------------------------
            // Convert to HEX
            // -----------------------------------------------------------------

            val rfid =
                HelperFunctions().bytesToHexStr(uid)

            Log.d(
                "MicroSensysPlugin",
                "identifyTag(): RFID HEX=[$rfid]"
            )

            Log.d(
                "MicroSensysPlugin",
                "identifyTag(): UID/EPC=$uidHex"
                "identifyTag(): RFID length=${rfid?.length}"
            )

            result.success(uidHex)
            // -----------------------------------------------------------------
            // Send RFID back to Flutter
            // -----------------------------------------------------------------

            result.success(rfid)

            Log.d(
                "MicroSensysPlugin",
                "========== identifyTag() END =========="
            )

        } catch (e: MssException) {
            Log.e(
                "MicroSensysPlugin",
                "identifyTag(): MssException: ${e}",
                e
            )
        } catch (e: MssException) {

            Log.e(
                "MicroSensysPlugin",
                "identifyTag(): MssException class=${e.javaClass.name}"
            )

            Log.e(
                "MicroSensysPlugin",
                "identifyTag(): MssException message=${e.message}"
            )

            Log.e(
                "MicroSensysPlugin",
                "identifyTag(): MssException localizedMessage=${e.localizedMessage}"
            )

            Log.e(
                "MicroSensysPlugin",
                "identifyTag(): MssException toString=$e"
            )

            e.printStackTrace()

            result.error(
                "IDENTIFY_ERROR",
                e.toString(),
                e.toString()
            )
            result.error(
                "IDENTIFY_ERROR",
                e.message ?: e.toString(),
                e.toString()
            )

        } catch (e: Exception) {
            Log.e(
                "MicroSensysPlugin",
                "identifyTag(): Exception: ${e}",
                e
            )
        } catch (e: Exception) {

            Log.e(
                "MicroSensysPlugin",
                "identifyTag(): Exception class=${e.javaClass.name}"
            )

            Log.e(
                "MicroSensysPlugin",
                "identifyTag(): Exception message=${e.message}"
            )

            Log.e(
                "MicroSensysPlugin",
                "identifyTag(): Exception localizedMessage=${e.localizedMessage}"
            )

            Log.e(
                "MicroSensysPlugin",
                "identifyTag(): Exception toString=$e"
            )

            e.printStackTrace()

            result.error(
                "IDENTIFY_ERROR",
                e.toString(),
                e.toString()
            )
        }
            result.error(
                "IDENTIFY_ERROR",
                e.message ?: e.toString(),
                e.toString()
            )
        }
    }

    // =========================================================================
    // checkConnected
    // =========================================================================

    private fun checkConnected(result: Result) {
        if (reader?.isConnected == true) {
            result.success(true)
        } else {
            result.success(false)
        }
    }
    // endregion checkConnected

    // =========================================================================
    // checkInitialized
    // =========================================================================

    private fun checkInitialized(result: Result) {
        if (reader != null) {
            result.success(true)
        } else {
            result.success(false)
        }
    }

    // =========================================================================
    // checkConnecting
    // =========================================================================

    // region checkInitialized
    private fun checkConnecting(result: Result) {
        if (reader?.isConnecting == true) {
            result.success(true)
        } else {
            result.success(false)
        }
    }

    // =========================================================================
    // disConnect
    // =========================================================================

    private fun disConnect(result: Result) {
        if (reader != null && reader?.isConnected == true) {
            reader?.terminate();
        } else {

            Log.d(
                "MicroSensysPlugin",
                "disConnect(): Reader is not connected"
            )

            result.success(false)
        }
    }
}