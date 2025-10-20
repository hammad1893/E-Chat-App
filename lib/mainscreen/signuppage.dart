import 'package:chat_app/constants/text.dart';
import 'package:chat_app/constants/utils.dart';
import 'package:chat_app/mainscreen/loginpage.dart';
import 'package:chat_app/mainscreen/userinfoscreen.dart';
import 'package:chat_app/state/authstate.dart';
import 'package:chat_app/widget/elevatedbutton.dart';
import 'package:chat_app/widget/textfield.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Signuppage extends StatefulWidget {
  const Signuppage({super.key});

  @override
  State<Signuppage> createState() => _SignuppageState();
}

class _SignuppageState extends State<Signuppage> {
  bool isvisible = false;
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
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
                    "Let’s Get Started",
                    style: Apptexts.titlestyle.copyWith(color: Colors.white),
                  ),
                  SizedBox(height: size.height * .01),
                  Padding(
                    padding: const EdgeInsets.only(left: 30, right: 30),
                    child: Text(
                      textAlign: TextAlign.center,
                      "join us and start your journey today.",
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
                    "Name",
                    style: Apptexts.subtitlestyle.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * .01),
            ReactiveBorderTextField(
              label: "Name",
              hintText: "Enter your name",
              controller: nameController,
            ),
            SizedBox(height: size.height * .02),
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
              controller: passwordController,
              label: "Password",
              hintText: "Enter your password",
              obsecureText: isvisible,
              suffixIcon: isvisible ? Icons.visibility_off : Icons.visibility,
              onSuffixTap: () => setState(() => isvisible = !isvisible),
            ),
            SizedBox(height: size.height * .05),
            CustomElevatedButton(
              text: "Sign Up",
              onPress: () async {
                if (emailcontroller.text.isEmpty ||
                    nameController.text.isEmpty ||
                    passwordController.text.isEmpty) {
                  SnackbarMessage.failedsnack(
                    "Please fill all the fields",
                    context,
                  );
                  return;
                } else if (!RegExp(
                  r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
                ).hasMatch(emailcontroller.text)) {
                  SnackbarMessage.failedsnack("Enter a valid email", context);
                  return;
                } else if (!RegExp(
                  r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$',
                ).hasMatch(passwordController.text)) {
                  SnackbarMessage.failedsnack(
                    "Password must be at least 8 chars, include upper, lower, number & special char",
                    context,
                  );
                  return;
                }

                user.signup(
                  name: nameController.text,
                  email: emailcontroller.text,
                  password: passwordController.text,
                );
                AppUtils.success(context, "Account created successfully");
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_logged_in', true);

                Navigator.push(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(builder: (context) => Userinfoscreen()),
                );
                emailcontroller.clear();
                nameController.clear();
                passwordController.clear();
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
                GestureDetector(
                  onTap: () {
                    user.signInWithGoogle(context);
                  },
                  child: Container(
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
                  "Already have an account?",
                  style: Apptexts.subtitlestyle.copyWith(color: Colors.white),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Loginpage()),
                    );
                  },
                  child: Text(
                    "Sign In",
                    style: Apptexts.subtitlestyle.copyWith(
                      color: Color(0xff40C4FF),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * .04),
          ],
        ),
      ),
    );
  }
}
