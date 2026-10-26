import 'package:flutter/material.dart';
import 'package:halmishop_app/screens/main_feed_screen%20copy.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'cart_provider.dart'; // 👈 2. 임포트 추가
import 'screens/login_screen.dart'; // 혹은 시작 스크屏 경로


void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartProvider())],
      child: const MyApp(),
    ),
  );
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
      // home: const LoginScreen(), // 회원가입 화면을 첫 화면으로 지정
      home : LoginScreen(),
    );
  }
}
