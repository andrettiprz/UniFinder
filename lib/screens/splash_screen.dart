import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import '../services/universidad_service.dart';
import '../services/review_service.dart';
import '../services/initial_data_service.dart';
import '../providers/favorites_provider.dart';
import '../providers/review_provider.dart';
import '../providers/universidad_provider.dart';
import '../models/universidad.dart';

// Pantalla de carga inicial de la aplicación
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Estado de la pantalla de splash que maneja las animaciones y la carga de datos
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // Controlador y animaciones para los efectos visuales
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Configuración del controlador de animación
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animación de fade in
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Animación de escala
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    // Iniciar la carga de datos y las animaciones
    _inicializarDatos();
    _controller.forward();
  }

  // Método para cargar todos los datos necesarios antes de mostrar la aplicación
  Future<void> _inicializarDatos() async {
    try {
      // Inicializar servicios necesarios
      final reviewService = ReviewService();
      final universidadService = UniversidadService();
      final initialDataService = InitialDataService();

      // Asegurar que las universidades existan en Firestore
      await initialDataService.inicializarUniversidades();

      // Cargar datos en paralelo para optimizar el tiempo de carga
      final results = await Future.wait([
        // Cargar lista completa de universidades
        universidadService.getUniversidades(),
        // Cargar solo universidades que tienen reseñas
        reviewService.getUniversidadesConReviews(),
      ]);

      if (mounted) {
        // Procesar resultados de la carga paralela
        final universidades = results[0] as List<Universidad>;
        final ratingsSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;

        // Crear mapas de ratings y número de reseñas
        final ratings = <String, double>{};
        final numReviews = <String, int>{};
        for (var doc in ratingsSnapshot.docs) {
          final universidadId = doc.data()['universidadId'] as String;
          ratings[universidadId] = (doc.data()['rating'] as num).toDouble();
          numReviews[universidadId] = (doc.data()['numReviews'] as num).toInt();
        }

        // Obtener referencias a los providers
        final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
        final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
        final universidadProvider = Provider.of<UniversidadProvider>(context, listen: false);
        
        // Inicializar datos específicos del usuario si está autenticado
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated && authProvider.user != null) {
          favoritesProvider.init();
          await reviewProvider.loadUserReviews(authProvider.user!.uid);
        }

        // Inicializar el provider de universidades con todos los datos
        universidadProvider.initializeData(
          universidades: universidades,
          ratings: ratings,
          numReviews: numReviews,
        );

        // Asegurar que la animación termine
        if (!_controller.isCompleted) {
          await _controller.forward();
        }

        // Pequeña pausa para asegurar la inicialización completa
        await Future.delayed(const Duration(milliseconds: 500));

        // Navegar a la siguiente pantalla
        _navegarSiguientePantalla();
      }
    } catch (e) {
      developer.log('Error al precargar datos: $e');
      // Continuar con la navegación incluso si hay error
      if (mounted) {
        _navegarSiguientePantalla();
      }
    }
  }

  // Método para navegar a la pantalla correspondiente según el estado de autenticación
  void _navegarSiguientePantalla() {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FadeTransition(
              opacity: animation,
              child: authProvider.isAuthenticated 
                  ? const MainNavigationScreen()
                  : const LoginScreen(),
            ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.6;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo de la aplicación
                    SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Título de la aplicación
                    Text(
                      'UniFinder',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Subtítulo descriptivo
                    Text(
                      'Encuentra tu universidad ideal',
                      style: TextStyle(
                        color: AppTheme.textColor.withValues(alpha: 179),
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Indicador de carga circular
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primary.withValues(alpha: 128),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 