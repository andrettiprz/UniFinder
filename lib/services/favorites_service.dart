import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/universidad.dart';

// Servicio que maneja todas las operaciones relacionadas con las universidades favoritas de los usuarios
class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtiene la referencia a la colección de favoritos de un usuario específico
  // Los favoritos se almacenan como una subcolección dentro del documento del usuario
  CollectionReference<Map<String, dynamic>> _favoritesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('favorites');
  }

  // Agrega una universidad a la lista de favoritos del usuario actual
  // Guarda los datos principales de la universidad y la marca de tiempo
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

  // Elimina una universidad de la lista de favoritos del usuario actual
  // Recibe el nombre de la universidad como identificador
  Future<void> removeFromFavorites(String universidadNombre) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _favoritesCollection(user.uid).doc(universidadNombre).delete();
  }

  // Obtiene un stream con la lista de universidades favoritas del usuario actual
  // El stream se actualiza automáticamente cuando hay cambios en los favoritos
  // Las universidades están ordenadas por fecha de agregado, las más recientes primero
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

  // Verifica si una universidad específica está en la lista de favoritos del usuario
  // Retorna true si la universidad está en favoritos, false en caso contrario
  Future<bool> isFavorite(String universidadNombre) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _favoritesCollection(user.uid)
        .doc(universidadNombre)
        .get();
    
    return doc.exists;
  }

  // Alterna el estado de favorito de una universidad
  // Si la universidad está en favoritos, la elimina; si no está, la agrega
  // Retorna true si la universidad fue agregada, false si fue eliminada
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