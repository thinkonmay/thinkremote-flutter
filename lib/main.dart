import 'package:clipboard/clipboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc_client/model/devices.model.dart';
import 'package:flutter_webrtc_client/utils/popup.selection.dart';
import 'package:flutter_webrtc_client/webrtc.client.dart';

import 'firebase_options.dart';
import 'utils/log.dart';
import 'utils/nv_connection.dart';

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

  double posX = 100;
  double posY = 100;

  double maxHeightVideo = 100;
  double maxWidthVideo = 100;


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
      
      var app =
          WebRTCClient(remoteVideo, null, token, (DeviceSelection offer) async {
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
            maxHeightVideo = remoteVideo.videoHeight.toDouble();
            maxWidthVideo = remoteVideo.videoWidth.toDouble();
          }
        }
        setState(() {});
      });
    }
  }

  Future<void> handleClick(String value) async {
    switch (value) {
      case 'Fullscreen':
        isFullscreen
            ? SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)
            : SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        isFullscreen = !isFullscreen;
        break;
    }
  }

  void onTapDown(BuildContext context, TapDownDetails details) {
    // print('${details.globalPosition}');
    RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localOffset = box.globalToLocal(details.globalPosition);
    setState(() {
      posX = localOffset.dx;
      posY = localOffset.dy;
    });

    // NvConnection().sendMousePosition(
    //     x: posX,
    //     y: posY,
    //     referenceWidth: maxWidthVideo,
    //     referenceHeight: maxHeightVideo);

    // NvConnection().sendMouseMoveAsMousePosition(
    //     deltaX: posX / maxWidthVideo,
    //     deltaY: posY / maxHeightVideo,
    //     referenceWidth: maxWidthVideo,
    //     referenceHeight: maxHeightVideo);

    // NvConnection().sendMouseMove(
    //     deltaX: posX / maxWidthVideo, deltaY: posY / maxHeightVideo);
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
                  return {'Fullscreen'}.map((String choice) {
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
              child: GestureDetector(
                onTapDown: (TapDownDetails details) =>
                    onTapDown(context, details),
                child: RTCVideoView(remoteVideo),
              ),
            )),
        Positioned(
            bottom: 10,
            left: 10,
            child: Text(
                'Dx: ${posX / remoteVideo.videoWidth}, Dy: ${posY / remoteVideo.videoHeight}'))
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
