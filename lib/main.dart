import 'package:flutter/material.dart';
import 'clusters_view.dart';

void main() => runApp(MyApp());

// https://flutter.dev/docs/get-started/codelab
// https://codelabs.developers.google.com/codelabs/first-flutter-app-pt2/#0
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cluster Up',
      theme: ThemeData(primaryColor: Colors.blue[800], brightness: Brightness.dark),
      home: ClustersView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
