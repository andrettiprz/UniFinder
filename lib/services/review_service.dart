import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

// Servicio que maneja todas las operaciones relacionadas con las reseñas de universidades
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reviews';

  // Obtiene un stream de reseñas para una universidad específica
  // Este stream se actualiza automáticamente cuando hay cambios en las reseñas
  Stream<List<Review>> getUniversidadReviews(String universidadId) {
    return _firestore
        .collection(_collection)
        .where('universidadId', isEqualTo: universidadId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Review.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  // Obtiene un stream de todas las reseñas hechas por un usuario específico
  // Este stream se actualiza automáticamente cuando el usuario crea o modifica sus reseñas
  Stream<List<Review>> getUserReviews(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Review.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  // Obtiene las 20 universidades mejor calificadas que tienen reseñas
  // Los resultados están ordenados por rating de mayor a menor
  Future<QuerySnapshot> getUniversidadesConReviews() async {
    // Usar la colección de agregación para obtener datos pre-calculados
    final reviewsAggregationRef = _firestore.collection('universidades_reviews');
    
    // Obtener las universidades ordenadas por rating
    return await reviewsAggregationRef
        .orderBy('rating', descending: true)
        .limit(20)
        .get();
  }

  // Crea una nueva reseña en la base de datos y actualiza las estadísticas
  // Retorna la reseña creada con su ID asignado
  Future<Review> createReview(Review review) async {
    final docRef = await _firestore.collection(_collection).add(review.toJson());
    
    // Actualizar las estadísticas agregadas de la universidad
    await _actualizarAgregacionReviews(review.universidadId);
    
    return review.copyWith(id: docRef.id);
  }

  // Actualiza una reseña existente y recalcula las estadísticas
  Future<void> updateReview(Review review) async {
    await _firestore
        .collection(_collection)
        .doc(review.id)
        .update(review.toJson());
    
    // Actualizar las estadísticas agregadas de la universidad
    await _actualizarAgregacionReviews(review.universidadId);
  }

  // Elimina una reseña y actualiza las estadísticas de la universidad
  Future<void> deleteReview(String reviewId) async {
    final reviewDoc = await _firestore.collection(_collection).doc(reviewId).get();
    if (!reviewDoc.exists) return;
    
    final universidadId = reviewDoc.data()?['universidadId'] as String?;
    if (universidadId == null) return;
    
    await reviewDoc.reference.delete();
    
    // Actualizar las estadísticas agregadas de la universidad
    await _actualizarAgregacionReviews(universidadId);
  }

  // Método privado que actualiza las estadísticas agregadas de una universidad
  // Calcula el promedio de ratings y el número total de reseñas
  Future<void> _actualizarAgregacionReviews(String universidadId) async {
    // Obtener todas las reseñas de la universidad
    final reviews = await _firestore
        .collection(_collection)
        .where('universidadId', isEqualTo: universidadId)
        .get();

    if (reviews.docs.isEmpty) {
      // Si no hay reseñas, eliminar el documento de agregación
      await _firestore.collection('universidades_reviews').doc(universidadId).delete();
      return;
    }

    // Calcular el rating promedio
    double totalRating = 0;
    for (var doc in reviews.docs) {
      totalRating += (doc.data()['rating'] as num).toDouble();
    }

    final avgRating = totalRating / reviews.docs.length;

    // Actualizar o crear el documento con las estadísticas agregadas
    await _firestore.collection('universidades_reviews').doc(universidadId).set({
      'universidadId': universidadId,
      'rating': avgRating,
      'numReviews': reviews.docs.length,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Obtiene el rating promedio actual de una universidad
  // Retorna 0.0 si la universidad no tiene reseñas
  Future<double> getUniversidadRatingPromedio(String universidadId) async {
    final doc = await _firestore
        .collection('universidades_reviews')
        .doc(universidadId)
        .get();

    if (!doc.exists) return 0.0;
    return (doc.data()?['rating'] as num?)?.toDouble() ?? 0.0;
  }

  // Verifica si un usuario ya ha hecho una reseña para una universidad específica
  // Retorna true si el usuario ya tiene una reseña, false en caso contrario
  Future<bool> hasUserReviewed(String userId, String universidadId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('universidadId', isEqualTo: universidadId)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }
} 