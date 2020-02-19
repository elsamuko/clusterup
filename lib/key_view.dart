import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;
import 'ssh_key.dart';

// helper function for compute
SSHKey generateSSHKey(int) {
  return SSHKey.generate();
}

class KeyViewState extends State<KeyView> {
  KeyViewState();

  Future<SSHKey> _getKey;

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
            child = Padding(
                padding: EdgeInsets.all(20),
                child: Column(children: <Widget>[
                  Text(
                      "Copy this SSH key into your '.ssh/authorized_keys2' file:"),
                  SizedBox(height: 10),
                  SelectableText(snapshot.data.pubForSSH())
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

          return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context, widget._key),
                ),
                title: Text('View SSH key'),
              ),
              body: child);
        });
  }
}

class KeyView extends StatefulWidget {
  SSHKey _key;
  KeyView([this._key]);

  @override
  KeyViewState createState() => KeyViewState();
}
