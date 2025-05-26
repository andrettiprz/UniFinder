class Universidad {
  final String nombre;
  final List<String> carreras;
  final Map<String, String> contacto;
  final Map<String, String> direccion;

  Universidad({
    required this.nombre,
    required this.carreras,
    required this.contacto,
    required this.direccion,
  });

  factory Universidad.fromJson(Map<String, dynamic> json) {
    return Universidad(
      nombre: json['nombre'] as String,
      carreras: List<String>.from(json['carreras']),
      contacto: Map<String, String>.from(json['contacto'].map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      )),
      direccion: Map<String, String>.from(json['direccion'].map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      )),
    );
  }

  int get numeroCarreras => carreras.length;
} 