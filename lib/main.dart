import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:siba_weather/reusable_widgets/reusable_widget.dart';
import 'package:siba_weather/screens/signIn.dart';
import 'package:siba_weather/screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            // User is signed in
            String userName = snapshot.data!.displayName ?? '';
            final List<String> displayNameParts = userName.split(' ');
            final String firstName =
                displayNameParts.isNotEmpty ? displayNameParts[0] : '';
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: HomeScreen(
                userName: firstName,
              ),
              title: 'Hi_Weather',
              theme: ThemeData(
                scaffoldBackgroundColor: const Color(0xFFF4FFCD),
              ),
              initialRoute: '/home',
              routes: {
                '/signin': (context) => const SignInScreen(),
                '/home': (context) => HomeScreen(userName: firstName),
              },
            );
          } else {
            // User is not signed in
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: const SignInScreen(),
              title: 'Hi_Weather',
              theme: ThemeData(
                scaffoldBackgroundColor: const Color(0xFFF4FFCD),
              ),
              initialRoute: '/signin',
              routes: {
                '/signin': (context) => const SignInScreen(),
                '/home': (context) => const HomeScreen(
                      userName: '',
                    ),
              },
            );
          }
        } else {
          // Waiting for authentication state to be determined
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
            title: 'Hi_Weather',
            theme: ThemeData(
              scaffoldBackgroundColor: const Color(0xFFF4FFCD),
            ),
          );
        }
      },
    );
  }
}
