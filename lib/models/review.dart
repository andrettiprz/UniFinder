import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo que representa una reseña de una universidad
class Review {
  // Identificador único de la reseña
  final String id;
  // Identificador del usuario que hizo la reseña
  final String userId;
  // Nombre del usuario que hizo la reseña
  final String userName;
  // Identificador de la universidad reseñada
  final String universidadId;
  // Nombre de la universidad reseñada
  final String universidadNombre;
  // Calificación dada por el usuario (0-5)
  final double rating;
  // Comentario textual de la reseña
  final String comentario;
  // Fecha en que se creó la reseña
  final DateTime fecha;

  // Constructor que requiere todos los campos
  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.universidadId,
    required this.universidadNombre,
    required this.rating,
    required this.comentario,
    required this.fecha,
  });

  // Constructor de fábrica para crear una instancia desde un mapa JSON
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      universidadId: json['universidadId'] as String,
      universidadNombre: json['universidadNombre'] as String,
      rating: (json['rating'] as num).toDouble(),
      comentario: json['comentario'] as String,
      fecha: (json['fecha'] as Timestamp).toDate(),
    );
  }

  // Convierte la instancia a un mapa JSON para almacenamiento en Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'universidadId': universidadId,
      'universidadNombre': universidadNombre,
      'rating': rating,
      'comentario': comentario,
      'fecha': Timestamp.fromDate(fecha),
    };
  }

  // Crea una nueva instancia con algunos campos actualizados
  // Útil para modificar una reseña existente sin cambiar todos sus campos
  Review copyWith({
    String? id,
    String? userId,
    String? userName,
    String? universidadId,
    String? universidadNombre,
    double? rating,
    String? comentario,
    DateTime? fecha,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      universidadId: universidadId ?? this.universidadId,
      universidadNombre: universidadNombre ?? this.universidadNombre,
      rating: rating ?? this.rating,
      comentario: comentario ?? this.comentario,
      fecha: fecha ?? this.fecha,
    );
  }
} 