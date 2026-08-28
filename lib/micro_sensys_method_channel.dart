import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'micro_sensys_platform_interface.dart';

/// An implementation of [MicroSensysPlatform] that uses method channels.
class MethodChannelMicroSensys extends MicroSensysPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('micro_sensys');

  final EventChannel eventChannel = const EventChannel('micro_sensys_events');
  final EventChannel eventChannelStatus =
      const EventChannel('micro_sensys_events_status');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool?> initReader({String? frequencyType, String? communicationType}) {
    var params = {
      'frequencyType': frequencyType ?? 'UHF',
      'communicationType': communicationType ?? 'BLE',
    };
    return methodChannel.invokeMethod<bool>('initReader', params);
  }

  @override
  Future<bool?> initIOSReader({required String deviceName}) {
    return methodChannel
        .invokeMethod<bool>('initIOSReader', {'deviceName': deviceName});
  }

  @override
  Future<String?> identifyTag() {
    return methodChannel.invokeMethod<String?>('identifyTag');
  }

  @override
  Future<bool?> checkConnected() {
    return methodChannel.invokeMethod<bool>('checkConnected');
  }

  @override
  Future<bool?> checkInitialized() {
    return methodChannel.invokeMethod<bool>('checkInitialized');
  }

  @override
  Future<bool?> checkConnecting() {
    return methodChannel.invokeMethod<bool>('checkConnecting');
  }

  @override
  Future<void> disConnect() {
    return methodChannel.invokeMethod<void>('disConnect');
  }

  @override
  Stream<String> listenTags() {
    return eventChannel.receiveBroadcastStream().cast<String>();
  }

  @override
  Stream<String> iosListenStatus() {
    return eventChannelStatus.receiveBroadcastStream().cast<String>();
  }

  @override
  Future<bool?> connect(String deviceIdentifier) {

    debugPrint(
      'MethodChannelMicroSensys.connect(): '
          'deviceIdentifier=[$deviceIdentifier], '
          'length=${deviceIdentifier.length}',
    );

    return methodChannel.invokeMethod<bool>(
      'connect',
      {
        'deviceIdentifier': deviceIdentifier,
      },
    );
  }
}
