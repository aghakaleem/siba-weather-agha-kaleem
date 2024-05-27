import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sign_button/sign_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:siba_weather/screens/home.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  User? user;
  String? firstName;
  StreamSubscription<User?>? _authStateChangesSubscription;

  @override
  void initState() {
    super.initState();
    _authStateChangesSubscription =
        firebaseAuth.authStateChanges().listen((event) {
      setState(() {
        user = event;
      });
    });
  }

  @override
  void dispose() {
    _authStateChangesSubscription?.cancel(); // Cancel the listener
    super.dispose();
  }

  Future<void> HandleGoogleSignIn() async {
    await Firebase.initializeApp();
    try {
      // Attempt to sign in with Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // If the user successfully signed in with Google
      if (googleUser != null) {
        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a credential from the access token
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in with Firebase using the credential
        await firebaseAuth.signInWithCredential(credential);
        final List<String> displayNameParts =
            googleUser.displayName!.split(' ');
        firstName = displayNameParts.isNotEmpty
            ? displayNameParts[0]
            : ''; // Store the first name

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                  userName:
                      firstName ?? ''), // Pass the first name to HomeScreen
            ));
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.height * 0.08,
              MediaQuery.of(context).size.height * 0.2,
              MediaQuery.of(context).size.height * 0.08,
              0),
          child: Column(
            children: <Widget>[
              logoWidget("lib/assets/images/logo.png"),
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              Text(
                "SIBA Weather",
                style: GoogleFonts.zenDots(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              Column(
                children: <Widget>[
                  googleSignInButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget googleSignInButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 50), // Adjust the padding as needed
      child: SizedBox(
        height: 50, // Set the height to 50
        child: SignInButton(
          buttonType: ButtonType.google,
          buttonSize: ButtonSize.medium,
          onPressed: HandleGoogleSignIn,
        ),
      ),
    );
  }

  Image logoWidget(String imagePath) {
    return Image.asset(imagePath,
        fit: BoxFit.fitWidth,
        width: MediaQuery.of(context).size.width * 0.48,
        height: MediaQuery.of(context).size.height * 0.25);
  }
}
