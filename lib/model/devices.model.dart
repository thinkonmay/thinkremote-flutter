import 'dart:convert';

class Soundcard {
  late String DeviceID;
  late String Name;
  late String Api;
  late bool IsDefault;
  late bool IsLoopback;

  Soundcard(dynamic data) {
    DeviceID = data.id;
    Name = data.name;
    Api = data.api;
    IsDefault = data.isDefault;
    IsLoopback = data.isLoopback;
  }
}

class Monitor {
  late int MonitorHandle;
  late String MonitorName;
  late String DeviceName;
  late String Adapter;
  late int Width;
  late int Height;
  late int Framerate;
  late bool IsPrimary;

  Monitor(dynamic data) {
    MonitorHandle = data.handle;
    MonitorName = data.name;
    DeviceName = data.device;
    Adapter = data.adapter;
    Width = data.width;
    Height = data.height;
    Framerate = data.framerate;
    IsPrimary = data.isPrimary;
  }
}

class DeviceSelection {
  late List<Monitor> monitors;
  late List<Soundcard> soundcards;

  DeviceSelection(String data) {
    monitors = <Monitor>[];
    soundcards = <Soundcard>[];

    var parseResult = jsonDecode(data);

    for (var i in parseResult["monitors"]) {
      monitors.add(Monitor(i));
    }
    for (var i in parseResult["soundcards"]) {
      soundcards.add(Soundcard(i));
    }
  }
}

class DeviceSelectionResult {
  late String MonitorHandle;
  late String SoundcardDeviceID;
  late int bitrate;
  late int framerate;

  DeviceSelectionResult(
      int bitrate, int framerate, String soundcard, String monitor) {
    bitrate = bitrate;
    framerate = framerate;
    SoundcardDeviceID = soundcard;
    MonitorHandle = monitor;
  }

  @override
  String toString() {
    return jsonEncode({
      "monitor": this.MonitorHandle,
      "soundcard": this.SoundcardDeviceID,
      "bitrate": this.bitrate,
      "framerate": this.framerate,
    });
  }
}