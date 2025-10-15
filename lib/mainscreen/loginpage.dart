import 'package:chat_app/bottomnavigation.dart';
import 'package:chat_app/constants/text.dart';
import 'package:chat_app/constants/utils.dart';
import 'package:chat_app/mainscreen/signuppage.dart';
import 'package:chat_app/state/authstate.dart';
import 'package:chat_app/widget/elevatedbutton.dart';
import 'package:chat_app/widget/textfield.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  bool isvisible = false;
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<Authstate>(context, listen: false);
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Color(0xff292929),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: size.height * .27,
              color: Color(0xff092a51),
              child: Column(
                children: [
                  SizedBox(height: size.height * .13),
                  Text(
                    "Welcome Back!",
                    style: Apptexts.titlestyle.copyWith(color: Colors.white),
                  ),
                  SizedBox(height: size.height * .01),
                  Padding(
                    padding: const EdgeInsets.only(left: 30, right: 30),
                    child: Text(
                      textAlign: TextAlign.center,
                      "Stay connected with your friends anytime, anywhere.",
                      style: Apptexts.subtitlestyle.copyWith(
                        color: Colors.white,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: size.height * .09,
              color: Color(0xff2c2d3a),
            ),
            SizedBox(height: size.height * .05),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Email",
                    style: Apptexts.subtitlestyle.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * .01),
            ReactiveBorderTextField(
              controller: emailcontroller,
              label: "Email",
              hintText: "Enter your email",
              prefixIcon: Icons.email,
            ),
            SizedBox(height: size.height * .02),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Password",
                    style: Apptexts.subtitlestyle.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * .01),
            ReactiveBorderTextField(
              controller: passwordcontroller,
              label: "Password",
              hintText: "Enter your password",
              prefixIcon: Icons.password,
              obsecureText: isvisible,
              suffixIcon: isvisible ? Icons.visibility_off : Icons.visibility,
              onSuffixTap: () => setState(() => isvisible = !isvisible),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Forget Password?",
                    style: Apptexts.subtitlestyle.copyWith(
                      color: Color(0xff40C4FF),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * .04),
            CustomElevatedButton(
              text: "Login",
              onPress: () async {
                if (emailcontroller.text.isEmpty ||
                    passwordcontroller.text.isEmpty) {
                  SnackbarMessage.failedsnack(
                    "Please fill all the fields",
                    context,
                  );
                  return;
                }

                final String? error = await user.login(
                  email: emailcontroller.text.trim(),
                  password: passwordcontroller.text.trim(),
                );

                if (!mounted) return;

                if (error == null) {
                  AppUtils.showToast("Login successful");
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomBottomNavBar(),
                    ),
                  );
                } else {
                  SnackbarMessage.failedsnack(error, context);
                }
              },
            ),

            SizedBox(height: size.height * .03),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: size.width * .25,
                  child: Divider(
                    color: Color(0xff40C4FF),
                    thickness: 1,
                    indent: 10,
                  ),
                ),
                Text(
                  "Or continue with",
                  style: Apptexts.subtitlestyle.copyWith(color: Colors.white),
                ),
                SizedBox(
                  width: size.width * .25,
                  child: Divider(
                    color: Color(0xff40C4FF),
                    thickness: 1,
                    endIndent: 10,
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * .03),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  height: size.height * .07,
                  width: size.width * .175,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xff40C4FF)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.google,
                      color: Colors.white,
                      size: 37,
                    ),
                  ),
                ),
                Container(
                  height: size.height * .07,
                  width: size.width * .175,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xff40C4FF)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Icon(Icons.apple, color: Colors.white, size: 50),
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * .03),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?",
                  style: Apptexts.subtitlestyle.copyWith(color: Colors.white),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Signuppage()),
                    );
                  },
                  child: Text(
                    "Sign Up",
                    style: Apptexts.subtitlestyle.copyWith(
                      color: Color(0xff40C4FF),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
