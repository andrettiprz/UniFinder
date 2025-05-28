import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String userName;
  final String universidadId;
  final String universidadNombre;
  final double rating;
  final String comentario;
  final DateTime fecha;

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