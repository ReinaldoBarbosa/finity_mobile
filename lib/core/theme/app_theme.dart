import 'package:flutter/material.dart';

class AppTheme {
  // ============================================
  // CORES PRINCIPAIS DO FINITY
  // ============================================

  static const Color primaryColor = Color(0xFF4930C8);
  static const Color backgroundColor = Color(0xFFF7F6FC);

  // ============================================
  // CORES DE TEXTO
  // ============================================

  static const Color textColor = Color(0xFF252238);
  static const Color secondaryTextColor = Color(0xFF777487);

  // ============================================
  // CORES DE COMPONENTES
  // ============================================

  static const Color cardColor = Colors.white;
  static const Color borderColor = Color(0xFFE5E1EF);

  // ============================================
  // CORES DE STATUS FINANCEIRO
  // ============================================

  static const Color successColor = Color(0xFF219653);
  static const Color errorColor = Color(0xFFEB5757);
  static const Color warningColor = Color(0xFFE6A23C);
  static const Color infoColor = Color(0xFF2D9CDB);
  static const Color cancelledColor = Color(0xFF777487);

  // ============================================
  // TEMA CLARO DO APLICATIVO
  // ============================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Cores gerais.
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),

      // Barra superior.
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 21,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Cartões.
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: borderColor,
          ),
        ),
      ),

      // Campos de texto.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        hintStyle: const TextStyle(
          color: secondaryTextColor,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
      ),

      // Botões principais.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Botões de contorno.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(
            color: primaryColor,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Botões de texto.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Botão flutuante.
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),

      // Indicadores de carregamento.
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),

      // Divisórias.
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      // Chips e filtros.
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: primaryColor,
        secondarySelectedColor: primaryColor,
        disabledColor: const Color(0xFFF1F0F6),
        labelStyle: const TextStyle(
          color: textColor,
          fontSize: 13,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: borderColor,
          ),
        ),
      ),

      // Barras de notificação.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textColor,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
