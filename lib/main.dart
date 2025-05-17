import 'package:flutter/material.dart';
import 'notion_table_page.dart';

void main() {
  runApp(const MyApp());
}

final List<Map<String, dynamic>> members = [
  {
    'name': '김민승',
    'role': 'Frontend',
    'phoneNumber': '010-5068-1107',
    'github': 'jaemin104',
    'status': '활동중',
    'email': 'jaemin1107@gmail.com',
  },
  {
    'name': '노영진',
    'role': 'Backend',
    'phoneNumber': '010-4494-2588',
    'github': 'youngjin',
    'status': '활동중',
    'email': 'emzmfkdufws12@gmail.com',
  },
  {
    'name': '신영빈',
    'role': 'Frontend',
    'phoneNumber': '010-5841-0128',
    'github': 'youngbin03',
    'status': '활동중',
    'email': 'shyoungbin0128@gmail.com',
  },
  {
    'name': '정재훈',
    'role': 'Frontend',
    'phoneNumber': '010-8253-1379',
    'github': 'affection.jh',
    'status': '활동중',
    'email': 'jaehun330@gmail.com',
  },
  {
    'name': '삼만승',
    'role': 'Frontend',
    'phoneNumber': '010-5068-1107',
    'github': 'jaemin104',
    'status': '활동중',
    'email': 'jaemin1107@gmail.com',
  },
  {
    'name': '삼만승',
    'role': 'Frontend',
    'phoneNumber': '010-5034-1234',
    'github': 'jaemin104',
    'status': '활동중',
    'email': 'jadjj0724@gmail.com',
  },
  {
    'name': '김지은',
    'role': 'Frontend',
    'phoneNumber': '010-6574-3234',
    'github': 'jaemin104',
    'status': '활동중',
    'email': 'jienekin4@gmail.com',
  },
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '노션 스타일 테이블',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
      home: const NotionTablePage(),
    );
  }
}
