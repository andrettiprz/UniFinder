// Modelo que representa una universidad con sus datos y métodos relacionados
class Universidad {
  // Datos básicos de la universidad
  final String nombre;
  final List<String> carreras;
  final Map<String, String> contacto;
  final Map<String, String> direccion;
  double rating;
  int numReviews;

  // Constructor que requiere los datos básicos y permite rating y numReviews opcionales
  Universidad({
    required this.nombre,
    required this.carreras,
    required this.contacto,
    required this.direccion,
    this.rating = 0.0,
    this.numReviews = 0,
  });

  // Constructor de fábrica para crear una instancia desde un mapa JSON
  factory Universidad.fromJson(Map<String, dynamic> json) {
    return Universidad(
      nombre: json['nombre'] as String? ?? '',
      carreras: (json['carreras'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      contacto: Map<String, String>.from(
        (json['contacto'] as Map<dynamic, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
        ),
      ),
      direccion: Map<String, String>.from(
        (json['direccion'] as Map<dynamic, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
        ),
      ),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      numReviews: (json['numReviews'] as num?)?.toInt() ?? 0,
    );
  }

  // Convierte la instancia a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'carreras': carreras.isEmpty ? [] : carreras,
      'contacto': contacto.isEmpty ? {} : contacto,
      'direccion': direccion.isEmpty ? {} : direccion,
      'rating': rating,
      'numReviews': numReviews,
    };
  }

  // Getter que retorna el número total de carreras
  int get numeroCarreras => carreras.length;

  // Getters para acceder fácilmente al estado y municipio
  String get estado => direccion['estado'] ?? '';
  String get municipio => direccion['municipio'] ?? '';

  // Obtiene una lista ordenada de estados únicos de un conjunto de universidades
  static List<String> getEstadosUnicos(List<Universidad> universidades) {
    final estados = universidades
        .map((u) => u.estado)
        .where((estado) => estado.isNotEmpty)
        .toSet()
        .toList();
    estados.sort();
    return estados;
  }

  // Obtiene una lista ordenada de municipios para un estado específico
  static List<String> getMunicipiosPorEstado(
    List<Universidad> universidades,
    String estado,
  ) {
    final municipios = universidades
        .where((u) => u.estado == estado)
        .map((u) => u.municipio)
        .where((municipio) => municipio.isNotEmpty)
        .toSet()
        .toList();
    municipios.sort();
    return municipios;
  }

  // Obtiene una lista ordenada de todas las carreras únicas de un conjunto de universidades
  static List<String> getCarrerasUnicas(List<Universidad> universidades) {
    final carreras = universidades
        .expand((u) => u.carreras)
        .toSet()
        .toList();
    carreras.sort();
    return carreras;
  }

  // Verifica si la universidad cumple con los filtros especificados
  bool matchesFilters({
    String? estado,
    String? municipio,
    String? carrera,
  }) {
    if (estado != null && this.estado != estado) {
      return false;
    }
    if (municipio != null && this.municipio != municipio) {
      return false;
    }
    if (carrera != null) {
      // Dividir la búsqueda en palabras clave
      final keywords = carrera.toLowerCase().split(' ')
        .where((word) => word.length > 2) // Ignorar palabras muy cortas
        .toList();
      
      // Buscar coincidencias en cualquier carrera de la universidad
      return carreras.any((carreraUniv) {
        final carreraLower = carreraUniv.toLowerCase();
        // Verificar si todas las palabras clave están presentes
        return keywords.every((keyword) => carreraLower.contains(keyword));
      });
    }
    return true;
  }

  // Verifica si la universidad coincide con un término de búsqueda general
  bool matchesSearch(String query) {
    final searchQuery = query.toLowerCase();
    
    // Buscar en el nombre
    if (nombre.toLowerCase().contains(searchQuery)) {
      return true;
    }

    // Buscar en estado y municipio
    if (estado.toLowerCase().contains(searchQuery) ||
        municipio.toLowerCase().contains(searchQuery)) {
      return true;
    }

    // Buscar en carreras
    return carreras.any((carrera) => 
      carrera.toLowerCase().contains(searchQuery)
    );
  }

  // Método estático para buscar carreras usando un sistema de palabras clave y variantes
  static List<String> buscarCarreras(List<String> carreras, String query) {
    if (query.isEmpty) return carreras.take(20).toList();

    // Limpiar y normalizar la búsqueda
    final searchQuery = query.toLowerCase().trim();
    if (searchQuery.isEmpty || searchQuery.contains('?')) {
      return carreras.take(20).toList();
    }

    // Separar la búsqueda en palabras clave
    final keywords = searchQuery.split(' ')
      .where((word) => word.length > 2)
      .toList();

    // Mapeo de términos comunes a sus variantes para mejorar la búsqueda
    final Map<String, List<String>> variantes = {
      'ing': ['ingenieria', 'ingeniero', 'ingeniería'],
      'lic': ['licenciatura', 'licenciado'],
      'admin': ['administración', 'administracion'],
      'info': ['informática', 'informatica'],
      'soft': ['software'],
      'comp': ['computación', 'computacion', 'computadora', 'computadoras'],
      'sist': ['sistemas', 'sistema'],
      'tec': ['tecnología', 'tecnologia', 'tecnologías', 'tecnologias'],
      'des': ['desarrollo', 'diseño', 'diseno'],
    };

    // Expandir las palabras clave con sus variantes
    final expandedKeywords = keywords.expand((keyword) {
      final variants = variantes.entries
          .where((entry) => keyword.startsWith(entry.key))
          .expand((entry) => entry.value)
          .toList();
      return variants.isEmpty ? [keyword] : variants;
    }).toList();

    // Función para calcular la relevancia de una carrera en base a las coincidencias
    int calcularRelevancia(String carrera) {
      final carreraLower = carrera.toLowerCase();
      int relevancia = 0;
      
      // Dar más peso a coincidencias exactas
      if (carreraLower.contains(searchQuery)) {
        relevancia += 100;
      }

      // Contar coincidencias de palabras clave y variantes
      for (final keyword in expandedKeywords) {
        if (carreraLower.contains(keyword)) {
          relevancia += 10;
        }
      }

      return relevancia;
    }

    // Filtrar carreras que contengan al menos una palabra clave o variante
    final carrerasFiltradas = carreras.where((carrera) {
      final carreraLower = carrera.toLowerCase();
      return expandedKeywords.any((keyword) => carreraLower.contains(keyword));
    }).toList();

    // Ordenar por relevancia y limitar a 20 resultados
    carrerasFiltradas.sort((a, b) => 
      calcularRelevancia(b).compareTo(calcularRelevancia(a))
    );

    return carrerasFiltradas.take(20).toList();
  }

  // Verifica si la universidad ofrece una carrera específica
  bool tieneCarrera(String busqueda) {
    if (busqueda.isEmpty) return true;
    
    final searchLower = busqueda.toLowerCase().trim();
    if (searchLower.isEmpty || searchLower.contains('?')) return false;
    
    return carreras.any((carrera) => 
      carrera.toLowerCase().contains(searchLower));
  }
} 