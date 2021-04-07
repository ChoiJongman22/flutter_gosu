import 'package:flutter/material.dart';
import 'package:patienceandsuccess/route_item.dart';
import 'package:patienceandsuccess/src/Group_call.dart';
import 'package:patienceandsuccess/src/data_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(FlumeRide());

class FlumeRide extends StatefulWidget {
  @override
  _FlumeRideState createState() => _FlumeRideState();
}

//AlertDialog button Enum
enum DialogAction {
  cancel,
  connect,
}

class _FlumeRideState extends State<FlumeRide> {
  List<RouteItem> items;
  String _server = '';
  SharedPreferences _prefs;

  bool _datachannel = false;

  @override
  void initState() {
    super.initState();
    _initData();
    _initItems();
  }

  _buildRow(context, item) {
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(item.title),
        onTap: () => item.push(context),
        trailing: Icon(Icons.arrow_right),
      ),
      Divider()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("FlumeRide"),
        ),
        body: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(0.0),
            itemCount: items.length,
            itemBuilder: (context, i) {
              return _buildRow(context, items[i]);
            }),
      ),
    );
  }

  _initData() async {
    //sharedpreference 얻기
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _server = _prefs.getString('server') ??
          '33lab.webrtc.com'; //null이 아니면 server를 null이면 뒤에거
    });
  }

  void showingDialog<T>({BuildContext context, Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T value) {
      if (value != null) {
        if (value == DialogAction.connect) {
          _prefs.setString('server', _server); //server에 _setserver 저장하기
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => _datachannel
                      ? DataChannel(host: _server)
                      : Call(host: _server)));
        }
      }
    });
  }

  //dialog floating function
  _showAddressDiaglog(context) {
    showingDialog<DialogAction>(
      context: context,
      child: AlertDialog(
        title: const Text('Enter server address: '),
        content: TextField(
          onChanged: (String text) {
            setState(() {
              _server = text;
            });
          },
          decoration: InputDecoration(
            hintText: _server,
          ),
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context, DialogAction.cancel);
              }),
          TextButton(
              onPressed: () {
                Navigator.pop(context, DialogAction.connect);
              },
              child: const Text('Connect'))
        ],
      ),
    );
  }

  _initItems() {
    items = <RouteItem>[
      RouteItem(
          title: 'Group Call',
          subtitle: 'Group Call 33LAB',
          push: (BuildContext context) {
            _datachannel = false;
            _showAddressDiaglog(context);
          }),
      RouteItem(
          title: 'Channel',
          subtitle: 'Group channel',
          push: (BuildContext context) {
            _datachannel = true;
            _showAddressDiaglog(context);
          })
    ];
  }
}
