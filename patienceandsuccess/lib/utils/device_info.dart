import 'dart:io';

class DeviceInfo {
  static String get label {
    return Platform.localHostname + '(' + Platform.operatingSystem + ")";
  }

  static String get userAgent {
    print(Platform.operatingSystem);
    return 'flutter-webrtc/' + Platform.operatingSystem + '-plugin 0.0.1';
  }
}
