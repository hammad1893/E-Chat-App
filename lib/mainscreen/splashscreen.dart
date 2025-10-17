
import 'dart:async';
import 'package:chat_app/bottomnavigation.dart';
import 'package:chat_app/mainscreen/onboardinscreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    // Move to next screen after animation + delay
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 2), _checkUserFlow);
      }
    });
  }

  Future<void> _checkUserFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('is_first_time') ?? true;
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!mounted) return;

    if (isFirstTime) {
      // First time user → go onboarding
      await prefs.setBool('is_first_time', false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Onboardinscreen()),
      );
    } else if (isLoggedIn) {
      // Logged in user → go to main app
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CustomBottomNavBar()),
      );
    } else {
      // Not logged in → go onboarding or login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Onboardinscreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff292929),
      body: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/Logo.png', fit: BoxFit.cover),

                  const SizedBox(height: 20),
                  const Text(
                    'E-Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'As fast as lightning,\nas delicious as thunder!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Stay Connected\nStay Chatting',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(
                    color: Colors.lightBlueAccent,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Version 2.1.0',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
