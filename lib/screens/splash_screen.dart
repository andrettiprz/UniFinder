import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    _controller.forward().then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
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
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.6; // 60% del ancho de la pantalla

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
                    // Logo grande
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
                    // Texto UniFinder
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
                    // Texto descriptivo
                    Text(
                      'Encuentra tu universidad ideal',
                      style: TextStyle(
                        color: AppTheme.textColor.withOpacity(0.7),
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
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