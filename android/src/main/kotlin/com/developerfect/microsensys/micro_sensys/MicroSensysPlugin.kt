package com.developerfect.microsensys.micro_sensys

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import de.microsensys.exceptions.MssException
import de.microsensys.functions.RFIDFunctions
import de.microsensys.utils.InterfaceTypeEnum
import de.microsensys.utils.PortTypeEnum
import de.microsensys.utils.ProtocolTypeEnum

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** MicroSensysPlugin */
class MicroSensysPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    private lateinit var context: Context
    private var reader: RFIDFunctions? = null


    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "micro_sensys")
        context = flutterPluginBinding.applicationContext
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {

        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE} - OK-")
            }

            "initReader" -> {
                initReader(result, call)
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

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    //region RFID Functions
    @SuppressLint("LongLogTag")
    private fun initReader(result: Result, call: MethodCall) {
        try {
            val args = call.arguments as Map<String, Any>;

            //UHF, HF
            val interfaceTypeString = args["frequencyType"] as String

            //BluetoothLE, BLE,USB
            val portTypeString = args["communicationType"] as String

            //DEVICE IDENTIFIER
            val deviceIdentifier = args["deviceIdentifier"] as? String ?: "PEN"

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

            reader = RFIDFunctions(context, HelperFunctions().getPortTypeFromString(portTypeString))
            reader!!.protocolType = ProtocolTypeEnum.Protocol_v4
            reader!!.interfaceType = HelperFunctions().getInterfaceTypeFromString(interfaceTypeString)

            // Bao - Test: Set the port name before initializing the reader
            // Must happen before initialize()
            reader!!.setPortName(deviceIdentifier)

            Log.d(
                "MicroSensysPlugin",
                "Initializing reader with portName=${reader!!.portName}"
            )

            reader!!.initialize()
            result.success(true)
        } catch (e: MssException) {
            result.error("1", e.toString(), e.toString())
            e.printStackTrace()
        } catch (e: Exception) {
            result.error("1", e.toString(), e.toString())
            e.printStackTrace()
        } finally {

        }
    }

    // endregion RFID Functions

    // region identifyReader
    @SuppressLint("LongLogTag")
    private fun identifyTag(result: Result) {
        Log.d("MicroSensysPlugin", "========== identifyTag() START ==========")

        try {
            // Check reader
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

            // Check connection
            val connected = reader?.isConnected == true

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

            // IMPORTANT:
            // Call identify() ONLY ONCE.
            Log.d(
                "MicroSensysPlugin",
                "identifyTag(): Calling reader.identify()..."
            )

            val uid: ByteArray? = reader!!.identify()

            Log.d(
                "MicroSensysPlugin",
                "identifyTag(): identify() returned"
            )

            // Check result
            if (uid == null) {
                Log.e(
                    "MicroSensysPlugin",
                    "identifyTag(): UID is NULL"
                )

                result.error(
                    "IDENTIFY_ERROR",
                    "RFID identify returned null",
                    null
                )
                return
            }

            // Log raw bytes
            Log.d(
                "MicroSensysPlugin",
                "identifyTag(): UID bytes=${uid.contentToString()}"
            )

            Log.d(
                "MicroSensysPlugin",
                "identifyTag(): UID size=${uid.size}"
            )

            // Convert to HEX string
            val rfid = HelperFunctions().bytesToHexStr(uid)

            Log.d(
                "MicroSensysPlugin",
                "identifyTag(): RFID HEX=[$rfid]"
            )

            Log.d(
                "MicroSensysPlugin",
                "identifyTag(): RFID length=${rfid.length}"
            )

            // Send RFID back to Flutter
            result.success(rfid)

            Log.d(
                "MicroSensysPlugin",
                "========== identifyTag() END =========="
            )

        } } catch (e: MssException) {

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
            e.message ?: e.toString(),
            e.toString()
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
            e.message ?: e.toString(),
            e.toString()
        )
    }
    }
    // endregion identifyReader

    // region checkConnected
    private fun checkConnected(result: Result) {
        if (reader?.isConnected == true) {
            result.success(true)
        } else {
            result.success(false)
        }
    }
    // endregion checkConnected

    // region checkInitialized
    private fun checkInitialized(result: Result) {
        if (reader != null) {
            result.success(true)
        } else {
            result.success(false)
        }
    }
    // endregion checkInitialized


    // region checkInitialized
    private fun checkConnecting(result: Result) {
        if (reader?.isConnecting == true) {
            result.success(true)
        } else {
            result.success(false)
        }
    }
    // endregion checkInitialized

    // region checkConnected
    private fun disConnect(result: Result) {
        if (reader != null && reader?.isConnected == true) {
            reader?.terminate();
        } else {
            result.error("3", "Reader is not connected", "Reader is not connected")
        }
    }
    // endregion checkConnected
}
