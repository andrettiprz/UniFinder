import 'dart:math';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';
import '../services/universidad_service.dart';

// Servicio encargado de inicializar y gestionar los datos iniciales de la aplicación
class InitialDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UniversidadService _universidadService = UniversidadService();
  final Random _random = Random();

  // Lista de las principales universidades de México para datos iniciales
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

  // Comentarios predefinidos positivos para reseñas con alta calificación
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

  // Comentarios predefinidos moderados para reseñas con calificación media
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

  // Genera un comentario aleatorio basado en la calificación
  String _generarComentarioAleatorio(double rating) {
    if (rating >= 4.0) {
      return _comentariosPositivos[_random.nextInt(_comentariosPositivos.length)];
    } else {
      return _comentariosModerados[_random.nextInt(_comentariosModerados.length)];
    }
  }

  // Genera reseñas iniciales para las universidades principales
  Future<void> generarReviewsIniciales() async {
    try {
      // Primero crear las universidades si no existen
      await _crearUniversidades();

      // Generar reseñas para cada universidad en la lista de top universidades
      for (var universidad in _topUniversidades) {
        // Generar entre 5 y 10 reseñas por universidad
        final numReviews = 5 + _random.nextInt(6);
        final reviews = <Review>[];
        
        // Crear las reseñas con datos aleatorios
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
        
        // Guardar las reseñas en lotes de 5 para no sobrecargar Firestore
        for (var i = 0; i < reviews.length; i += 5) {
          final batch = _firestore.batch();
          final end = i + 5 > reviews.length ? reviews.length : i + 5;
          
          for (var j = i; j < end; j++) {
            final review = reviews[j];
            final docRef = _firestore.collection('reviews').doc(review.id);
            batch.set(docRef, review.toJson());
          }
          
          await batch.commit();
          // Pausa entre lotes para evitar sobrecargar Firestore
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        // Actualizar el rating promedio y número de reseñas de la universidad
        final avgRating = reviews.fold<double>(0.0, (total, review) => total + review.rating) / reviews.length;
        await _firestore.collection('universidades').doc(universidad['nombre']).update({
          'rating': double.parse(avgRating.toStringAsFixed(1)),
          'numReviews': reviews.length,
        });
        
        // Pausa entre universidades para evitar sobrecargar Firestore
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      developer.log('Error al generar reviews iniciales: $e');
      throw Exception('Error al generar reviews iniciales: $e');
    }
  }

  // Crea las universidades principales en Firestore si no existen
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
      developer.log('Error al crear universidades: $e');
      throw Exception('Error al crear universidades: $e');
    }
  }

  // Inicializa todas las universidades en Firestore desde el JSON
  Future<void> inicializarUniversidades() async {
    try {
      // Verificar si ya existen universidades para evitar duplicados
      final snapshot = await _firestore.collection('universidades').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        developer.log('Las universidades ya están inicializadas');
        return;
      }

      // Cargar todas las universidades desde el JSON
      final universidades = await _universidadService.getUniversidades();
      developer.log('Inicializando ${universidades.length} universidades en Firestore...');

      // Crear las universidades en lotes para no sobrecargar Firestore
      const batchSize = 500;
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
        developer.log('Inicializadas universidades ${i + 1} a $end');
        
        // Pausa entre lotes para no sobrecargar Firestore
        if (end < universidades.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      developer.log('Universidades inicializadas correctamente');
    } catch (e) {
      developer.log('Error al inicializar universidades: $e');
      throw Exception('Error al inicializar universidades: $e');
    }
  }

  // Borra todas las reseñas y reinicia los ratings de las universidades
  Future<void> borrarTodasLasReviews() async {
    try {
      // 1. Obtener todas las reseñas
      final reviewsSnapshot = await _firestore.collection('reviews').get();
      
      // 2. Borrar todas las reseñas en un lote
      final batch = _firestore.batch();
      for (var doc in reviewsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      // 3. Reiniciar los ratings y número de reseñas de todas las universidades
      final universidadesSnapshot = await _firestore.collection('universidades').get();
      final batchUniversidades = _firestore.batch();
      
      for (var doc in universidadesSnapshot.docs) {
        batchUniversidades.update(doc.reference, {
          'rating': 0.0,
          'numReviews': 0,
        });
      }
      await batchUniversidades.commit();
      
      developer.log('Todas las reviews han sido borradas y los ratings reiniciados');
    } catch (e) {
      developer.log('Error al borrar las reviews: $e');
      throw Exception('Error al borrar las reviews: $e');
    }
  }
} 