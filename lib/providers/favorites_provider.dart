import 'package:flutter/foundation.dart';
import '../models/universidad.dart';
import '../services/favorites_service.dart';

class FavoritesProvider with ChangeNotifier {
  final FavoritesService _favoritesService = FavoritesService();
  List<Universidad> _favorites = [];
  bool _isLoading = false;

  List<Universidad> get favorites => _favorites;
  bool get isLoading => _isLoading;

  // Inicializar el stream de favoritos
  void init() {
    _favoritesService.getFavorites().listen((favorites) {
      _favorites = favorites;
      notifyListeners();
    });
  }

  // Agregar o quitar de favoritos
  Future<bool> toggleFavorite(Universidad universidad) async {
    _isLoading = true;
    notifyListeners();

    try {
      final isFavorite = await _favoritesService.toggleFavorite(universidad);
      return isFavorite;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verificar si una universidad está en favoritos
  Future<bool> isFavorite(String universidadNombre) {
    return _favoritesService.isFavorite(universidadNombre);
  }
} 