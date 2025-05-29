import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/universidad.dart';
import '../services/universidad_service.dart';
import '../services/review_service.dart';
import 'universidad_detail_screen.dart';

// Pantalla de búsqueda que permite filtrar universidades por varios criterios
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Servicios para obtener datos
  final UniversidadService _service = UniversidadService();
  final ReviewService _reviewService = ReviewService();
  
  // Controladores y nodos de foco para el campo de búsqueda de carreras
  final TextEditingController _carreraController = TextEditingController();
  final FocusNode _carreraFocusNode = FocusNode();
  
  // Listas principales de datos
  List<Universidad> _universidades = [];
  List<Universidad> _resultados = [];
  bool _isLoading = true;
  String? _error;
  bool _showCarrerasList = false;
  Map<String, double> _ratings = {};
  Map<String, int> _numReviews = {};

  // Estados de los filtros seleccionados
  String? _selectedEstado;
  String? _selectedMunicipio;
  String? _selectedCarrera;

  // Listas para las opciones de los filtros
  List<String> _estados = [];
  List<String> _municipios = [];
  List<String> _carreras = [];
  List<String> _carrerasFiltradas = [];

  // Lista de universidades filtradas por estado y municipio
  List<Universidad> _universidadesFiltradas = [];

  @override
  void initState() {
    super.initState();
    _loadUniversidades();
    _carreraFocusNode.addListener(_onCarreraFocusChange);
  }

  @override
  void dispose() {
    _carreraController.dispose();
    _carreraFocusNode.dispose();
    super.dispose();
  }

  // Maneja los cambios de foco en el campo de búsqueda de carreras
  void _onCarreraFocusChange() {
    setState(() {
      _showCarrerasList = _carreraFocusNode.hasFocus;
      if (_showCarrerasList) {
        _updateCarrerasDisponibles();
      }
    });
  }

  // Carga inicial de datos de universidades y sus calificaciones
  Future<void> _loadUniversidades() async {
    try {
      // Cargar universidades y sus ratings en paralelo
      final universidadesFuture = _service.getUniversidades();
      final ratingsFuture = _reviewService.getUniversidadesConReviews();

      final results = await Future.wait([universidadesFuture, ratingsFuture]);
      final universidades = results[0] as List<Universidad>;
      final ratingsSnapshot = results[1] as QuerySnapshot;

      // Procesar los ratings y número de reseñas
      final ratings = <String, double>{};
      final numReviews = <String, int>{};
      for (var doc in ratingsSnapshot.docs) {
        final universidadId = doc['universidadId'] as String;
        ratings[universidadId] = (doc['rating'] as num).toDouble();
        numReviews[universidadId] = (doc['numReviews'] as num).toInt();
      }

      setState(() {
        _universidades = universidades;
        _resultados = List.from(universidades);
        _universidadesFiltradas = universidades;
        _ratings = ratings;
        _numReviews = numReviews;
        _isLoading = false;
        
        // Inicializar las listas de filtros
        _estados = Universidad.getEstadosUnicos(universidades);
        _carreras = Universidad.getCarrerasUnicas(universidades);
        _carrerasFiltradas = _carreras.take(20).toList();

        // Ordenar resultados por calificación
        _ordenarPorRating();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Ordena las universidades por su calificación promedio
  void _ordenarPorRating() {
    _resultados.sort((a, b) {
      final ratingA = _ratings[a.nombre] ?? 0.0;
      final ratingB = _ratings[b.nombre] ?? 0.0;
      return ratingB.compareTo(ratingA);
    });
  }

  // Actualiza la lista de municipios cuando se selecciona un estado
  void _updateMunicipios() {
    if (_selectedEstado != null) {
      setState(() {
        _municipios = Universidad.getMunicipiosPorEstado(_universidades, _selectedEstado!);
        _selectedMunicipio = null;
        _updateUniversidadesFiltradas();
      });
    } else {
      setState(() {
        _municipios = [];
        _selectedMunicipio = null;
        _updateUniversidadesFiltradas();
      });
    }
  }

  // Actualiza la lista de universidades según los filtros de estado y municipio
  void _updateUniversidadesFiltradas() {
    setState(() {
      // Filtrar universidades por estado y municipio
      _universidadesFiltradas = _universidades.where((universidad) {
        if (_selectedEstado != null && universidad.estado != _selectedEstado) {
          return false;
        }
        if (_selectedMunicipio != null && universidad.municipio != _selectedMunicipio) {
          return false;
        }
        return true;
      }).toList();

      // Actualizar resultados y carreras disponibles
      _updateCarrerasDisponibles();
      _applyFilters();
    });
  }

  // Actualiza la lista de carreras disponibles según las universidades filtradas
  void _updateCarrerasDisponibles() {
    // Obtener solo las carreras de las universidades filtradas
    final carrerasDisponibles = Universidad.getCarrerasUnicas(_universidadesFiltradas);
    
    setState(() {
      if (_carreraController.text.isEmpty) {
        _carrerasFiltradas = carrerasDisponibles.take(20).toList();
      } else {
        _carrerasFiltradas = Universidad.buscarCarreras(carrerasDisponibles, _carreraController.text);
      }
      
      // Limpiar la carrera seleccionada si ya no está disponible
      if (_selectedCarrera != null && !carrerasDisponibles.contains(_selectedCarrera)) {
        _selectedCarrera = null;
        _carreraController.clear();
      }
    });
  }

  // Filtra las carreras según el texto de búsqueda
  void _filterCarreras(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _carrerasFiltradas = Universidad.getCarrerasUnicas(_universidadesFiltradas).take(20).toList();
      });
      return;
    }

    setState(() {
      final carrerasDisponibles = Universidad.getCarrerasUnicas(_universidadesFiltradas);
      _carrerasFiltradas = Universidad.buscarCarreras(carrerasDisponibles, query);
      
      // Filtrar universidades que coincidan con la búsqueda
      if (query.trim().isNotEmpty) {
        _resultados = _universidadesFiltradas.where((universidad) {
          return universidad.carreras.any((carrera) =>
            carrera.toLowerCase().contains(query.toLowerCase()));
        }).toList();
        _ordenarPorRating();
      }
    });
  }

  // Selecciona una carrera de la lista de sugerencias
  void _selectCarrera(String carrera) {
    setState(() {
      _selectedCarrera = carrera;
      _carreraController.text = carrera;
      _showCarrerasList = false;
      _applyFilters();
    });
    _carreraFocusNode.unfocus();
  }

  // Aplica todos los filtros seleccionados
  void _applyFilters() {
    setState(() {
      // Comenzar con todas las universidades
      List<Universidad> filtradas = _universidades;
      
      // Aplicar filtro de estado
      if (_selectedEstado != null) {
        filtradas = filtradas.where((u) => u.estado == _selectedEstado).toList();
      }
      
      // Aplicar filtro de municipio
      if (_selectedMunicipio != null) {
        filtradas = filtradas.where((u) => u.municipio == _selectedMunicipio).toList();
      }
      
      // Aplicar filtro de carrera
      if (_selectedCarrera != null) {
        filtradas = filtradas.where((u) => 
          u.carreras.contains(_selectedCarrera)
        ).toList();
      } else if (_carreraController.text.trim().isNotEmpty) {
        final busqueda = _carreraController.text.toLowerCase();
        filtradas = filtradas.where((u) => 
          u.carreras.any((carrera) => 
            carrera.toLowerCase().contains(busqueda))
        ).toList();
      }
      
      // Actualizar las listas filtradas
      _universidadesFiltradas = filtradas;
      _resultados = filtradas;
      
      // Ordenar por calificación
      _ordenarPorRating();
    });
  }

  // Reinicia todos los filtros a su estado inicial
  void _resetFilters() {
    setState(() {
      _selectedEstado = null;
      _selectedMunicipio = null;
      _selectedCarrera = null;
      _carreraController.clear();
      _municipios = [];
      _universidadesFiltradas = _universidades;
      _carrerasFiltradas = Universidad.getCarrerasUnicas(_universidades).take(20).toList();
      _resultados = List.from(_universidades);
      _showCarrerasList = false;
      _ordenarPorRating();
    });
    _carreraFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar indicador de carga mientras se cargan los datos
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Mostrar mensaje de error si ocurrió algún problema
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Universidades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetFilters,
            tooltip: 'Resetear filtros',
          ),
        ],
      ),
      body: Column(
        children: [
          // Sección de filtros
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtros de búsqueda',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  // Filtro de estados
                  DropdownButtonFormField<String>(
                    value: _selectedEstado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos los estados'),
                      ),
                      ..._estados.map(
                        (estado) => DropdownMenuItem(
                          value: estado,
                          child: Text(estado),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedEstado = value;
                        _updateMunicipios();
                        _applyFilters();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Filtro de municipios
                  DropdownButtonFormField<String>(
                    value: _selectedMunicipio,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Municipio',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos los municipios'),
                      ),
                      ..._municipios.map(
                        (municipio) => DropdownMenuItem(
                          value: municipio,
                          child: Text(municipio),
                        ),
                      ),
                    ],
                    onChanged: _selectedEstado == null
                        ? null
                        : (value) {
                            setState(() {
                              _selectedMunicipio = value;
                              _applyFilters();
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  // Campo de búsqueda de carreras con autocompletado
                  Stack(
                    children: [
                      TextField(
                        controller: _carreraController,
                        focusNode: _carreraFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Buscar carrera',
                          suffixIcon: _carreraController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _carreraController.clear();
                                    setState(() {
                                      _selectedCarrera = null;
                                      _carrerasFiltradas = _carreras.take(20).toList();
                                      _applyFilters();
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          _filterCarreras(value);
                        },
                        onTap: () {
                          setState(() {
                            _showCarrerasList = true;
                            if (_carreraController.text.isEmpty) {
                              _carrerasFiltradas = _carreras.take(20).toList();
                            }
                          });
                        },
                      ),
                      // Lista de sugerencias de carreras
                      if (_showCarrerasList)
                        Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Card(
                            elevation: 8,
                            margin: EdgeInsets.zero,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: _carrerasFiltradas.length,
                                itemBuilder: (context, index) {
                                  final carrera = _carrerasFiltradas[index];
                                  return ListTile(
                                    title: Text(carrera),
                                    onTap: () => _selectCarrera(carrera),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Lista de resultados
          Expanded(
            child: _resultados.isEmpty
                // Mensaje cuando no hay resultados
                ? Center(
                    child: Text(
                      'No se encontraron universidades con los filtros seleccionados',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  )
                // Lista de universidades encontradas
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _resultados.length,
                    itemBuilder: (context, index) {
                      final universidad = _resultados[index];
                      final rating = _ratings[universidad.nombre] ?? 0.0;
                      final numReviews = _numReviews[universidad.nombre] ?? 0;
                      
                      // Tarjeta de universidad con su información
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            universidad.nombre,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              // Calificación y número de reseñas
                              Row(
                                children: [
                                  RatingBarIndicator(
                                    rating: rating,
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    itemCount: 5,
                                    itemSize: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${rating.toStringAsFixed(1)} ($numReviews reseñas)',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Información de ubicación y carreras
                              Text(
                                '${universidad.estado}, ${universidad.municipio}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                '${universidad.numeroCarreras} carreras disponibles',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UniversidadDetailScreen(universidad: universidad),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 