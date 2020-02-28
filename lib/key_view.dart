import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;
import 'ssh_key.dart';

// helper function for compute
SSHKey generateSSHKey(int) {
  return SSHKey.generate();
}

class KeyViewState extends State<KeyView> {
  KeyViewState();

  Future<SSHKey> _getKey;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    if (widget._key == null) {
      _getKey = compute(generateSSHKey, 1);
    } else {
      _getKey = Future<SSHKey>(() {
        return widget._key;
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    dev.log("key view");

    return FutureBuilder<SSHKey>(
        future: _getKey,
        builder: (BuildContext context, AsyncSnapshot<SSHKey> snapshot) {
          Widget child;

          if (snapshot.hasData) {
            widget._key = snapshot.data;
            String key = snapshot.data.pubForSSH() + " clusterup";
            child = Padding(
                padding: EdgeInsets.all(20),
                child: Column(children: <Widget>[
                  Text(
                      "Copy this SSH key into your '.ssh/authorized_keys2' file:"),
                  SizedBox(height: 10),
                  FlatButton(
                      color: Colors.black87,
                      textColor: Colors.lightGreenAccent,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: key));
                        final snackBar = SnackBar(
                            content: Text("Copied ssh key into clipboard"));
                        _scaffoldKey.currentState.showSnackBar(snackBar);
                      },
                      child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            key,
                            style: TextStyle(fontFamily: "monospace"),
                          )))
                ]));
          } else {
            child = Center(
                child: Column(
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(height: 30),
                Text('Generating SSH key...'),
              ],
              mainAxisAlignment: MainAxisAlignment.center,
            ));
          }

          return WillPopScope(
              onWillPop: () async {
                Navigator.pop(context, widget._key);
                return false;
              },
              child: Scaffold(
                  key: _scaffoldKey,
                  appBar: AppBar(
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context, widget._key);
                      },
                    ),
                    title: Text('View SSH key'),
                  ),
                  body: child));
        });
  }
}

class KeyView extends StatefulWidget {
  SSHKey _key;
  KeyView(this._key);

  @override
  KeyViewState createState() => KeyViewState();
}
