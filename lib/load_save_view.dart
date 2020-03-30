import 'package:flutter/material.dart';
import 'dart:developer' as dev;

class LoadSaveViewState extends State<LoadSaveView> {
  LoadSaveViewState();

  @override
  Widget build(BuildContext context) {
    dev.log("load/save view");

    return Scaffold(
      appBar: AppBar(title: Text("Load/Save configuration")),
    );
  }
}

class LoadSaveView extends StatefulWidget {
  LoadSaveView();

  @override
  LoadSaveViewState createState() => LoadSaveViewState();
}
