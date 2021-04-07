import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flume_Ride',
      theme: ThemeData(),
      home: MyHomePage(title: 'FlumeRide'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _offer = false;
  RTCPeerConnection _peerConnection;
  MediaStream _localStream;
  final _localRenderer = new RTCVideoRenderer();
  final _remoteRenderer = new RTCVideoRenderer();
  final sdpController = TextEditingController();

  //necessary method

  @override
  void initState() {
    initRenderer();
    _createPeerConnection().then((pc) {
      _peerConnection = pc;
    });

    super.initState();
  }

  @override
  dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    sdpController.dispose();
    super.dispose();
  }

  //Success
  _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': {
        'facingMode': 'user',
      },
    };
    //Success
    MediaStream stream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = stream;

    return stream;
  }

  initRenderer() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    _localStream = await _getUserMedia();
    RTCPeerConnection pc =
        await createPeerConnection(configuration, offerSdpConstraints);
    pc.addStream(_localStream);

    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        print(json.encode({
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMlineIndex
        }));
      }
    };
    pc.onIceConnectionState = (e) {
      print(e);
    };
    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      _remoteRenderer.srcObject = stream;
    };
    return pc;
  }

  void _createOffer() async {
    RTCSessionDescription description =
        await _peerConnection.createOffer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp);
    print(json.encode(session));
    _offer = true;
    _peerConnection.setLocalDescription(description);
  }

  void _setRemoteDescription() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode('$jsonString');

    String sdp = write(session, null);

    RTCSessionDescription description =
        new RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');
    print(description.toMap());

    await _peerConnection.setRemoteDescription(description);
  }

  void _createAnswer() async {
    RTCSessionDescription description =
        await _peerConnection.createAnswer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp);
    print(json.encode(session));
    _offer = true;
    _peerConnection.setLocalDescription(description);
  }

  void _setCandidate() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode('$jsonString');

    print(session['candidate']);

    dynamic candidate = new RTCIceCandidate(
        session['candidate'], session['sdpMid'], session['sdpMlineIndex']);

    await _peerConnection.addCandidate(candidate);
  }

  //window conposition

  SizedBox videoRenderers() => SizedBox(
        height: 210,
        child: Row(
          children: [
            Flexible(
              child: Container(
                key: Key("local"),
                margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                decoration: BoxDecoration(color: Colors.black),
                child: RTCVideoView(_localRenderer, mirror: true),
              ),
            ),
            Flexible(
              child: Container(
                key: Key("remote"),
                margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                decoration: BoxDecoration(color: Colors.black),
                child: RTCVideoView(_remoteRenderer),
              ),
            ),
          ],
        ),
      );
  Row offerAndAnswerButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ElevatedButton(
            onPressed: _createOffer,
            child: Text("Offer"),
            style: ElevatedButton.styleFrom(onPrimary: Colors.amber),
          ),
          ElevatedButton(
            onPressed: _createAnswer,
            child: Text("Answer"),
            style: ElevatedButton.styleFrom(onPrimary: Colors.amber),
          )
        ],
      );

  Padding sdpCandidateTF() => Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: sdpController,
          keyboardType: TextInputType.multiline,
          maxLines: 4,
          maxLength: TextField.noMaxLength,
        ),
      );

  Row sdpCandidateButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ElevatedButton(
              onPressed: _setRemoteDescription,
              child: Text("Set Remote Desc"),
              style: ElevatedButton.styleFrom(
                  primary: Colors.purple,
                  onPrimary: Colors.blue,
                  onSurface: Colors.black)),
          ElevatedButton(
            onPressed: _setCandidate,
            child: Text("Set Candidate"),
            style: ElevatedButton.styleFrom(primary: Colors.blue),
          )
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        child: Column(
          children: [
            videoRenderers(),
            offerAndAnswerButtons(),
            sdpCandidateTF(),
            sdpCandidateButtons(),
          ],
        ),
      ),
    );
  }
}
