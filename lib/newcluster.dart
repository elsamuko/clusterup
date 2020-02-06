import 'package:flutter/material.dart';
import 'dart:developer' as dev;
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
              icon: Icon(Icons.check),
              onPressed: () {
                if( _formKey.currentState.validate() ) {
                  _formKey.currentState.save();
                  dev.log("Saving new cluster ${_cluster}");
                }
              },
            ),
          ],
        ),
        body: Form(
            key: _formKey,
            child: Column(
          children: <Widget>[
            TextFormField(
              decoration: const InputDecoration(
                icon: Icon(Icons.label),
                labelText: 'name',
              ),
              onSaved: (String value) {
                  dev.log("Saving name");
                  _cluster.name = value;
              },
            ),
            TextFormField(
              decoration: const InputDecoration(
                icon: Icon(Icons.person),
                hintText: 'username',
                labelText: 'username',
              ),
              onSaved: (String value) {
                setState(() {
                  _cluster.user = value;
                });
              },
              validator: (String value) {
                return value.contains('@') ? 'Do not use the @ char.' : null;
              },
            ),
            TextFormField(
              decoration: const InputDecoration(
                icon: Icon(Icons.computer),
                hintText: 'Server domain',
                labelText: 'server',
              ),
              onSaved: (String value) {
                _cluster.domain = value;
              },
              validator: (String value) {
                return value.contains('@') ? 'Do not use the @ char.' : null;
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
                // This optional block of code can be used to run
                // code when the user saves the form.
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
        )));
  }
}

class NewCluster extends StatefulWidget {
  @override
  NewClusterState createState() => NewClusterState();
}
