// Importaciones necesarias para la autenticación
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

// Proveedor que maneja el estado de autenticación y notifica a los widgets cuando cambia
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;

  // Getters para acceder al estado de autenticación
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  // Constructor que inicializa el listener de cambios de autenticación
  AuthProvider() {
    _init();
  }

  // Configura el listener para cambios en el estado de autenticación
  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Inicia sesión con email y contraseña
  // Retorna true si el login fue exitoso, false en caso contrario
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.loginUserWithEmailAndPassword(email, password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Registra un nuevo usuario con email y contraseña
  // Retorna true si el registro fue exitoso, false en caso contrario
  Future<bool> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.createUserWithEmailAndPassword(email, password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cierra la sesión del usuario actual
  Future<void> logout() async {
    await _authService.signout();
    _user = null;
    notifyListeners();
  }
} 