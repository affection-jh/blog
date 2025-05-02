import 'package:blog/editor.dart';
import 'package:blog/rich_editor/widgets/custom_text_editor.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '노션 에디터',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF2D2D2D),
        appBarTheme: AppBarTheme(backgroundColor: Color(0xFF2D2D2D)),
      ),
      home: NotionEditor(),
    );
  }
}
