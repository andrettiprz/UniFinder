import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/universidad.dart';

// Servicio que maneja todas las operaciones relacionadas con las universidades
class UniversidadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'universidades';

  // URL del archivo JSON con los datos iniciales de las universidades
  static const String baseUrl =
      'https://gist.githubusercontent.com/andrettiprz/e983726f070f9a6e92c0a3254e306dae/raw/c14ecd2016f460c6e7a78afc1061eb8a92b372e1/universidades_limpias.json';

  // Obtiene la lista completa de universidades desde el archivo JSON
  Future<List<Universidad>> getUniversidades() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Universidad.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load universities');
      }
    } catch (e) {
      developer.log('Error in getUniversidades: $e');
      throw Exception('Error loading universities: $e');
    }
  }

  // Obtiene un stream de universidades ordenadas por rating desde Firestore
  Stream<List<Universidad>> getUniversidadesStream() {
    try {
      return _firestore
          .collection(_collection)
          .orderBy('rating', descending: true)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              return [];
            }
            return snapshot.docs.map((doc) {
              try {
                // Convertir los datos de Firestore al modelo Universidad
                return Universidad.fromJson({
                  ...doc.data(),
                  'nombre': doc.id,
                  'carreras': doc.data()['carreras'] ?? [],
                  'contacto': doc.data()['contacto'] ?? {},
                  'direccion': doc.data()['direccion'] ?? {},
                });
              } catch (e) {
                developer.log('Error parsing universidad ${doc.id}: $e');
                return null;
              }
            })
            .where((u) => u != null)
            .cast<Universidad>()
            .toList();
          });
    } catch (e) {
      developer.log('Error in getUniversidadesStream: $e');
      return Stream.value([]);
    }
  }

  // Actualiza el rating y número de reseñas de una universidad
  Future<void> actualizarRating(String universidadId, double nuevoRating, int numReviews) async {
    try {
      developer.log('Actualizando rating para universidad: $universidadId');
      developer.log('Nuevo rating: $nuevoRating, Num reviews: $numReviews');
      
      // Verificar si la universidad existe en Firestore
      final docRef = _firestore.collection(_collection).doc(universidadId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        developer.log('Error: Universidad no encontrada en Firestore: $universidadId');
        // Crear un nuevo documento si la universidad no existe
        await docRef.set({
          'carreras': [],
          'contacto': {},
          'direccion': {},
          'rating': nuevoRating,
          'numReviews': numReviews,
        });
        return;
      }
      
      // Actualizar el rating y número de reseñas
      await docRef.update({
        'rating': nuevoRating,
        'numReviews': numReviews,
      });
      
      developer.log('Rating actualizado correctamente');
    } catch (e) {
      developer.log('Error al actualizar rating: $e');
      throw Exception('Error al actualizar rating: $e');
    }
  }

  // Obtiene una universidad específica por su ID desde Firestore
  Future<Universidad?> getUniversidad(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return Universidad.fromJson({...doc.data()!, 'nombre': doc.id});
    }
    return null;
  }
} 