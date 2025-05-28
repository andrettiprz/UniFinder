import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reviews';

  // Obtener todas las reviews de una universidad
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

  // Obtener todas las reviews de un usuario
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

  // Obtener universidades con reviews, ordenadas por rating
  Future<QuerySnapshot> getUniversidadesConReviews() async {
    // Crear una colección de agregación de reviews por universidad
    final reviewsAggregationRef = _firestore.collection('universidades_reviews');
    
    // Obtener las universidades ordenadas por rating
    return await reviewsAggregationRef
        .orderBy('rating', descending: true)
        .limit(20)
        .get();
  }

  // Crear una nueva review
  Future<Review> createReview(Review review) async {
    final docRef = await _firestore.collection(_collection).add(review.toJson());
    
    // Actualizar la agregación de reviews
    await _actualizarAgregacionReviews(review.universidadId);
    
    return review.copyWith(id: docRef.id);
  }

  // Actualizar una review existente
  Future<void> updateReview(Review review) async {
    await _firestore
        .collection(_collection)
        .doc(review.id)
        .update(review.toJson());
    
    // Actualizar la agregación de reviews
    await _actualizarAgregacionReviews(review.universidadId);
  }

  // Eliminar una review
  Future<void> deleteReview(String reviewId) async {
    final reviewDoc = await _firestore.collection(_collection).doc(reviewId).get();
    if (!reviewDoc.exists) return;
    
    final universidadId = reviewDoc.data()?['universidadId'] as String?;
    if (universidadId == null) return;
    
    await reviewDoc.reference.delete();
    
    // Actualizar la agregación de reviews
    await _actualizarAgregacionReviews(universidadId);
  }

  // Actualizar la agregación de reviews para una universidad
  Future<void> _actualizarAgregacionReviews(String universidadId) async {
    final reviews = await _firestore
        .collection(_collection)
        .where('universidadId', isEqualTo: universidadId)
        .get();

    if (reviews.docs.isEmpty) {
      // Si no hay reviews, eliminar el documento de agregación
      await _firestore.collection('universidades_reviews').doc(universidadId).delete();
      return;
    }

    double totalRating = 0;
    for (var doc in reviews.docs) {
      totalRating += (doc.data()['rating'] as num).toDouble();
    }

    final avgRating = totalRating / reviews.docs.length;

    // Actualizar o crear el documento de agregación
    await _firestore.collection('universidades_reviews').doc(universidadId).set({
      'universidadId': universidadId,
      'rating': avgRating,
      'numReviews': reviews.docs.length,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Obtener el promedio de ratings de una universidad
  Future<double> getUniversidadRatingPromedio(String universidadId) async {
    final doc = await _firestore
        .collection('universidades_reviews')
        .doc(universidadId)
        .get();

    if (!doc.exists) return 0.0;
    return (doc.data()?['rating'] as num?)?.toDouble() ?? 0.0;
  }

  // Verificar si un usuario ya ha hecho review de una universidad
  Future<bool> hasUserReviewed(String userId, String universidadId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('universidadId', isEqualTo: universidadId)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }
} 