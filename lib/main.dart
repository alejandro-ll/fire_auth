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

  // GlobalKey para el Navigator, utilizado para navegación segura en enlaces mágicos
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
    // Escucha enlaces entrantes
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        print('Received URI: ${uri.toString()}');
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      print('Error occurred: $err');
    });

    // Manejo de enlace inicial
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

    // Verifica si es un enlace de inicio de sesión por correo electrónico
    if (FirebaseAuth.instance.isSignInWithEmailLink(uri.toString())) {
      final String email = queryParams['email'] ?? '';
      print('Email: $email');
      if (email.isNotEmpty) {
        // Inicia sesión con enlace mágico
        await AuthService().signInWithEmailLink(
          email: email,
          emailLink: uri.toString(),
        );
      } 
    } else if (path == '/login') {
      MyApp.navigatorKey.currentState?.pushNamed('/login');
    } else if (path == '/signup') {
      MyApp.navigatorKey.currentState?.pushNamed('/signup');
    } else {
      MyApp.navigatorKey.currentState?.pushNamed('/');
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
      navigatorKey: MyApp.navigatorKey,
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
