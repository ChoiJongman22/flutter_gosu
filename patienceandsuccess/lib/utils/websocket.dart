import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:async';

typedef void OnMessageCallback(dynamic msg);
typedef void OnCloseCallback(int code, String reason);
typedef void OnOpenCallback();

class FlumeWebSocket {
  String _url;
  var _socket;
  OnOpenCallback onOpen;
  OnMessageCallback onMessage;
  OnCloseCallback onClose;
  FlumeWebSocket(this._url);

  connect() async {
    try {
      _socket = await _connectForSelfSignedCert(_url);
      onOpen?.call();
      _socket.list((data) {
        onMessage?.call(data);
      }, onDone: () {
        onClose?.call(_socket.closeCode, _socket.closeReason);
      });
    } catch (e) {
      onClose?.call(500, e.toString());
    }
  }

  send(data) {
    if (_socket != null) {
      _socket.add(data);
      print('send: $data');
    }
  }

  close() {
    if (_socket != null) _socket.close();
  }

  Future<WebSocket> _connectForSelfSignedCert(url) async {
    try {
      Random r = new Random();
      String key = base64.encode(List<int>.generate(8, (_) => r.nextInt(255)));
      HttpClient client = HttpClient(context: SecurityContext())
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) {
          print(
              'FlumeWebSocket: Allow self-signed certificate => $host:$port. ');
          return true;
        };

      HttpClientRequest request = await client.getUrl(Uri.parse(url));
      request.headers.add('Connection', 'Upgrade');
      request.headers.add('Upgrade', 'websocket');
      request.headers.add('Sec-WebScoket-Version', '13');
      request.headers.add('Sec-WebScoket-Key', key.toLowerCase());
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
