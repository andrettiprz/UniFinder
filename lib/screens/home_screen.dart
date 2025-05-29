import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../models/universidad.dart';
import '../services/universidad_service.dart';
import '../services/review_service.dart';
import '../providers/universidad_provider.dart';
import 'universidad_detail_screen.dart';

// Pantalla principal que muestra las universidades recomendadas
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Servicios para obtener datos de universidades y reseñas
  final UniversidadService _service = UniversidadService();
  final ReviewService _reviewService = ReviewService();

  // Método para cargar las universidades recomendadas basadas en reseñas
  Future<void> _cargarUniversidadesRecomendadas() async {
    if (!mounted) return;
    
    try {
      // Obtener las universidades con más reviews primero
      final snapshot = await _reviewService.getUniversidadesConReviews();
      
      if (!mounted) return;

      // Obtener los detalles completos de las universidades
      final todasUniversidades = await _service.getUniversidades();
      
      if (!mounted) return;

      // Crear un mapa para acceso rápido a las universidades por nombre
      final universidadesPorNombre = {
        for (var u in todasUniversidades) u.nombre: u
      };

      // Preparar las estructuras de datos para las universidades recomendadas
      final universidadesRecomendadas = <Universidad>[];
      final ratings = <String, double>{};
      final numReviews = <String, int>{};

      // Procesar los datos de las reseñas y crear la lista de recomendaciones
      for (var doc in snapshot.docs) {
        final universidadId = doc['universidadId'] as String;
        final universidad = universidadesPorNombre[universidadId];
        if (universidad != null) {
          universidadesRecomendadas.add(universidad);
          ratings[universidadId] = (doc['rating'] as num).toDouble();
          numReviews[universidadId] = (doc['numReviews'] as num).toInt();
        }
      }

      // Actualizar el provider con los datos obtenidos
      if (mounted) {
        final provider = Provider.of<UniversidadProvider>(context, listen: false);
        provider.initializeData(
          universidades: universidadesRecomendadas,
          ratings: ratings,
          numReviews: numReviews,
        );
      }

    } catch (e) {
      developer.log('Error al cargar universidades recomendadas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  // Método para manejar la actualización manual (pull-to-refresh)
  Future<void> _onRefresh() async {
    await _cargarUniversidadesRecomendadas();
  }

  // Método para navegar a la pantalla de detalles de una universidad
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
    // Usar Consumer para recibir actualizaciones del UniversidadProvider
    return Consumer<UniversidadProvider>(
      builder: (context, provider, child) {
        final universidades = provider.universidades;
        final ratings = provider.ratings;
        final numReviews = provider.numReviews;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la sección
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Universidades Recomendadas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Lista de universidades
            Expanded(
              child: !provider.isInitialized
                  // Mostrar indicador de carga mientras se inicializan los datos
                  ? const Center(child: CircularProgressIndicator())
                  : universidades.isEmpty
                      // Mostrar mensaje cuando no hay universidades con reseñas
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
                                onPressed: _onRefresh,
                                child: const Text('Actualizar'),
                              ),
                            ],
                          ),
                        )
                      // Mostrar lista de universidades con reseñas
                      : RefreshIndicator(
                          onRefresh: _onRefresh,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: universidades.length,
                            itemBuilder: (context, index) {
                              final universidad = universidades[index];
                              final rating = ratings[universidad.nombre] ?? 0.0;
                              final reviewCount = numReviews[universidad.nombre] ?? 0;
                              
                              // Tarjeta de universidad con información relevante
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
                                      // Barra de calificación y número de reseñas
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
                                            '${rating.toStringAsFixed(1)} ($reviewCount reseñas)',
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
      },
    );
  }
} 