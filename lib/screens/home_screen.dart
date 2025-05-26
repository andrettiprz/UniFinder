import 'package:flutter/material.dart';
import '../models/universidad.dart';
import '../services/universidad_service.dart';
import 'universidad_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UniversidadService _service = UniversidadService();
  List<Universidad> _universidades = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUniversidades();
  }

  Future<void> _loadUniversidades() async {
    try {
      final universidades = await _service.getUniversidades();
      setState(() {
        _universidades = universidades;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Universidades Recomendadas'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUniversidades,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _universidades.length,
          itemBuilder: (context, index) {
            final universidad = _universidades[index];
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
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${universidad.numeroCarreras} carreras disponibles',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                onTap: () => _navigateToDetail(universidad),
              ),
            );
          },
        ),
      ),
    );
  }
} 