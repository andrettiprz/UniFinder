import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/universidad.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Referencia a la colección de favoritos
  CollectionReference<Map<String, dynamic>> _favoritesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('favorites');
  }

  // Agregar una universidad a favoritos
  Future<void> addToFavorites(Universidad universidad) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _favoritesCollection(user.uid).doc(universidad.nombre).set({
      'nombre': universidad.nombre,
      'carreras': universidad.carreras,
      'contacto': universidad.contacto,
      'direccion': universidad.direccion,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Eliminar una universidad de favoritos
  Future<void> removeFromFavorites(String universidadNombre) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _favoritesCollection(user.uid).doc(universidadNombre).delete();
  }

  // Obtener todas las universidades favoritas
  Stream<List<Universidad>> getFavorites() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _favoritesCollection(user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Universidad.fromJson(data);
      }).toList();
    });
  }

  // Verificar si una universidad está en favoritos
  Future<bool> isFavorite(String universidadNombre) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _favoritesCollection(user.uid)
        .doc(universidadNombre)
        .get();
    
    return doc.exists;
  }

  // Toggle favorito
  Future<bool> toggleFavorite(Universidad universidad) async {
    final isFav = await isFavorite(universidad.nombre);
    if (isFav) {
      await removeFromFavorites(universidad.nombre);
      return false;
    } else {
      await addToFavorites(universidad);
      return true;
    }
  }
} 