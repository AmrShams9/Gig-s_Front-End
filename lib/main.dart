import 'package:flutter/material.dart';
import 'Screens/auth.dart';
import 'Screens/runner_home_screen.dart';
import 'Screens/poster_home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gigs',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DBF73),
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const PosterHomeScreen(); // Assuming PosterHomeScreen after login based on previous context
          }
          return const AuthScreen();
        },
      ),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/runner-home': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String?;
          return RunnerHomeScreen(
            profileImagePath: args ?? '',
          );
        },
        '/poster-home': (context) => const PosterHomeScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const AuthScreen(),
        );
      },
    );
  }
}