import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:police_app/Auth.dart';
import 'package:police_app/pages/login_page.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'pages/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:  StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if(snapshot.hasData){
           print("Snapshort:::::::::::${snapshot.data?.uid}");
           return const HomePage();
          }
          else{
            //  return const RegisterPage(title: 'Police Report Sign Up');
             return const LoginPage();

          }
        },
        ),
        routes: {
          '/login_page/': (context) => const LoginPage(),
          '/register_page/': (context) => const RegisterPage(),
          '/home_page/': (context) => const HomePage(),
        },
    );
  }
}
