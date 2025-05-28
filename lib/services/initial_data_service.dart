import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/universidad.dart';
import '../services/universidad_service.dart';

class InitialDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UniversidadService _universidadService = UniversidadService();
  final Random _random = Random();

  final List<Map<String, dynamic>> _topUniversidades = [
    {'nombre': 'Universidad Nacional Autónoma de México (UNAM)', 'rating': 0.0},
    {'nombre': 'Instituto Tecnológico y de Estudios Superiores de Monterrey (ITESM)', 'rating': 0.0},
    {'nombre': 'Instituto Politécnico Nacional (IPN)', 'rating': 0.0},
    {'nombre': 'Universidad Autónoma Metropolitana (UAM)', 'rating': 0.0},
    {'nombre': 'Universidad Iberoamericana (IBERO)', 'rating': 0.0},
    {'nombre': 'Universidad de Guadalajara (UDG)', 'rating': 0.0},
    {'nombre': 'Universidad Autónoma de Nuevo León (UANL)', 'rating': 0.0},
    {'nombre': 'Instituto Tecnológico Autónomo de México (ITAM)', 'rating': 0.0},
    {'nombre': 'Universidad Anáhuac', 'rating': 0.0},
    {'nombre': 'Universidad de las Américas Puebla (UDLAP)', 'rating': 0.0},
    {'nombre': 'Universidad Autónoma de Guadalajara (UAG)', 'rating': 0.0},
    {'nombre': 'Universidad La Salle', 'rating': 0.0},
    {'nombre': 'Universidad Panamericana (UP)', 'rating': 0.0},
    {'nombre': 'Universidad del Valle de México (UVM)', 'rating': 0.0},
    {'nombre': 'Universidad Autónoma del Estado de México (UAEM)', 'rating': 0.0},
    {'nombre': 'Universidad de Monterrey (UDEM)', 'rating': 0.0},
    {'nombre': 'Universidad Autónoma de Baja California (UABC)', 'rating': 0.0},
    {'nombre': 'Universidad de Guanajuato (UG)', 'rating': 0.0},
    {'nombre': 'Universidad Autónoma de San Luis Potosí (UASLP)', 'rating': 0.0},
    {'nombre': 'Universidad Autónoma de Querétaro (UAQ)', 'rating': 0.0},
  ];

  final List<String> _comentariosPositivos = [
    'Excelente nivel académico y profesores muy preparados.',
    'Las instalaciones son de primer nivel.',
    'Gran ambiente estudiantil y muchas actividades extracurriculares.',
    'Los programas académicos están muy actualizados.',
    'Muy buena preparación para el mundo laboral.',
    'Excelentes oportunidades de investigación.',
    'El networking y las conexiones que se hacen aquí son invaluables.',
    'La biblioteca y recursos de estudio son excepcionales.',
    'Los laboratorios están muy bien equipados.',
    'Hay muchas oportunidades de intercambio internacional.',
  ];

  final List<String> _comentariosModerados = [
    'Buena universidad aunque hay aspectos por mejorar.',
    'Los profesores son buenos pero algunos cursos necesitan actualización.',
    'Las instalaciones son adecuadas pero podrían mejorar.',
    'Hay buenas oportunidades pero la competencia es fuerte.',
    'La calidad educativa es buena pero los costos son altos.',
    'Buen ambiente aunque algunos servicios pueden mejorar.',
    'Los programas son buenos pero podrían ser más prácticos.',
    'Hay buenos recursos pero a veces son insuficientes.',
    'La experiencia es positiva pero hay que ser muy autodidacta.',
    'Buena opción educativa aunque hay que ser muy organizado.',
  ];

  String _generarComentarioAleatorio(double rating) {
    if (rating >= 4.0) {
      return _comentariosPositivos[_random.nextInt(_comentariosPositivos.length)];
    } else {
      return _comentariosModerados[_random.nextInt(_comentariosModerados.length)];
    }
  }

  Future<void> generarReviewsIniciales() async {
    try {
      // Primero crear las universidades
      await _crearUniversidades();

      // Luego generar las reviews en lotes más pequeños
      for (var universidad in _topUniversidades) {
        // Generar entre 5 y 10 reviews por universidad
        final numReviews = 5 + _random.nextInt(6);
        final reviews = <Review>[];
        
        for (var i = 0; i < numReviews; i++) {
          final rating = universidad['rating'] + (_random.nextDouble() * 0.4 - 0.2);
          final adjustedRating = double.parse(rating.toStringAsFixed(1));
          
          final review = Review(
            id: _firestore.collection('reviews').doc().id,
            userId: 'sistema',
            userName: 'Usuario ${_random.nextInt(1000)}',
            universidadId: universidad['nombre'],
            universidadNombre: universidad['nombre'],
            rating: adjustedRating,
            comentario: _generarComentarioAleatorio(adjustedRating),
            fecha: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
          );
          
          reviews.add(review);
        }
        
        // Crear las reviews en lotes de 5
        for (var i = 0; i < reviews.length; i += 5) {
          final batch = _firestore.batch();
          final end = i + 5 > reviews.length ? reviews.length : i + 5;
          
          for (var j = i; j < end; j++) {
            final review = reviews[j];
            final docRef = _firestore.collection('reviews').doc(review.id);
            batch.set(docRef, review.toJson());
          }
          
          await batch.commit();
          // Esperar un momento entre lotes para no sobrecargar Firestore
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        // Actualizar el rating y numReviews de la universidad
        final avgRating = reviews.fold<double>(0, (sum, review) => sum + review.rating) / reviews.length;
        await _firestore.collection('universidades').doc(universidad['nombre']).update({
          'rating': double.parse(avgRating.toStringAsFixed(1)),
          'numReviews': reviews.length,
        });
        
        // Esperar un momento entre universidades
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Error al generar reviews iniciales: $e');
      throw Exception('Error al generar reviews iniciales: $e');
    }
  }

  Future<void> _crearUniversidades() async {
    try {
      final batch = _firestore.batch();
      
      for (var universidad in _topUniversidades) {
        final docRef = _firestore.collection('universidades').doc(universidad['nombre']);
        batch.set(docRef, {
          'carreras': [],
          'contacto': {},
          'direccion': {},
          'rating': 0.0,
          'numReviews': 0,
        });
      }
      
      await batch.commit();
    } catch (e) {
      print('Error al crear universidades: $e');
      throw Exception('Error al crear universidades: $e');
    }
  }

  Future<void> inicializarUniversidades() async {
    try {
      // Verificar si ya existen universidades
      final snapshot = await _firestore.collection('universidades').limit(1).get();
      if (!snapshot.docs.isEmpty) {
        print('Las universidades ya están inicializadas');
        return;
      }

      // Obtener todas las universidades del JSON
      final universidades = await _universidadService.getUniversidades();
      print('Inicializando ${universidades.length} universidades en Firestore...');

      // Crear las universidades en lotes para no sobrecargar Firestore
      final batchSize = 500;
      for (var i = 0; i < universidades.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < universidades.length) ? i + batchSize : universidades.length;
        
        for (var j = i; j < end; j++) {
          final universidad = universidades[j];
          final docRef = _firestore.collection('universidades').doc(universidad.nombre);
          batch.set(docRef, {
            'carreras': universidad.carreras,
            'contacto': universidad.contacto,
            'direccion': universidad.direccion,
            'rating': 0.0,
            'numReviews': 0,
          });
        }
        
        await batch.commit();
        print('Inicializadas universidades ${i + 1} a $end');
        
        // Pequeña pausa entre lotes para no sobrecargar Firestore
        if (end < universidades.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      print('Universidades inicializadas correctamente');
    } catch (e) {
      print('Error al inicializar universidades: $e');
      throw Exception('Error al inicializar universidades: $e');
    }
  }

  Future<void> borrarTodasLasReviews() async {
    try {
      // 1. Obtener todas las reviews
      final reviewsSnapshot = await _firestore.collection('reviews').get();
      
      // 2. Borrar todas las reviews en lotes
      final batch = _firestore.batch();
      for (var doc in reviewsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      // 3. Reiniciar los ratings de todas las universidades
      final universidadesSnapshot = await _firestore.collection('universidades').get();
      final batchUniversidades = _firestore.batch();
      
      for (var doc in universidadesSnapshot.docs) {
        batchUniversidades.update(doc.reference, {
          'rating': 0.0,
          'numReviews': 0,
        });
      }
      await batchUniversidades.commit();
      
      print('Todas las reviews han sido borradas y los ratings reiniciados');
    } catch (e) {
      print('Error al borrar las reviews: $e');
      throw Exception('Error al borrar las reviews: $e');
    }
  }
} 