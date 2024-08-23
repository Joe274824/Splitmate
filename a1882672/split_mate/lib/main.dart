import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'tenant_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),  // 启动时加载 LoginScreen
    );
  }
}

class HomeScreen extends StatelessWidget {
  final bool isPrincipleTenant;
  final String token;  // 新增 token 参数

  HomeScreen({required this.isPrincipleTenant, required this.token});  // 修改构造函数

  @override
  Widget build(BuildContext context) {
    return TenantScreen(isPrincipleTenant: isPrincipleTenant, token: token);  // 传递 token
  }
}
