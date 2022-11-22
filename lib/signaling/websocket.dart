// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_webrtc_client/model/signaling.model.dart';
import 'package:flutter_webrtc_client/utils/log.dart';

typedef PacketHandlerType = void Function({Map<String, String> Data});

class SignallingClient {
  late WebSocket WebSocketConnection;
  var PacketHandler;
  // Function()? onOpen;
  Function(dynamic msg)? onMessage;
  Function(int? code, String? reaso)? onClose;

  SignallingClient(String url, String token, PacketHandlerType PacketHandler) {
    this.PacketHandler = PacketHandler;
    LogConnectionEvent(ConnectionEvent.WebSocketConnecting);
    setup(url, token);
  }

  setup(url, token) async {
    WebSocketConnection = await _connectForSelfSignedCert("$url?token=$token");
    // onOpen?.call();
    WebSocketConnection.listen((data) {
      onServerMessage(data);
    }, onDone: () {
      onClose?.call(
          WebSocketConnection.closeCode, WebSocketConnection.closeReason);
    });
    // WebSocketConnection.onOpen.listen((e) => onServerOpen(e));
  }

  /*
     * Fired whenever the signalling websocket is opened.
     * Sends the peer id to the signalling server.
     */
  // onServerOpen(event) {
  //   LogConnectionEvent(ConnectionEvent.WebSocketConnected);
  //   WebSocketConnection.onError.listen((e) {
  //     Log(LogLevel.Error, "websocket connection error : ${e.type}");
  //     onServerError();
  //   });

  //   WebSocketConnection.onMessage.listen((e) {
  //     onServerMessage(e);
  //   });

  //   WebSocketConnection.onClose.listen((e) {
  //     Log(LogLevel.Error, "websocket connection closed : ${e.type}");
  //     onServerError();
  //   });
  // }

  /*
     * send messsage to signalling server
     * @param {string} request_type 
     * @param {any} content 
     */
  SignallingSend(String Target, Map<String, String> Data) {
    var dat = UserRequest(0, Target, <String, String>{}, Data).toString();
    Log(LogLevel.Debug, "sending message : $dat");
    WebSocketConnection.add(dat);
  }

  /*
     * Fired whenever the signalling websocket emits and error.
     * Reconnects after 3 seconds.
     */
  onServerError() {
    Log(LogLevel.Warning, "websocket connection disconnected");
    LogConnectionEvent(ConnectionEvent.WebSocketDisconnected);
  }

  /*
     * handle message from signalling server during connection handshake
     * @param {Event} event 
     * @returns 
     */
  onServerMessage(event) {
    var msg = jsonDecode(event);
    var response = UserResponse(
        msg['id'], msg['error'], Map<String, String>.from(msg['data']));
    Log(LogLevel.Debug, "received signaling message: ${response.toString()}");
    PacketHandler(Data: response.Data);
  }

  Future<WebSocket> _connectForSelfSignedCert(url) async {
    try {
      Random r = Random();
      String key = base64.encode(List<int>.generate(8, (_) => r.nextInt(255)));
      HttpClient client = HttpClient(context: SecurityContext());
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        print(
            'SimpleWebSocket: Allow self-signed certificate => $host:$port. ');
        return true;
      };

      HttpClientRequest request =
          await client.getUrl(Uri.parse(url)); // form the correct url here
      request.headers.add('Connection', 'Upgrade');
      request.headers.add('Upgrade', 'websocket');
      request.headers.add(
          'Sec-WebSocket-Version', '13'); // insert the correct version here
      request.headers.add('Sec-WebSocket-Key', key.toLowerCase());

      HttpClientResponse response = await request.close();
      // ignore: close_sinks
      Socket socket = await response.detachSocket();
      var webSocket = WebSocket.fromUpgradedSocket(
        socket,
        protocol: 'signaling',
        serverSide: false,
      );

      return webSocket;
    } catch (e) {
      throw e;
    }
  }
}
