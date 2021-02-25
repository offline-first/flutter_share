import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  Future<File> getFile() async {
    final fileName = "test.png";
    final data = await rootBundle.load('assets/$fileName');

    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/$fileName').create();
    await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));

    return file;
  }

  Future<void> shareImage() async {
    final file = await getFile();
    await FlutterShare.file(file.path);
  }

  Future<void> shareWhatsApp() async {
    final file = await getFile();
    await FlutterShare.shareWhatsapp(
        filePath: file.path, text: "optional text");
  }

  Future<void> shareTelegram() async {
    final file = await getFile();
    await FlutterShare.shareTelegram(
        filePath: file.path, text: "Hello, optional text");
  }

  void checkInstalled() async {
    print("Telegram Installed:${await FlutterShare.telegramInstalled()}");
    print("Facebook Installed:${await FlutterShare.facebookInstalled()}");
    print("Instagram Installed:${await FlutterShare.instagramInstalled()}");
    print("Twitter Installed:${await FlutterShare.twitterInstalled()}");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
            child: Column(
          children: [
            TextButton(
              onPressed: shareImage,
              child: Text('Share image from asset'),
            ),
            TextButton(
              onPressed: shareTelegram,
              child: Text('Share image from asset'),
            ),
          ],
        )),
      ),
    );
  }
}
