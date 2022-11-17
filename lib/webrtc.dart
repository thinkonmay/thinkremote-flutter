import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef SendFuncType = void Function(
    {String? target, Map<String, String>? data});
typedef TrackHandlerType = Function(RTCTrackEvent a);
typedef ChannelHandlerType = dynamic Function(RTCDataChannel a);

class WebRTC {
  late RTCPeerConnection conn;
  late SendFuncType signallingSendFunc;
  late String state;

  Future setup(
      ChannelHandlerType channelHandler, TrackHandlerType trackHandler) async {
    var configuration = {
      "iceServers": [
        {
          "urls": "turn:workstation.thinkmay.net:3478",
          "username": "oneplay",
          "credential": "oneplay"
        },
        {
          "urls": [
            "stun:workstation.thinkmay.net:3478",
            "stun:stun.l.google.com:19302"
          ]
        }
      ]
    };
    conn = await createPeerConnection(configuration);
    conn.onDataChannel = channelHandler;
    conn.onTrack = trackHandler;
    conn.onIceCandidate = ((RTCIceCandidate ev) => {onICECandidates(ev)});
    conn.onConnectionState =
        ((RTCPeerConnectionState ev) => {onConnectionStateChange(ev)});
  }

  WebRTC(SendFuncType sendFunc, TrackHandlerType trackerHandler,
      ChannelHandlerType channelHandler) {
    state = "Not connected";
    signallingSendFunc = sendFunc;
    setup(channelHandler, trackerHandler);
  }

  onConnectionStateChange(RTCPeerConnectionState eve) {
    print("state change to ${jsonEncode(eve)}");
    switch (eve) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        // LogConnectionEvent(ConnectionEvent.WebRTCConnectionDoneChecking)
        // Log(LogLevel.Infor,"webrtc connection established");
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        // LogConnectionEvent(ConnectionEvent.WebRTCConnectionClosed)
        // Log(LogLevel.Error,"webrtc connection establish failed");
        break;
      default:
        break;
    }
  }

  /*
     * 
     * @param {*} ice 
     */
  onIncomingICE(RTCIceCandidate ice) async {
    var candidate =
        RTCIceCandidate(ice.candidate, ice.sdpMid, ice.sdpMLineIndex);
    try {
      await conn.addCandidate(candidate);
    } catch (error) {
      // Log(LogLevel.Error,error);
    }
  }

  /*
     * Handles incoming SDP from signalling server.
     * Sets the remote description on the peer connection,
     * creates an answer with a local description and sends that to the peer.
     *
     * @param {RTCSessionDescriptionInit} sdp
    */
  onIncomingSDP(RTCSessionDescription sdp) async {
    if (sdp.type != "offer") {
      return;
    }

    state = "Got SDP offer";

    try {
      var Conn = conn;
      await Conn.setRemoteDescription(sdp);
      var ans = await Conn.createAnswer();
      await onLocalDescription(ans);
    } catch (error) {
      // Log(LogLevel.Error,error);
    }
    ;
  }

  /*
     * Handles local description creation from createAnswer.
     *
     * @param {RTCSessionDescriptionInit} local_sdp
     */
  onLocalDescription(RTCSessionDescription desc) async {
    var Conn = conn;
    await conn.setLocalDescription(desc);

    if (await Conn.getLocalDescription() == null) {
      return;
    }

    var init = await Conn.getLocalDescription();

    var dat = <String, String>{};
    dat.update("Type", (value) => value = init!.type!);
    dat.update("SDP", (value) => value = init!.sdp!);
    signallingSendFunc(target: "SDP", data: dat);
  }

  onICECandidates(RTCIceCandidate ev) {
    if (ev.candidate == null) {
      print("ICE Candidate was null, done");
      return;
    }

    var init = jsonEncode(ev.candidate) as RTCIceCandidate;
    var dat = <String, String>{};
    if (init.candidate!.isNotEmpty) {
      dat.update("Candidate", (value) => value = init.candidate!);
    }
    if (init.sdpMid!.isNotEmpty) {
      dat.update("SDPMid", (value) => value = init.sdpMid!);
    }
    if (init.sdpMLineIndex != null) {
      dat.update("SDPMLineIndex", ((value) => init.sdpMLineIndex.toString()));
    }
    signallingSendFunc(target: "ICE", data: dat);
  }
}
