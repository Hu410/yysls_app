import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'views/home/home_page.dart';

class YyslsApp extends StatelessWidget {
  const YyslsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '燕云毕业度计算器',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }
}
