import 'micro_sensys_platform_interface.dart';

class MicroSensys {
  // Temporary testing methods
  Future<void> scanIOSDevices() {
    return MicroSensysPlatform.instance.scanIOSDevices();
  }

  Future<void> getIOSPairedDevices() {
    return MicroSensysPlatform.instance.getIOSPairedDevices();
  }

  Future<String?> getPlatformVersion() {
    return MicroSensysPlatform.instance.getPlatformVersion();
  }

  Future<bool?> initReader({String? frequencyType, String? communicationType}) {
    return MicroSensysPlatform.instance.initReader(
        frequencyType: frequencyType, communicationType: communicationType);
  }

  Future<bool?> initIOSReader({required String deviceName}) {
    return MicroSensysPlatform.instance.initIOSReader(deviceName: deviceName);
  }

  Future<String?> identifyTag() {
    return MicroSensysPlatform.instance.identifyTag();
  }

  Future<bool?> checkConnected() {
    return MicroSensysPlatform.instance.checkConnected();
  }

  Future<bool?> checkConnecting() {
    return MicroSensysPlatform.instance.checkConnecting();
  }

  Future<bool?> checkInitialized() {
    return MicroSensysPlatform.instance.checkInitialized();
  }

  Future disConnect() {
    return MicroSensysPlatform.instance.disConnect();
  }

  Stream<String> listenTags() {
    return MicroSensysPlatform.instance.listenTags();
  }

  Stream<String> iosListenStatus() {
    return MicroSensysPlatform.instance.iosListenStatus();
  }

  Stream<String> iosListenDevices() {
    return MicroSensysPlatform.instance.iosListenDevices();
  }

  Future<bool?> connect(String deviceIdentifier) {
    return MicroSensysPlatform.instance.connect(deviceIdentifier);
  }

  /// Asks the SDK for the connected reader information.
  ///
  /// The answer arrives asynchronously on [iosListenDeviceInfo].
  Future<bool?> readDeviceInformation() {
    return MicroSensysPlatform.instance.readDeviceInformation();
  }

  /// Serial number of the connected reader.
  ///
  /// Empty until [readDeviceInformation] has completed at least once.
  Future<String?> getReaderSerial() {
    return MicroSensysPlatform.instance.getReaderSerial();
  }

  /// Device information reported by the SDK, keyed by field name
  /// (e.g. `READER_ID`, `BATTERY`).
  Stream<Map<String, String>> iosListenDeviceInfo() {
    return MicroSensysPlatform.instance.iosListenDeviceInfo();
  }
}
