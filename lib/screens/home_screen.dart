import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/universidad.dart';
import '../services/universidad_service.dart';
import '../services/review_service.dart';
import 'universidad_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UniversidadService _service = UniversidadService();
  final ReviewService _reviewService = ReviewService();
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Universidad> _universidades = [];
  Map<String, double> _ratings = {};
  Map<String, int> _numReviews = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarUniversidadesRecomendadas();
  }

  Future<void> _cargarUniversidadesRecomendadas() async {
    if (!mounted) return;
    
    try {
      if (!_isRefreshing) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // Obtener las universidades con más reviews primero
      final snapshot = await _reviewService.getUniversidadesConReviews();
      
      if (!mounted) return;

      // Obtener los detalles de las universidades del JSON
      final todasUniversidades = await _service.getUniversidades();
      
      if (!mounted) return;

      // Mapear las universidades por nombre para fácil acceso
      final universidadesPorNombre = {
        for (var u in todasUniversidades) u.nombre: u
      };

      // Crear la lista final de universidades recomendadas
      final universidadesRecomendadas = <Universidad>[];
      final ratings = <String, double>{};
      final numReviews = <String, int>{};

      for (var doc in snapshot.docs) {
        final universidadId = doc['universidadId'] as String;
        final universidad = universidadesPorNombre[universidadId];
        if (universidad != null) {
          universidadesRecomendadas.add(universidad);
          ratings[universidadId] = (doc['rating'] as num).toDouble();
          numReviews[universidadId] = (doc['numReviews'] as num).toInt();
        }
      }

      setState(() {
        _universidades = universidadesRecomendadas;
        _ratings = ratings;
        _numReviews = numReviews;
        _isLoading = false;
        _isRefreshing = false;
      });

    } catch (e) {
      print('Error al cargar universidades recomendadas: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _cargarUniversidadesRecomendadas();
  }

  void _navigateToDetail(Universidad universidad) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UniversidadDetailScreen(universidad: universidad),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Universidades Recomendadas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: _isLoading && !_isRefreshing
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error: $_error',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _cargarUniversidadesRecomendadas,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : _universidades.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.school_outlined,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'No hay universidades con reseñas todavía',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Las universidades aparecerán aquí cuando los usuarios agreguen reseñas',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _cargarUniversidadesRecomendadas,
                                child: const Text('Actualizar'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _onRefresh,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _universidades.length,
                            itemBuilder: (context, index) {
                              final universidad = _universidades[index];
                              final rating = _ratings[universidad.nombre] ?? 0.0;
                              final numReviews = _numReviews[universidad.nombre] ?? 0;
                              
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 16),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Text(
                                    universidad.nombre,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
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
                                      Text(
                                        '${universidad.estado}, ${universidad.municipio}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        '${universidad.numeroCarreras} carreras disponibles',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color:
                                                  Theme.of(context).colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _navigateToDetail(universidad),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
} 