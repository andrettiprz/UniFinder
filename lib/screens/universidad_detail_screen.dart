import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/universidad.dart';
import '../providers/favorites_provider.dart';
import '../widgets/reviews_section.dart';

class UniversidadDetailScreen extends StatelessWidget {
  final Universidad universidad;

  const UniversidadDetailScreen({
    super.key,
    required this.universidad,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(universidad.nombre),
        actions: [
          _FavoriteButton(universidad: universidad),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Información de Contacto',
              [
                if (universidad.contacto['telefono']?.isNotEmpty ?? false)
                  _buildInfoRow(Icons.phone, 'Teléfono', universidad.contacto['telefono']!),
                if (universidad.contacto['email']?.isNotEmpty ?? false)
                  _buildInfoRow(Icons.email, 'Email', universidad.contacto['email']!),
                if (universidad.contacto['web']?.isNotEmpty ?? false)
                  _buildInfoRow(Icons.web, 'Sitio Web', universidad.contacto['web']!),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Dirección',
              [
                _buildInfoRow(Icons.location_on, 'Calle', universidad.direccion['calle'] ?? ''),
                _buildInfoRow(Icons.location_city, 'Colonia', universidad.direccion['colonia'] ?? ''),
                _buildInfoRow(Icons.map, 'CP', universidad.direccion['cp'] ?? ''),
                _buildInfoRow(Icons.place, 'Estado', universidad.direccion['estado'] ?? ''),
                _buildInfoRow(Icons.location_city, 'Municipio', universidad.direccion['municipio'] ?? ''),
              ],
            ),
            const SizedBox(height: 24),
            ReviewsSection(
              universidadId: universidad.nombre,
              universidadNombre: universidad.nombre,
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Carreras Disponibles (${universidad.numeroCarreras})',
              universidad.carreras.map((carrera) => 
                _buildInfoRow(Icons.school, '', carrera)
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label.isNotEmpty) ...[
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final Universidad universidad;

  const _FavoriteButton({
    required this.universidad,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        return FutureBuilder<bool>(
          future: favoritesProvider.isFavorite(universidad.nombre),
          builder: (context, snapshot) {
            final isFavorite = snapshot.data ?? false;
            
            return IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
              onPressed: favoritesProvider.isLoading
                  ? null
                  : () async {
                      final isNowFavorite = await favoritesProvider.toggleFavorite(universidad);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isNowFavorite
                                  ? 'Agregado a favoritos'
                                  : 'Eliminado de favoritos',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
            );
          },
        );
      },
    );
  }
} 