import 'package:clipboard/clipboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc_remote_desktop/flutter_webrtc_remote_desktop.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // await DotEnv().load(fileName: '.env');
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: const MyHomePage(),
      initialRoute: "/",
      routes: <String, WidgetBuilder>{
        "/test": (context) => _DynamicLinkScreen(),
      },
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
  bool isFullscreen = false;

  late WebRTCClient app;

  @override
  void initState() {
    super.initState();
    initDynamicLinks();
    initRenderers();
  }

  Future<void> initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      var token = dynamicLinkData.link.toString().split("?")[1].split("=")[1];
      if (token != "") {
        connect(token);
      } else {
        print('token is empty');
      }
    }).onError((error) {
      print('onLink error');
      print(error.message);
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

  connect(String token) {
    if (token.isNotEmpty) {
      app = WebRTCClient(
          "wss://remote.thinkmay.net/handshake", remoteVideo, null, token,
          (DeviceSelection offer) async {
        LogConnectionEvent(ConnectionEvent.WaitingAvailableDeviceSelection);

        DeviceSelectionResult requestOptionDevice =
            DeviceSelectionResult(null, null);

        requestOptionDevice.SoundcardDeviceID = await showAlertDeviceSelection(
          data: offer.soundcards,
          type: TypeDeviceSelection.soundcard,
          deviceSelectionResult: requestOptionDevice,
          context: context,
        );

        Log(LogLevel.Infor,
            "selected audio deviceid ${requestOptionDevice.SoundcardDeviceID}");

        requestOptionDevice.MonitorHandle = await showAlertDeviceSelection(
          data: offer.monitors,
          type: TypeDeviceSelection.monitor,
          deviceSelectionResult: requestOptionDevice,
          context: context,
        );

        requestOptionDevice.bitrate = await showAlertDeviceSelection(
            data: [500, 1000, 2000, 3000, 6000, 8000, 10000],
            type: TypeDeviceSelection.bitrate,
            deviceSelectionResult: requestOptionDevice,
            context: context);

        requestOptionDevice.framerate = await showAlertDeviceSelection(
            data: [30, 40, 50, 55, 60],
            type: TypeDeviceSelection.framerate,
            deviceSelectionResult: requestOptionDevice,
            context: context);

        Log(LogLevel.Infor,
            "selected monitor handle ${requestOptionDevice.MonitorHandle}");
        return requestOptionDevice;
      }).Notifier((message) {
        print("Notifer $message");
        // TurnOnStatus(message);
      }).Alert((message) {
        print("Alert $message");
      });

      app.onRemoteStream = ((RTCTrackEvent evt) async {
        if (evt.track.kind == "video") {
          if (remoteVideo.srcObject != evt.streams[0]) {
            LogConnectionEvent(ConnectionEvent.ReceivedVideoStream);
            remoteVideo.srcObject = evt.streams[0];
          }
        }
        setState(() {});
      });
    }
  } 

  Future<void> handleClick(String value) async {
    switch (value) {
      case 'Reset Video':
        app.ResetVideo();
        break;
      case 'Fullscreen': 
        isFullscreen
            ? SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)
            : SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        isFullscreen = !isFullscreen;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebRTC Client',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Flutter WebRTC Client'),
            actions: <Widget>[
              PopupMenuButton<String>(
                onSelected: handleClick,
                itemBuilder: (BuildContext context) {
                  return {'Fullscreen', 'Reset Video'}.map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(choice),
                    );
                  }).toList();
                },
              ),
            ],
          ),
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

  void displayTextInputDialog(BuildContext context) async {
    tokenCtrler.text = await FlutterClipboard.paste();
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
                    onTap: () {
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

class _DynamicLinkScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hello World DeepLink'),
        ),
        body: const Center(
          child: Text('Hello, World!'),
        ),
      ),
    );
  }
}
