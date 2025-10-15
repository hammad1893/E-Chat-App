import 'package:chat_app/bottomnavigation.dart';
import 'package:chat_app/mainscreen/onboardinscreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentStage = 0;
  Timer? _stageTimer;

  final List<SplashStage> _stages = [
    SplashStage(
      icon: Icons.chat_bubble_outline,
      title: '',
      subtitle: '',
      iconSize: 60,
    ),
    SplashStage(
      icon: Icons.chat_bubble,
      title: '',
      subtitle: '',
      iconSize: 70,
      showSecondIcon: true,
    ),
    SplashStage(
      icon: Icons.chat_bubble,
      title: '',
      subtitle: 'As fast as lightning,\nas delicious as thunder!',
      iconSize: 80,
      showSecondIcon: true,
      showThirdIcon: true,
    ),
    SplashStage(
      icon: Icons.chat_bubble_outline,
      title: 'E-Chat',
      subtitle: 'Stay Connected\nStay Chatting',
      iconSize: 100,
      isFinalStage: true,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _startStageAnimation();
  }

  void _startStageAnimation() {
    _controller.forward(from: 0);

    _stageTimer = Timer(const Duration(milliseconds: 1200), () {
      if (_currentStage < _stages.length - 1) {
        setState(() {
          _currentStage++;
        });
        _startStageAnimation();
      } else {
        // All stages complete, navigate
        Timer(const Duration(milliseconds: 1000), _checkFirstTimeUser);
      }
    });
  }

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('is_first_time') ?? true;

    if (mounted) {
      if (isFirstTime) {
        await prefs.setBool('is_first_time', false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Onboardinscreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CustomBottomNavBar()),
        );
      }
    }
  }

  @override
  void dispose() {
    _stageTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stages[_currentStage];

    return Scaffold(
      backgroundColor: const Color(0xff1a1a1a),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icons
                SizedBox(
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Main icon
                      Opacity(
                        opacity: _controller.value,
                        child: Transform.scale(
                          scale: 0.5 + (_controller.value * 0.5),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color:
                                  stage.isFinalStage
                                      ? Colors.transparent
                                      : Colors.blueAccent.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border:
                                  stage.isFinalStage
                                      ? Border.all(
                                        color: Colors.blueAccent,
                                        width: 3,
                                      )
                                      : null,
                            ),
                            child: Icon(
                              stage.icon,
                              size: stage.iconSize,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),

                      // Second icon (stage 2+)
                      if (stage.showSecondIcon)
                        Positioned(
                          right: 40,
                          child: Opacity(
                            opacity: _controller.value * 0.8,
                            child: Transform.scale(
                              scale: 0.3 + (_controller.value * 0.4),
                              child: Icon(
                                Icons.chat_bubble,
                                size: 50,
                                color: Colors.blueAccent.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),

                      // Third icon (stage 3+)
                      if (stage.showThirdIcon)
                        Positioned(
                          left: 40,
                          top: 30,
                          child: Opacity(
                            opacity: _controller.value * 0.6,
                            child: Transform.scale(
                              scale: 0.2 + (_controller.value * 0.3),
                              child: Icon(
                                Icons.chat_bubble,
                                size: 40,
                                color: Colors.blueAccent.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                if (stage.title.isNotEmpty)
                  Opacity(
                    opacity: _controller.value,
                    child: Text(
                      stage.title,
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // Subtitle
                if (stage.subtitle.isNotEmpty)
                  Opacity(
                    opacity: _controller.value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        stage.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 40),

                // Progress indicator (only show on final stage)
                if (stage.isFinalStage)
                  Opacity(
                    opacity: _controller.value,
                    child: const CircularProgressIndicator(
                      color: Colors.blueAccent,
                      strokeWidth: 3,
                    ),
                  ),

                // Stage dots indicator
                if (!stage.isFinalStage)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _stages.length - 1,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _currentStage ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                index == _currentStage
                                    ? Colors.blueAccent
                                    : Colors.blueAccent.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Version (only on final stage)
                if (stage.isFinalStage)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Opacity(
                      opacity: _controller.value,
                      child: Text(
                        'Version 2.1.0',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SplashStage {
  final IconData icon;
  final String title;
  final String subtitle;
  final double iconSize;
  final bool showSecondIcon;
  final bool showThirdIcon;
  final bool isFinalStage;

  SplashStage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconSize,
    this.showSecondIcon = false,
    this.showThirdIcon = false,
    this.isFinalStage = false,
  });
}
