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
  }

  initRenderers() async {
    await remoteVideo.initialize();
    connect();
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
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyZWNpcGllbnQiOiIxODMiLCJpc1NlcnZlciI6IkZhbHNlIiwiaWQiOiIyOTMiLCJuYmYiOjE2NjkxODk2ODEsImV4cCI6MTY2OTQ0ODg4MSwiaWF0IjoxNjY5MTg5NjgxfQ.hLIUie2dlyzW_-mji_7_FRytyhWEwgLJMiqtB9nYsb0";

      var app =
          WebRTCClient(remoteVideo, null, token, (DeviceSelection offer) async {
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

        // late Soundcard soundcardNone;
        // for (var sourdcard in offer.soundcards) {
        //   if (sourdcard.Api.toLowerCase() == "none") {
        //     soundcardNone = sourdcard;
        //   }
        // }
        return DeviceSelectionResult(
            3000, 30, "none", offer.monitors[0].MonitorHandle.toString());
      }).Notifier((message) {
        print("Notifer $message");
        // TurnOnStatus(message);
      }).Alert((message) {
        print("Alert $message");
      });

      app.onRemoteStream = ((stream) {
        if (remoteVideo.srcObject != stream) {
          // LogConnectionEvent(ConnectionEvent.ReceivedVideoStream);
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
        home: OrientationBuilder(builder: (context, orientation) {
          return Container(
            child: Stack(children: <Widget>[
              Positioned(
                  left: 0.0,
                  right: 0.0,
                  top: 0.0,
                  bottom: 0.0,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    decoration: const BoxDecoration(color: Colors.black54),
                    child: RTCVideoView(remoteVideo),
                  )),
            ]),
          );
        }));
  }
}
