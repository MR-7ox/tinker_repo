import 'package:flutter/material.dart';
import 'package:gigfind/Screens/home_screen.dart';
import 'package:gigfind/Screens/login_Screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gigfind/Screens/trash_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:gigfind/Screens/navigation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

final GoRouter _router = GoRouter(
  redirect: (context, state) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final loggingIn = state.uri.path == '/';

    if (!loggedIn) return loggingIn ? null : '/';
    if (loggingIn) return '/home';

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => Login_Screen()),
    ShellRoute(
      builder: (context, state, child) {
        return NavigationScreen(child: child);
      },
      routes: [
        GoRoute(path: '/home', builder: (context, state) => Home_Screen()),
        GoRoute(
          path: '/trollscreen',
          builder: (context, state) => TrollChatScreen(),
        ),
      ],
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  return runApp(MyAPP());
}

class MyAPP extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GigFind',
      routerConfig: _router,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(
          0xFF0A0A2A,
        ), // Dark blue-purple background
        primaryColor: Color(0xFF00C8F8), // Neon blue primary color
        hintColor: Color(0xFF9B59B6), // Purple accent color
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          headlineMedium: TextStyle(
            color: Color(0xFF00C8F8),
          ), // Neon blue for headlines
          headlineSmall: TextStyle(
            color: Color(0xFF9B59B6),
          ), // Purple for sub-headlines
        ),
        cardColor: Colors.white.withOpacity(
          0.05,
        ), // Light transparent white for card backgrounds
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black.withOpacity(
            0.3,
          ), // Slightly transparent black
          selectedItemColor: Color(0xFF00C8F8), // Neon blue for selected items
          unselectedItemColor: Colors.white70, // White-ish for unselected items
        ),
      ),
    );
  }
}
