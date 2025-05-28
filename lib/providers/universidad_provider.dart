import 'package:flutter/material.dart';
import '../models/universidad.dart';

class UniversidadProvider extends ChangeNotifier {
  List<Universidad> _universidades = [];
  Map<String, double> _ratings = {};
  Map<String, int> _numReviews = {};
  bool _isInitialized = false;

  List<Universidad> get universidades => _universidades;
  Map<String, double> get ratings => _ratings;
  Map<String, int> get numReviews => _numReviews;
  bool get isInitialized => _isInitialized;

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

  void clear() {
    _universidades = [];
    _ratings = {};
    _numReviews = {};
    _isInitialized = false;
    notifyListeners();
  }
} 