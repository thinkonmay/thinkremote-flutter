import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as LibWebRTC;
import 'package:flutter_webrtc_client/main.dart';
import 'package:flutter_webrtc_client/model/devices.model.dart' as Device;
import 'package:flutter_webrtc_client/signaling/websocket.dart';
import 'package:flutter_webrtc_client/webrtc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as LibWebRTC;

import 'utils/log.dart';

typedef AlertType = void Function(String input);
typedef DeviceSelectionType = Future<Device.DeviceSelectionResult> Function(
    Device.DeviceSelection input);

class WebRTCClient {
  // final SIGNALLING_URL = DotEnv().get('NEXT_PUBLIC_SIGNALING_URL').isNotEmpty
  //     ? dotenv.get('NEXT_PUBLIC_SIGNALING_URL')
  //     : 'wss://remote.thinkmay.net/handshake';

  late dynamic audio;

  late WebRTC webrtc;
  // final HID hid;
  var signaling;
  // final Map<String, DataChannel> datachannels;

  late DeviceSelectionType DeviceSelection;
  late AlertType alert;

  late bool started;

  WebRTCClient(
    this.audio,
    String token,
    this.DeviceSelection,
  ) {
    Log(LogLevel.Infor, "Started oneplay app with token $token");
    LogConnectionEvent(ConnectionEvent.ApplicationStarted);
    this.started = false;
    // this.datachannels = new Map<string,DataChannel>();
    // this.hid = new HID(this.video,((data: string) => {
    //     let channel = this.datachannels.get("hid")
    //     if (channel == null) {
    //         Log(LogLevel.Warning,"attempting to send message while data channel is not established");
    //         return;
    //     }
    //     channel.sendMessage(data);
    // }));

    signaling = SignallingClient("https://remote.thinkmay.net/handshake", token,
        ({Map<String, String>? Data}) => handleIncomingPacket(Data!));

    webrtc = WebRTC(({data, target}) {
      SignallingClient signaling = this.signaling;
      signaling.SignallingSend(target!, data!);
    }, (ev) {
      handleIncomingTrack(ev);
    }, (ev) {
      handleIncomingDataChannel(ev);
    });
  }

  handleIncomingTrack(
      LibWebRTC.RTCTrackEvent evt) {
    started = true;
    Log(LogLevel.Infor, "Incoming ${evt.track.kind} stream");
    // if (evt.track.kind == "audio") {
    //   if (audio.current.srcObject != evt.streams[0]) {
    //     LogConnectionEvent(ConnectionEvent.ReceivedAudioStream);
    //     audio.current.srcObject = evt.streams[0];
    //   }
    // } else 
    if (evt.track.kind == "video") {
        onRemoteStream?.call(evt.streams[0]);
    }
  }

  handleIncomingDataChannel(LibWebRTC.RTCDataChannel a) {
    LogConnectionEvent(ConnectionEvent.ReceivedDatachannel);
    Log(LogLevel.Infor, "incoming data channel: ${a.label}");
    if (a != LibWebRTC.RTCDataChannel) {
      return;
    }

    // this.datachannels.set(a.label, new DataChannel(a,(data) => {
    //     Log(LogLevel.Debug, "message from data channel ${a.label}: ${d ata}");
    // }));
  }

  handleIncomingPacket(Map<String, String> pkt) async {
    var target = pkt["Target"];
    if (target == "SDP") {
      var sdp = pkt["SDP"];
      if (sdp == null) {
        Log(LogLevel.Error, "missing sdp");
        return;
      }
      var type = pkt["Type"];
      if (type == null) {
        Log(LogLevel.Error, "missing sdp type");
        return;
      }

      webrtc.onIncomingSDP(LibWebRTC.RTCSessionDescription(
          sdp, (type == "offer") ? "offer" : "answer"));
    } else if (target == "ICE") {
      var sdpmid = pkt["SDPMid"];
      if (sdpmid == null) {
        Log(LogLevel.Error, "Missing sdp mid field");
      }
      var lineidx = pkt["SDPMLineIndex"];
      if (lineidx == null) {
        Log(LogLevel.Error, "Missing sdp line index field");
        return;
      }
      var can = pkt["Candidate"];
      if (can == null) {
        Log(LogLevel.Error, "Missing sdp candidate field");
        return;
      }

      webrtc.onIncomingICE(
          LibWebRTC.RTCIceCandidate(can, sdpmid, int.parse(lineidx)));
    } else if (target == "PREFLIGHT") {
      //TODO
      var preverro = pkt["Error"];
      if (preverro != null) {
        Log(LogLevel.Error, preverro);
        alert(preverro);
      }

      var i = Device.DeviceSelection(pkt["Devices"]!);
      var result = await DeviceSelection(i);
      var dat = <String, String>{};
      dat["type"] = "answer";
      dat["monitor"] = result.MonitorHandle;
      dat["soundcard"] = result.SoundcardDeviceID;
      dat["bitrate"] = "${result.bitrate}";
      dat["framerate"] = "${result.framerate}";
      signaling.SignallingSend("PREFLIGHT", dat);
    } else if (target == "START") {
      var dat = <String, String>{};
      signaling.SignallingSend("START", dat);
    }
  }

  WebRTCClient Notifier(void Function(String message) notifier) {
    AddNotifier(notifier);
    return this;
  }

  WebRTCClient Alert(void Function(String message) notifier) {
    alert = notifier;
    return this;
  }

  Function(LibWebRTC.MediaStream stream)? onRemoteStream;
}
