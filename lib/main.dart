import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc_client/model/devices.model.dart';
import 'package:flutter_webrtc_client/webrtc.client.dart';

import 'utils/log.dart';

void main() async {
  // await DotEnv().load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  RTCVideoRenderer remoteVideo = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    initRenderers();
    Future.delayed(const Duration(seconds: 5), () {
      connect();
    });
  }

  initRenderers() async {
    await remoteVideo.initialize();
  }

  @override
  void deactivate() {
    super.deactivate();
    remoteVideo.dispose();
  }

  @override
  void dispose() {
    remoteVideo.dispose();
    super.dispose();
  }

  connect() {
    if (true) {
      String token =
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyZWNpcGllbnQiOiIxNzMiLCJpc1NlcnZlciI6IkZhbHNlIiwiaWQiOiIyMzEiLCJuYmYiOjE2NjkxMDY0MDEsImV4cCI6MTY2OTM2NTYwMSwiaWF0IjoxNjY5MTA2NDAxfQ.SzV3xJUT5kaipB5OsvK81kvfVC87KbZh-gKCbU7jzfk";

      var app = WebRTCClient(null, token, (DeviceSelection offer) async {
        LogConnectionEvent(ConnectionEvent.WaitingAvailableDeviceSelection);
        // var soundcardID = await AskSelectSoundcard(offer.soundcards);
        // Log(LogLevel.Infor, "selected audio deviceid $soundcardID");
        // var DeviceHandle = await AskSelectDisplay(offer.monitors);
        // Log(LogLevel.Infor, "selected monitor handle $DeviceHandle");
        // var bitrate = await AskSelectBitrate();
        // Log(LogLevel.Infor, "selected bitrate $bitrate");
        // var framerate = await AskSelectFramerate();
        // Log(LogLevel.Infor, "selected framerate $framerate");
        // LogConnectionEvent(ConnectionEvent.ExchangingSignalingMessage);

        // return DeviceSelectionResult(bitrate, framerate, soundcard, monitor);

// mute

        var soundcardNone;
        for (var sourdcard in offer.soundcards) {
          if (sourdcard.Api.toLowerCase() == "none") {
            soundcardNone = sourdcard;
          }
        }
        return DeviceSelectionResult(3000, 30, soundcardNone.DeviceID,
            offer.monitors[0].MonitorHandle.toString());
      }).Notifier((message) {
        print("Notifer $message");
        // TurnOnStatus(message);
      }).Alert((message) {
        print("Alert $message");
      });

      app.onRemoteStream = ((stream) {
        if (remoteVideo.srcObject != stream) {
          LogConnectionEvent(ConnectionEvent.ReceivedVideoStream);
          remoteVideo.srcObject = stream;
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter WebRTC Client',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Container(
          height: 400,
          width: 400,
          child: RTCVideoView(remoteVideo),
        ));
  }
}
