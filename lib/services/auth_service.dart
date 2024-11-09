import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../pages/home/home.dart';
import '../pages/login/login.dart';
import '../main.dart';

class AuthService {

  Future<void> sendSignInLinkToEmail({
    required String email,
    required BuildContext context,
  }) async {
    final baseUrl = 'https://my-test-auth-3b2be.web.app/action';
    final queryParams = {
      'mode': 'signIn',
      'email': email,
      'continueUrl': '/home'
    };

    final url = Uri.https(
      Uri.parse(baseUrl).host,
      Uri.parse(baseUrl).path,
      queryParams,
    ).toString();

    try {
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: url,
          handleCodeInApp: true,
          iOSBundleId: 'com.example.testAndoridFirebase',
          androidPackageName: 'com.example.test_andorid_firebase',
          androidInstallApp: false,
          androidMinimumVersion: '12',
        ),
      );
      Fluttertoast.showToast(
        msg: 'Sign-in link sent to $email',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch  
 (e) {
      Fluttertoast.showToast(
        msg: e.toString(),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,  

        textColor: Colors.white,
        fontSize:  
 14.0,
      );
    }
  }


  // Iniciar sesión con enlace de correo electrónico
  Future<void> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    try {
      // Intento de inicio de sesión con enlace de correo electrónico
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );

      // Comprobar si se autenticó el usuario
      if (userCredential.user != null) {
        print("Usuario autenticado correctamente.");

        // Pequeño retraso antes de la navegación para asegurar que el árbol de widgets esté listo
        await Future.delayed(Duration(milliseconds: 200));

        // Comprobar que navigatorKey tiene un estado válido antes de navegar
        if (MyApp.navigatorKey.currentState != null) {
          MyApp.navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(builder: (BuildContext context) => const Home()),
          );
          print("Navegación a Home iniciada.");
        } else {
          print("Error: navigatorKey no tiene un estado válido.");
        }
      } else {
        print("No se autenticó ningún usuario.");
      }
    } catch (e) {
      print("Error al iniciar sesión con el enlace: $e");
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }


  Future<void> signup({
    required String email,
    required String password,
    required BuildContext context
  }) async {
    
    try {

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const Home()
        )
      );
      
    } on FirebaseAuthException catch(e) {
      String message = '';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that email.';
      }
       Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
    catch(e){

    }

  }

  Future<void> signin({
    required String email,
    required String password,
    required BuildContext context
  }) async {
    
    try {

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const Home()
        )
      );
      
    } on FirebaseAuthException catch(e) {
      String message = '';
      if (e.code == 'invalid-email') {
        message = 'No user found for that email.';
      } else if (e.code == 'invalid-credential') {
        message = 'Wrong password provided for that user.';
      }
       Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
    catch(e){

    }

  }

  Future<void> signout({
    required BuildContext context
  }) async {
    
    await FirebaseAuth.instance.signOut();
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) =>Login()
        )
      );
  }
}