import 'package:distriservicios_app_3/model/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../layaout/home_home.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  getCurrentUser() async {
    return await auth.currentUser;
  }

  signInWithGoogle(BuildContext context) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final GoogleSignIn googleSignIn = GoogleSignIn(
        //   scopes: [
        //   'https://www.googleapis.com/auth/drive.apps.readonly',
        // ]
        );

    try {
      // 1. Iniciar sesión con Google
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      if (googleSignInAccount == null) {
        // El usuario canceló el inicio de sesión
        // print("El usuario canceló el inicio de sesión");
        return;
      }

      // 2. Obtener la autenticación de Google
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      // 3. Verificar que la autenticación de Google es válida
      if (googleSignInAuthentication.accessToken == null) {
        // print("Error: No se obtuvo el access token.");
        return;
      }

      // 4. Obtener el access token
      String accessToken = googleSignInAuthentication.accessToken!;
      // print("Access Token obtenido: $accessToken");

      // 5. Crear las credenciales de Firebase usando el access token y idToken
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );

      // 6. Iniciar sesión en Firebase con las credenciales
      UserCredential result =
          await firebaseAuth.signInWithCredential(credential);
      User? userDetails = result.user;

      // 7. Comprobar si el usuario se ha autenticado correctamente
      if (userDetails != null) {
        Map<String, dynamic> userInfoMap = {
          "email": userDetails.email,
          "name": userDetails.displayName,
          "imgUrl": userDetails.photoURL,
          "id": userDetails.uid
        };

        // 8. Almacenar los datos del usuario en la base de datos (opcional, dependiendo de tu aplicación)
        await DatabaseMethods()
            .addUser(userDetails.uid, userInfoMap)
            .then((value) {
          if (context.mounted) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const HomeHome()));
          }
        });
      }
    } catch (e) {
      // print("Error durante el inicio de sesión: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al iniciar sesión: ${e.toString()}")),
      );
    }
  }
}
