import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de colores principal de la aplicación
  static const Color primary = Color(0xFF0057B7);    // Azul principal
  static const Color secondary = Color(0xFFFFFFFF);  // Blanco
  static const Color accent = Color(0xFF00C897);     // Verde acento
  static const Color textColor = Color(0xFF333333);  // Gris oscuro para texto
  static const Color surfaceColor = Color(0xFFF5F5F5); // Gris claro para fondos

  // Configuración del tema claro de la aplicación
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    // Esquema de colores para el tema claro
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: surfaceColor,
      onSurface: textColor,
      onPrimary: secondary,
      onSecondary: textColor,
      onBackground: textColor,
    ),
    
    // Configuración de la barra superior (AppBar)
    appBarTheme: const AppBarTheme(
      backgroundColor: secondary,
      foregroundColor: textColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Configuración de las tarjetas (Cards)
    cardTheme: CardThemeData(
      color: secondary,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Configuración de los campos de entrada (TextFields)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: secondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary.withValues(alpha: 128), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      labelStyle: const TextStyle(color: textColor),
      floatingLabelStyle: const TextStyle(color: primary),
    ),

    // Configuración de los botones elevados (ElevatedButtons)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: secondary,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Configuración de la barra de navegación inferior
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: secondary,
      selectedItemColor: primary,
      unselectedItemColor: Color(0xFF999999),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
      ),
    ),

    // Configuración de los elementos de lista (ListTiles)
    listTileTheme: const ListTileThemeData(
      iconColor: primary,
      textColor: textColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    // Configuración de los estilos de texto
    textTheme: const TextTheme(
      headlineLarge: TextStyle(  // Títulos muy grandes
        color: textColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle( // Títulos grandes
        color: textColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(     // Títulos medianos
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(      // Texto de cuerpo grande
        color: textColor,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(     // Texto de cuerpo normal
        color: textColor,
        fontSize: 14,
      ),
    ),

    // Color de fondo predeterminado para las pantallas
    scaffoldBackgroundColor: surfaceColor,
  );
} 