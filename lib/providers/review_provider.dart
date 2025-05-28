import 'package:flutter/foundation.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import '../services/universidad_service.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  final UniversidadService _universidadService = UniversidadService();
  List<Review> _userReviews = [];
  Map<String, List<Review>> _universidadReviews = {};
  Map<String, double> _promedioRatings = {};
  Map<String, bool> _loadingUniversidades = {};

  List<Review> get userReviews => _userReviews;
  Map<String, List<Review>> get universidadReviews => _universidadReviews;
  Map<String, double> get promedioRatings => _promedioRatings;

  // Cargar reviews de un usuario
  Future<void> loadUserReviews(String userId) async {
    _reviewService.getUserReviews(userId).listen((reviews) {
      _userReviews = reviews;
      notifyListeners();
    });
  }

  // Cargar reviews de una universidad
  Future<void> loadUniversidadReviews(String universidadId) async {
    // Evitar cargar múltiples veces
    if (_loadingUniversidades[universidadId] == true) {
      return;
    }
    
    _loadingUniversidades[universidadId] = true;
    
    // Limpiar las reviews existentes para esta universidad
    _universidadReviews[universidadId] = [];
    
    _reviewService.getUniversidadReviews(universidadId).listen(
      (reviews) {
        _universidadReviews[universidadId] = reviews;
        _actualizarRatingUniversidad(universidadId, reviews);
        notifyListeners();
      },
      onDone: () {
        _loadingUniversidades[universidadId] = false;
      },
    );
  }

  // Actualizar el rating de una universidad
  Future<void> _actualizarRatingUniversidad(String universidadId, List<Review> reviews) async {
    if (reviews.isEmpty) {
      _promedioRatings[universidadId] = 0.0;
      await _universidadService.actualizarRating(universidadId, 0.0, 0);
      return;
    }

    double total = 0;
    for (var review in reviews) {
      total += review.rating;
    }

    final promedio = total / reviews.length;
    _promedioRatings[universidadId] = promedio;
    await _universidadService.actualizarRating(universidadId, promedio, reviews.length);
    notifyListeners();
  }

  // Obtener el promedio de ratings de una universidad
  Future<double> getUniversidadRatingPromedio(String universidadId) async {
    if (!_promedioRatings.containsKey(universidadId)) {
      final promedio = await _reviewService.getUniversidadRatingPromedio(universidadId);
      _promedioRatings[universidadId] = promedio;
      notifyListeners();
    }
    return _promedioRatings[universidadId] ?? 0.0;
  }

  // Crear una nueva review
  Future<Review> createReview(Review review) async {
    final newReview = await _reviewService.createReview(review);
    
    // Actualizar las reviews del usuario
    if (!_userReviews.any((r) => r.id == newReview.id)) {
      _userReviews = [..._userReviews, newReview];
    }
    
    // Actualizar las reviews de la universidad
    final universidadId = review.universidadId;
    if (_universidadReviews.containsKey(universidadId)) {
      if (!_universidadReviews[universidadId]!.any((r) => r.id == newReview.id)) {
        _universidadReviews[universidadId] = [..._universidadReviews[universidadId]!, newReview];
        await _actualizarRatingUniversidad(universidadId, _universidadReviews[universidadId]!);
      }
    }
    
    notifyListeners();
    return newReview;
  }

  // Actualizar una review existente
  Future<void> updateReview(Review review) async {
    await _reviewService.updateReview(review);
    
    _userReviews = _userReviews.map((r) => r.id == review.id ? review : r).toList();
    
    final universidadId = review.universidadId;
    if (_universidadReviews.containsKey(universidadId)) {
      _universidadReviews[universidadId] = _universidadReviews[universidadId]!
          .map((r) => r.id == review.id ? review : r)
          .toList();
      await _actualizarRatingUniversidad(universidadId, _universidadReviews[universidadId]!);
    }
    
    notifyListeners();
  }

  // Eliminar una review
  Future<void> deleteReview(Review review) async {
    await _reviewService.deleteReview(review.id);
    
    _userReviews.removeWhere((r) => r.id == review.id);
    
    final universidadId = review.universidadId;
    if (_universidadReviews.containsKey(universidadId)) {
      _universidadReviews[universidadId]!.removeWhere((r) => r.id == review.id);
      await _actualizarRatingUniversidad(universidadId, _universidadReviews[universidadId]!);
    }
    
    notifyListeners();
  }

  // Verificar si un usuario ya ha hecho review de una universidad
  Future<bool> hasUserReviewed(String userId, String universidadId) {
    return _reviewService.hasUserReviewed(userId, universidadId);
  }

  // Limpiar los datos cuando sea necesario
  void clear() {
    _userReviews = [];
    _universidadReviews = {};
    _promedioRatings = {};
    _loadingUniversidades = {};
    notifyListeners();
  }
} 