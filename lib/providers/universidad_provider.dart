import 'package:flutter/material.dart';
import '../models/universidad.dart';

// Proveedor para manejar el estado de las universidades en la aplicación
class UniversidadProvider extends ChangeNotifier {
  // Lista de todas las universidades
  List<Universidad> _universidades = [];
  // Mapa de ratings por nombre de universidad
  Map<String, double> _ratings = {};
  // Mapa de número de reseñas por nombre de universidad
  Map<String, int> _numReviews = {};
  // Indica si el proveedor ha sido inicializado
  bool _isInitialized = false;

  // Getter que devuelve las universidades filtradas y ordenadas
  List<Universidad> get universidades {
    // Filtrar solo universidades con reseñas y ordenar por rating
    final universidadesConReviews = _universidades.where((u) {
      final numReviews = _numReviews[u.nombre] ?? 0;
      return numReviews > 0;
    }).toList();

    // Ordenar por rating de mayor a menor
    universidadesConReviews.sort((a, b) {
      final ratingA = _ratings[a.nombre] ?? 0.0;
      final ratingB = _ratings[b.nombre] ?? 0.0;
      return ratingB.compareTo(ratingA);
    });

    return universidadesConReviews;
  }
  
  // Getters para acceder a los datos del proveedor
  Map<String, double> get ratings => _ratings;
  Map<String, int> get numReviews => _numReviews;
  bool get isInitialized => _isInitialized;

  // Inicializa los datos del proveedor con la información proporcionada
  void initializeData({
    required List<Universidad> universidades,
    required Map<String, double> ratings,
    required Map<String, int> numReviews,
  }) {
    _universidades = universidades;
    _ratings = ratings;
    _numReviews = numReviews;
    _isInitialized = true;
    notifyListeners();
  }

  // Limpia todos los datos del proveedor
  void clear() {
    _universidades = [];
    _ratings = {};
    _numReviews = {};
    _isInitialized = false;
    notifyListeners();
  }
} 