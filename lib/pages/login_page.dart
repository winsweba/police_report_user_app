import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:police_app/Auth.dart';

import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });

  // final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final bool _isLogin = true;
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  User? userInfo = FirebaseAuth.instance.currentUser;

  final db = FirebaseFirestore.instance;

  handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.value.text.trim();
    final password = _passwordController.value.text.trim();

    setState(() {
      _loading = true;
      // print("objectBBBXXX::: ${user?.uid}");
    });

    try {
      await Auth().signWithEmailAndPassword(email, password);
      Navigator.of(context)
          .pushNamedAndRemoveUntil("/home_page/", (route) => false);
    } catch (e) {
      print("$e");
    }

    setState(() {
      _loading = false;
    });
  }


   @override
  void dispose() {
    // TODO: implement dispose
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login Now"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 8,
              ),
              Container(
                height: 250,
                width: 250,
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(width: 8),
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                        image: AssetImage('assets/police01.jpg'),
                        fit: BoxFit.fill)),
              ),
              const SizedBox(
                height: 8,
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please Valid email";
                          }
                          return null;
                        },
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "Enter Email"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please password should contain match";
                          }
                          return null;
                        },
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "Enter Password"),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 100,
                color: Colors.blue,
                margin: const EdgeInsets.all(25),
                child: ElevatedButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isLogin ? "Login " : 'SignUp',
                          style: TextStyle(fontSize: 20.0),
                        ),
                  onPressed: () => handleSubmit(),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(25),
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                  child: const Text("I Need Account"),
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        "/register_page/", (route) => false);
                    // Navigator.pushReplacement<void, void>(
                    //   context,
                    //   MaterialPageRoute<void>(
                    //     builder: (BuildContext context) =>
                    //         const RegisterPage(title: 'Police Report Sign Up'),
                    //   ),
                    // );

                    // setState(() {

                    // });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
