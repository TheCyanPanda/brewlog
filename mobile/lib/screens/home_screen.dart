import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  final AuthService authService;
  final Dio dio;

  const HomeScreen(
    {
      super.key,
      required this.authService,
      required this.dio,
    }
  );

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Comming soon - Home'),
      ),
    );
  }

}
