import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '젊은할미반찬가게',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const LoginScreen(), // 회원가입 화면을 첫 화면으로 지정
    );
  }
}
