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

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePage();
}

class _MyHomePage extends State<MyHomePage> {
  RTCVideoRenderer remoteVideo = RTCVideoRenderer();

  TextEditingController tokenCtrler = TextEditingController();

  @override
  void initState() {
    super.initState();
    initRenderers();
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

  connect(String token) {
    if (token.isNotEmpty) {
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


        // late Soundcard soundcardNone;
        // for (var sourdcard in offer.soundcards) {
        //   if (sourdcard.Api.toLowerCase() == "none") {
        //     soundcardNone = sourdcard;
        //   }
        // }
        return DeviceSelectionResult(
            3000, 60, "none", offer.monitors[0].MonitorHandle.toString());
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
      home: Scaffold(
          appBar: AppBar(title: const Text('Flutter WebRTC Client')),
          floatingActionButton: FloatingActionButton(
            onPressed: () => displayTextInputDialog(context),
            child: const Icon(Icons.add),
          ), //
          body: OrientationBuilder(builder: (context, orientation) {
            return renderVideoWidget(context);
          })),
    );
  }

  Container renderVideoWidget(BuildContext context) {
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
  }

  void displayTextInputDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Please fill your token!'),
            content: TextField(
              controller: tokenCtrler,
              decoration: InputDecoration(
                  hintText: "Your token",
                  suffixIcon: InkWell(
                    onTap: (){
                       tokenCtrler.clear();
                    },
                    child: const Icon(Icons.close_rounded),
                  )),
            ),
            actions: [
              MaterialButton(
                color: Colors.red,
                textColor: Colors.white,
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              MaterialButton(
                color: Colors.green,
                textColor: Colors.white,
                child: const Text('OK'),
                onPressed: () {
                  connect(tokenCtrler.text);
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }
}
