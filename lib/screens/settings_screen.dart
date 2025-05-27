import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Perfil'),
            onTap: () {
              // TODO: Implementar pantalla de perfil
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notificaciones'),
            onTap: () {
              // TODO: Implementar configuración de notificaciones
            },
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Privacidad y Seguridad'),
            onTap: () {
              // TODO: Implementar configuración de privacidad
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', 
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
} 