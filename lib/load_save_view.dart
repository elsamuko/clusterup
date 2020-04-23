import 'dart:io';
import 'package:clusterup/clusterup_data.dart';
import 'package:clusterup/server.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wifi/wifi.dart';

class LoadSaveViewState extends State<LoadSaveView> {
  LoadSaveViewState();
  String _base;
  String _ip = "";
  Server _server = Server();
  bool _withPrivateKey = false;

  @override
  void initState() {
    Wifi.ip.then((String ip) {
      setState(() {
        _ip = ip;
      });
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

      _server.json = widget._data.toJSON(_withPrivateKey);

      _server.onJson = (String json) {
        ClusterUpData data = ClusterUpData.fromJSON(json);
        if (data.clusters != null) {
          widget._data.clusters = data.clusters;
        }
        if (data.sshKey != null) {
          widget._data.sshKey = data.sshKey;
        }
      };

      _server.start(_base);
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
    dev.log("load/save view");

    return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, widget._data);
          return false;
        },
        child: Scaffold(
          appBar: AppBar(title: Text("Load/Save configuration")),
          body: Padding(
              padding: EdgeInsets.all(20),
              child: Column(children: <Widget>[
                SwitchListTile(
                  secondary: Icon(Icons.lock_outline),
                  title: Text("Include private key"),
                  value: _withPrivateKey,
                  onChanged: (v) {
                    setState(() {
                      _withPrivateKey = v;
                      _server.json = widget._data.toJSON(_withPrivateKey);
                    });
                  },
                ),
                Divider(),
                Text("Server running on"),
                SizedBox(height: 10),
                FlatButton(
                    color: Colors.black87,
                    textColor: Colors.lightGreenAccent,
                    onPressed: () {},
                    child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(
                          child: Text("http://$_ip:3001", style: TextStyle(fontFamily: "monospace")),
                        )))
              ])),
        ));
  }
}

class LoadSaveView extends StatefulWidget {
  ClusterUpData _data;
  LoadSaveView(this._data);

  @override
  LoadSaveViewState createState() => LoadSaveViewState();
}
