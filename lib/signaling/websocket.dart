
import 'dart:convert';
import 'dart:html';

import 'package:flutter_webrtc_client/model/signaling.model.dart';
import 'package:flutter_webrtc_client/signaling/websocket_web.dart';

typedef PacketHandlerType = void Function({Map<String, String> Data});
class SignallingClient
{
  late WebSocket WebSocketConnection;
  late PacketHandlerType PacketHandler;

  SignallingClient(
    String url,
    String token,
    PacketHandlerType PacketHandler){
      PacketHandler = PacketHandler;
        // LogConnectionEvent(ConnectionEvent.WebSocketConnecting)
        WebSocketConnection = WebSocket("$url?token=$token");
        WebSocketConnection.onOpen.listen((Event e) => onServerOpen(e));
    }

    /*
     * Fired whenever the signalling websocket is opened.
     * Sends the peer id to the signalling server.
     */
    onServerOpen(Event event)
    {
        // LogConnectionEvent(ConnectionEvent.WebSocketConnected)
        WebSocketConnection.onError.listen((Event e) { 
            // Log(LogLevel.Error,`websocket connection error : ${eve.type}`)
            onServerError();
        });

        WebSocketConnection.onMessage.listen((MessageEvent e) { 
          onServerMessage(e);
        });

        WebSocketConnection.onClose.listen((Event e) {
            // Log(LogLevel.Error,`websocket connection closed : ${eve.type}`)
            onServerError();
        });
    }

    /*
     * send messsage to signalling server
     * @param {string} request_type 
     * @param {any} content 
     */
    SignallingSend(String Target, Map<String, String> Data)
    {
        var dat =  UserRequest(0,
                Target,
                <String, String>{},
                Data).toString();
        // Log(LogLevel.Debug,`sending message : ${dat}`);
        WebSocketConnection.send(dat);
    }

    /*
     * Fired whenever the signalling websocket emits and error.
     * Reconnects after 3 seconds.
     */
    onServerError() 
    {
        // Log(LogLevel.Warning,"websocket connection disconnected");
        // LogConnectionEvent(ConnectionEvent.WebSocketDisconnected)
    }


    /*
     * handle message from signalling server during connection handshake
     * @param {Event} event 
     * @returns 
     */
    onServerMessage(MessageEvent event) 
    {
        var response = UserResponse(event.data.id,
                                        event.data.error,
                                        event.data.data);

        // Log(LogLevel.Debug,`received signaling message: ${response.toString()}`);
        PacketHandler(Data: response.Data);
    }
}



