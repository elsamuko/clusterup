import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;
import 'sshconnection.dart';
import 'cluster.dart';

class NewClusterState extends State<NewCluster> {
  Cluster _cluster = Cluster("");
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    dev.log("NewClusterState");

    return Scaffold(
        appBar: AppBar(
          title: Text('Add new cluster'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.check, size: 30 ),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  _formKey.currentState.save();
                  dev.log("Saving new cluster ${_cluster}");
                  Navigator.pop(context, _cluster);
                }
              },
            ),
          ],
        ),
        body: ListView(children: <Widget>[
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            decoration: const InputDecoration(
                              icon: Icon(Icons.label),
                              labelText: 'name',
                            ),
                            onSaved: (String value) {
                              _cluster.name = value;
                            },
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                              icon: Icon(Icons.person),
                              hintText: 'username',
                              labelText: 'username',
                            ),
                            inputFormatters: [
                              BlacklistingTextInputFormatter(RegExp("[ ]"))
                            ],
                            onSaved: (String value) {
                              _cluster.user = value;
                            },
                            validator: (String value) {
                              return value.contains('@')
                                  ? 'Do not use the @ char.'
                                  : null;
                            },
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                              icon: Icon(Icons.computer),
                              hintText: 'Server domain',
                              labelText: 'server',
                            ),
                            inputFormatters: [
                              BlacklistingTextInputFormatter(RegExp("[ ]"))
                            ],
                            onSaved: (String value) {
                              _cluster.host = value;
                            },
                            validator: (String value) {
                              return value.contains('@')
                                  ? 'Do not use the @ char.'
                                  : null;
                            },
                          ),
                          TextFormField(
                            initialValue: "22",
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.local_airport),
                              hintText: 'SSH server port',
                              labelText: 'port',
                            ),
                            onSaved: (String value) {
                              _cluster.port = int.parse(value);
                            },
                            validator: (String value) {
                              if (int.tryParse(value) == 0) {
                                return "Invalid port number";
                              } else {
                                return null;
                              }
                            },
                          ),
                        ],
                      )))),
          Container(
              margin: const EdgeInsets.all(20.0),
              child: FlatButton(
                  color: Colors.blue,
                  textColor: Colors.white,
                  onPressed: () async {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      dev.log("Testing ${_cluster}");
      bool ok = await SSHConnection.test(_cluster.user, _cluster.host, _cluster.port);
    }
                  },
                  child: Text(
                    "Test connection",
                  ))),
        ]));
  }
}

class NewCluster extends StatefulWidget {
  @override
  NewClusterState createState() => NewClusterState();
}
