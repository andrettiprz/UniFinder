import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/universidad.dart';

class UniversidadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'universidades';

  static const String baseUrl =
      'https://gist.githubusercontent.com/andrettiprz/e983726f070f9a6e92c0a3254e306dae/raw/c14ecd2016f460c6e7a78afc1061eb8a92b372e1/universidades_limpias.json';

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
      print('Error in getUniversidades: $e');
      throw Exception('Error loading universities: $e');
    }
  }

  // Obtener todas las universidades ordenadas por rating
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
                return Universidad.fromJson({
                  ...doc.data(),
                  'nombre': doc.id,
                  'carreras': doc.data()['carreras'] ?? [],
                  'contacto': doc.data()['contacto'] ?? {},
                  'direccion': doc.data()['direccion'] ?? {},
                });
              } catch (e) {
                print('Error parsing universidad ${doc.id}: $e');
                return null;
              }
            })
            .where((u) => u != null)
            .cast<Universidad>()
            .toList();
          });
    } catch (e) {
      print('Error in getUniversidadesStream: $e');
      return Stream.value([]);
    }
  }

  // Actualizar el rating de una universidad
  Future<void> actualizarRating(String universidadId, double nuevoRating, int numReviews) async {
    try {
      print('Actualizando rating para universidad: $universidadId');
      print('Nuevo rating: $nuevoRating, Num reviews: $numReviews');
      
      // Verificar si el documento existe antes de actualizarlo
      final docRef = _firestore.collection(_collection).doc(universidadId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        print('Error: Universidad no encontrada en Firestore: $universidadId');
        // Intentar crear el documento si no existe
        await docRef.set({
          'carreras': [],
          'contacto': {},
          'direccion': {},
          'rating': nuevoRating,
          'numReviews': numReviews,
        });
        return;
      }
      
      await docRef.update({
        'rating': nuevoRating,
        'numReviews': numReviews,
      });
      
      print('Rating actualizado correctamente');
    } catch (e) {
      print('Error al actualizar rating: $e');
      throw Exception('Error al actualizar rating: $e');
    }
  }

  // Obtener una universidad por su ID
  Future<Universidad?> getUniversidad(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return Universidad.fromJson({...doc.data()!, 'nombre': doc.id});
    }
    return null;
  }
} 