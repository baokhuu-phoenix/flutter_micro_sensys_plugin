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

  Future<bool?> connect(String deviceIdentifier) {
    print(
      '### MicroSensys.connect() CALLED '
      'deviceIdentifier=[$deviceIdentifier] ###',
    );

    return MicroSensysPlatform.instance.connect(deviceIdentifier);
  }
}
