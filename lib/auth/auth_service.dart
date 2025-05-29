import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';

// Servicio que maneja las operaciones de autenticación con Firebase
class AuthService {
  // Instancia de Firebase Auth para realizar operaciones de autenticación
  final _auth = FirebaseAuth.instance;

  // Crea un nuevo usuario con email y contraseña
  // Retorna el usuario creado o null si ocurre un error
  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } catch (e) {
      log("Error al crear usuario: $e");
    }
    return null;
  }

  // Inicia sesión con email y contraseña
  // Retorna el usuario autenticado o null si ocurre un error
  Future<User?> loginUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } catch (e) {
      log("Error al iniciar sesión: $e");
    }
    return null;
  }

  // Cierra la sesión del usuario actual
  // No retorna nada, pero puede lanzar una excepción si ocurre un error
  Future<void> signout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      log("Error al cerrar sesión: $e");
    }
  }
}