# FlutterWebrtc 

### Peer to peer battery included WebRTC client for mobile build on flutter

# Dependencies
  - Framework
    - [Flutter: 3.0.0](https://docs.flutter.dev/get-started/install)
  - API
    - [RTCVideoRenderer](https://pub.dev/documentation/simplewebrtc_flutter_webrtc_shim/latest/rtc_video_view/RTCVideoRenderer-class.html)
    - [RTCPeerConnection](https://pub.dev/documentation/webrtc/latest/rtc_peerconnection/RTCPeerConnection-class.html)
  - UI
    - Flutter

# Repository Structure
```
|-- lib
    | main.dart                     | main
    | models                        | Data model
    | signaling                     | websocket signaling adapter (based on socket)
    | utils                         | Other utilities module
    | webrtc                        | WebRTC class wrap around 
    | webrtc.client                 | Application object wrap around all modules
```

# Usage
- `git clone https://github.com/OnePlay-Internet/flutter-webrtc-client.git`
- `cd flutter-webrtc-client`
- `flutter packages get`
- `flutter run`

## Requirement
- Android NDK 23.2.8568313
- CMake
- Flutter 3.3.0
- Daemon
- Access to service.thinkmay.net