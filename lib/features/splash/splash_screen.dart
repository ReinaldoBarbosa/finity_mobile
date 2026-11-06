import 'dart:async';

import 'package:flutter/material.dart';
import '../auth/presentation/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _abrirLogin();
  }

  Future<void> _abrirLogin() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF29236F),
              Color(0xFF29236F),
              Color(0xFF211B60),
            ],
            stops: [0.0, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -100,
              right: -100,
              bottom: -100,
              height: 300,
              child: Transform.rotate(
                angle: -0.20,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF211B60),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                    const Text(
                      'Finity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 50,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Sua empresa no controle\nfinanceiro.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD0CDEB),
                        fontSize: 18,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 75,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF494184),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 28,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6C4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
