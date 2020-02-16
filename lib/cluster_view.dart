import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;
import 'ssh_connection.dart';
import 'cluster.dart';

class ClusterViewState extends State<ClusterView> {

  ClusterViewState();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    dev.log("NewClusterState");
    String title = ( widget._cluster != null ) ? 'Edit cluster' : 'Add new cluster';

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.check, size: 30 ),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  _formKey.currentState.save();
                  dev.log("Saving new cluster ${widget._cluster}");
                  Navigator.pop(context, widget._cluster);
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
                              widget._cluster.name = value;
                            },
                            initialValue: widget._cluster?.name,
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
                              widget._cluster.user = value;
                            },
                            initialValue: widget._cluster?.user,
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
                              widget._cluster.host = value;
                            },
                            initialValue: widget._cluster?.host,
                            validator: (String value) {
                              return value.contains('@')
                                  ? 'Do not use the @ char.'
                                  : null;
                            },
                          ),
                          TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.local_airport),
                              hintText: 'SSH server port',
                              labelText: 'port',
                            ),
                            onSaved: (String value) {
                              widget._cluster.port = int.parse(value);
                            },
                            initialValue: ( widget._cluster?.port ?? 22 ).toString(),
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
      dev.log("Testing ${widget._cluster}");
      bool ok = await SSHConnection.test(widget._cluster.user, widget._cluster.host, widget._cluster.port);
    }
                  },
                  child: Text(
                    "Test connection",
                  ))),
        ]));
  }
}

class ClusterView extends StatefulWidget {
  Cluster _cluster;
  ClusterView([this._cluster]);

  @override
  ClusterViewState createState() => ClusterViewState();
}
