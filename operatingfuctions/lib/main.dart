import 'dart:io';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      body: Center(
          child: Container(
              alignment: Alignment.center,
              child: Text()),
    ));
  }
}
