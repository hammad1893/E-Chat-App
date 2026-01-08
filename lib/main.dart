import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/view/screens/mainscreen/splashscreen.dart';
import 'package:chat_app/view_model/aichatstate.dart';
import 'package:chat_app/view_model/authstate.dart';
import 'package:chat_app/view_model/chatstate.dart';
import 'package:chat_app/view_model/groupstate.dart';
import 'package:chat_app/view_model/unread_count_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Authstate()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => UnreadCountProvider()),
        ChangeNotifierProvider(
          create: (_) => AiChatProvider('current_user_id'),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Chat App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: SplashScreen(),
      ),
    );
  }
}
