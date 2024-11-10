import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

import 'login.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  String? userName;
  String? userEmail;
  String? userImageUrl;
  double _opacity = 0.0;
  late AnimationController _controller;
  late StreamSubscription<User?> _authSubscription;
  GoogleSignIn googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    checkUserAuthentication();
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LogIn()),
        );
      } else {
        loadUserProfile();
      }
    });

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Iniciar la animación de opacidad
    _controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });
  }

  void checkUserAuthentication() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LogIn()),
      );
    } else {
      loadUserProfile();
    }
  }

  Future<void> loadUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("User")
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          userName = doc['name'];
          userEmail = doc['email'];
          userImageUrl = doc['imgUrl'] ?? 'images/distri003.jpg';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(seconds: 1),
              child: CircleAvatar(
                radius: 100,
                backgroundImage: userImageUrl != null
                    ? NetworkImage(userImageUrl!)
                    : const AssetImage('images/distri003.jpg') as ImageProvider,
              ),
            ),
            const SizedBox(height: 16),
            Text(userName ?? 'Cargando...',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24)),
            Text(userEmail ?? 'Cargando...',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await logoutUser(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19),
                ),
                elevation: 5,
              ),
              child: const Text(
                "Cerrar Sesión",
                style: TextStyle(fontSize: 25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> logoutUser(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      // barrierColor: Colors.red.withOpacity(0.5),
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 7));

    if (context.mounted) {
      Navigator.pop(context);
    }

    try {
      // Desconectar del usuario unido a Firebase
      await FirebaseAuth.instance.signOut();

      // Desconectar la cuenta de Google
      await googleSignIn.disconnect();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LogIn()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // print("Error al cerrar sesión: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ha ocurrido un error: ${e.toString()}'),
          duration: const Duration(seconds: 7),
        ),
      );
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _controller.dispose();
    super.dispose();
  }
}
