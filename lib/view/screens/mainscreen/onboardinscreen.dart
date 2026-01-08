import 'dart:async';

import 'package:chat_app/view/constants/text.dart';
import 'package:chat_app/view/screens/mainscreen/loginpage.dart';
import 'package:chat_app/view/widget/elevatedbutton.dart';
import 'package:flutter/material.dart';

class Onboardinscreen extends StatefulWidget {
  const Onboardinscreen({super.key});

  @override
  State<Onboardinscreen> createState() => _OnboardinscreenState();
}

class _OnboardinscreenState extends State<Onboardinscreen> {
  int currentIndex = 0;
  final PageController _controller = PageController();
  Timer? _timer;

  List<Map<String, String>> onboardlist = [
    {
      "image": "assets/images/onboard1.png",
      "text1": "Group Chatting",
      "text2": "Connect with multiple members in group chats.",
    },
    {
      "image": "assets/images/onboard2.png",
      "text1": "Video and Voice Calls",
      "text2": "Instantly connect via video and voice calls.",
    },
    {
      "image": "assets/images/onboard3.png",
      "text1": "Message Encryption",
      "text2": "Ensure privacy with encrypted messages.",
    },
    {
      "image": "assets/images/onboard4.png",
      "text1": "Cross-Platform Compatibility",
      "text2": "Access chats on any device seamlessly.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (currentIndex < onboardlist.length - 1) {
        _controller.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _controller.jumpToPage(0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xff092a51),
      body: Stack(
        children: [
          CustomPaint(
            size: Size(size.width, size.height * .67),
            painter: BottomCurvePainter1(), // see below for the class
          ),
          CustomPaint(
            size: Size(size.width, size.height * .62),
            painter: BottomCurvePainter2(), // see below for the class
          ),
          Column(
            children: [
              // SizedBox(height: size.height * .08),
              SizedBox(
                width: size.width,
                height: size.height * .65,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: onboardlist.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                    _startAutoSlide();
                  },
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        SizedBox(height: size.height * .08),
                        SizedBox(
                          width: size.width * .6,
                          height: size.height * .25,
                          child: Image.asset(onboardlist[index]["image"]!),
                        ),
                        SizedBox(height: size.height * .03),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * .1,
                          ),
                          child: Text(
                            onboardlist[index]["text1"]!,
                            textAlign: TextAlign.center,
                            style: Apptexts.titlestyle.copyWith(
                              fontSize: size.width * .07,
                              color: const Color(0xff40C4FF),
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * .015),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * .1,
                          ),
                          child: Text(
                            onboardlist[index]["text2"]!,
                            textAlign: TextAlign.center,
                            style: Apptexts.subtitlestyle.copyWith(
                              color: const Color(0xff40C4FF),
                              fontSize: size.width * .045,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              SizedBox(height: size.height * .08),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * .01),
                child: CustomElevatedButton(
                  text: "Get started",
                  onPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Loginpage()),
                    );
                  },
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.only(
                  left: size.width * .06,
                  right: size.width * .03,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _controller.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        "Skip",
                        style: Apptexts.subtitlestyle.copyWith(
                          color: const Color(0xff3AB2E8),
                          fontSize: size.width * .05,
                        ),
                      ),
                    ),

                    Row(
                      children: List.generate(
                        onboardlist.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: currentIndex == index ? 12 : 8,
                          height: currentIndex == index ? 12 : 8,
                          decoration: BoxDecoration(
                            color:
                                currentIndex == index
                                    ? const Color(0xff3AB2E8)
                                    : const Color(0xffA7E4FF),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        if (currentIndex < onboardlist.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        } else {
                          // Navigator.pushReplacementNamed(context, "/login");
                        }
                      },
                      child: CircleAvatar(
                        backgroundColor: const Color(0xffA7E4FF),
                        radius: size.width * .1,
                        child: Text(
                          currentIndex == onboardlist.length - 1
                              ? "Finish"
                              : "Next",
                          style: Apptexts.subtitlestyle.copyWith(
                            color: const Color(0xff1B526B),
                            fontSize: size.width * .045,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * .05),
            ],
          ),
        ],
      ),
    );
  }
}

class BottomCurvePainter1 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Color(0xff393a4c)
          ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class BottomCurvePainter2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Color(0xff292929)
          ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height - 100);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 100,
    );
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
