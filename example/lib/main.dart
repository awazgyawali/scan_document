import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:scan_document/scan_document.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plugin example app'),
      ),
      body: Center(
        child: TextButton(
          child: Text("Scan Documen t"),
          onPressed: () async {
            XFile? pdf = await scanDocument(context);
            if (pdf != null) OpenFile.open(pdf.path);
          },
        ),
      ),
    );
  }
}
