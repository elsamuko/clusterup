import 'package:flutter/material.dart';
import 'views/clusters_view.dart';
import 'package:clusterup/log.dart';

void main() {
  log("Starting");
  runApp(MyApp());
}

// https://flutter.dev/docs/get-started/codelab
// https://codelabs.developers.google.com/codelabs/first-flutter-app-pt2/#0
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // https://docs.flutter.dev/release/breaking-changes/buttons#restoring-the-original-button-visuals
    final ButtonStyle flatButtonStyle = TextButton.styleFrom(
      minimumSize: Size(88, 36),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
    );

    return MaterialApp(
      title: 'Cluster Up',
      theme: ThemeData(
        brightness: Brightness.dark,
        textButtonTheme: TextButtonThemeData(style: flatButtonStyle),
        scaffoldBackgroundColor: Color(0xff282828),
        primaryColor: Color(0xff575757),
      ),
      home: ClustersView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
