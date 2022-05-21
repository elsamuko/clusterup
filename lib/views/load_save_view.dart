import 'dart:io';
import 'package:clusterup/clusterup_data.dart';
import 'package:clusterup/server.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:clusterup/log.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LoadSaveViewState extends State<LoadSaveView> {
  LoadSaveViewState();
  String _base;
  String _ip = "";
  Server _server = Server(3001);
  bool _withPrivateKey = false;

  @override
  void initState() {
    NetworkInterface.list().then((list) {
      if (list.isNotEmpty && list.first.addresses.isNotEmpty) {
        setState(() {
          _ip = list.first.addresses.first.address;
        });
      }
    });

    List<String> artifacts = ["index.html", "favicon.ico", "bootstrap.css"];
    getTemporaryDirectory().then((Directory tempDir) async {
      _base = "${tempDir.path}/web";

      // write site
      artifacts.forEach((String artifact) async {
        File f = await File("$_base/$artifact").create(recursive: true);
        ByteData content = await rootBundle.load("res/web/$artifact");
        f.writeAsBytes(content.buffer.asInt8List());
      });

      // set current config as json string
      _server.json = widget._data.toJSON(_withPrivateKey);

      // configure callback when server gets a new json string
      _server.onJsonOrKey = (String json) {
        setState(() {
          // parse json
          ClusterUpData data = ClusterUpData.fromJSON(json);
          if (data.clusters != null && data.clusters.isNotEmpty) {
            widget._data.clusters = data.clusters;
          }
          if (data.sshKey != null) {
            widget._data.sshKey = data.sshKey;
          }

          // refresh server config
          _server.json = widget._data.toJSON(_withPrivateKey);
        });
      };
    });
    super.initState();
  }

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log("load/save view");

    List<Widget> children = <Widget>[
      SwitchListTile(
        secondary: Icon(Icons.lock_outline),
        title: Text("Include private key"),
        value: _withPrivateKey,
        onChanged: widget._data.sshKey != null
            ? (v) {
                setState(() {
                  _withPrivateKey = v;
                  _server.json = widget._data.toJSON(_withPrivateKey);
                });
              }
            : null,
      ),
      Divider(),
      TextButton(
          style: TextButton.styleFrom(
            backgroundColor: _server.isRunning() ? Colors.red[800] : Color(0xffcc8d00),
            primary: Colors.white,
          ),
          onPressed: () {
            setState(() {
              if (_server.isRunning()) {
                _server.stop();
              } else {
                _server.start(_base);
              }
            });
          },
          child: Text(
            _server.isRunning() ? "Stop server" : "Start server",
          ))
    ];

    if (_server.isRunning()) {
      String url = "http://$_ip:${_server.socket}";

      children += <Widget>[
        Divider(),
        Center(child: Text("Server running on")),
        SizedBox(height: 10),
        TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.black87,
              primary: Colors.amberAccent,
            ),
            onPressed: () {
              launchUrl(Uri.parse(url));
            },
            child: Padding(
                padding: EdgeInsets.all(8),
                child: Center(
                  child: Text(url, style: TextStyle(fontFamily: "monospace")),
                )))
      ];
    }

    bool isEmulator = !kReleaseMode && _ip == "10.0.2.16";

    // warn, if we are not emulator or in intranet
    if (!(isEmulator || _ip.startsWith("192.168."))) {
      children += <Widget>[
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.warning,
              color: Colors.amberAccent,
              size: 14,
            ),
            SizedBox(width: 4),
            Text(
              "Device is not in intranet, IP is $_ip",
              style: TextStyle(color: Colors.amberAccent),
            ),
          ],
        ),
      ];
    }

    return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, widget._data);
          return false;
        },
        child: Scaffold(
          appBar: AppBar(title: Text("Load/Save configuration")),
          body: Scrollbar(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: ListView(children: children),
            ),
          ),
        ));
  }
}

class LoadSaveView extends StatefulWidget {
  final ClusterUpData _data;
  LoadSaveView(this._data);

  @override
  LoadSaveViewState createState() => LoadSaveViewState();
}
