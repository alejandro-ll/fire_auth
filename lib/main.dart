import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'pages/home/home.dart';
import 'pages/login/login.dart';
import 'pages/signup/signup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    initUniLinks();
  }

  Future<void> initUniLinks() async {
    // Handle incoming links
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        print('Received URI: ${uri.toString()}');
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      print('Error occurred: $err');
    });

    // Handle initial link
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        print('Initial URI: ${initialUri.toString()}');
        _handleDeepLink(initialUri);
      }
    } on Exception catch (e) {
      print('Failed to get initial link: $e');
    }
  }

  void _handleDeepLink(Uri uri) async {
    final path = uri.path;
    final queryParams = uri.queryParameters;

    if (FirebaseAuth.instance.isSignInWithEmailLink(uri.toString())) {
      final String email = queryParams['email'] ?? '';
      print('Email: $email');
      if (email.isNotEmpty) {
        await AuthService().signInWithEmailLink(
          email: email,
          emailLink: uri.toString(),
          context: context,
        );
        Future.delayed(Duration.zero, () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const Home(),
            ),
          );
        });
      }
    } else if (path == '/login') {
      Navigator.pushNamed(context, '/login');
    } else if (path == '/signup') {
      Navigator.pushNamed(context, '/signup');
    } else {
      // Handle other paths or show an error page
      Navigator.pushNamed(context, '/');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deep Link Example',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => FirebaseAuth.instance.currentUser != null ? Home() : Login(),
        '/login': (context) => Login(),
        '/signup': (context) => Signup(),
        '/home': (context) => Home(),
      },
    );
  }
}