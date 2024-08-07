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
        primarySwatch: Colors.blue,wo
      ),
      home: LoginScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final bool isPrincipleTenant;
  HomeScreen({required this.isPrincipleTenant});

  @override
  Widget build(BuildContext context) {
    return TenantScreen(isPrincipleTenant: isPrincipleTenant);
  }
}
