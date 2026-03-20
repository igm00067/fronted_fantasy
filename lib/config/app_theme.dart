import 'package:flutter/material.dart';

class AppTheme {
  // Paleta de colores
  static const Color primaryColor = Color(0xFF38003C);      // Púrpura oscuro
  static const Color secondaryColor = Color(0xFFFFB81C);    // Dorado
  static const Color accentColor = Color(0xFF00D084);       // Verde teal
  static const Color backgroundColor = Color(0xFF0A0A14);   // Negro azulado
  static const Color surfaceColor = Color(0xFF14142A);      // Superficie oscura
  static const Color surfaceVariantColor = Color(0xFF1E1E38); // Variante superficie
  static const Color borderColor = Color(0xFF2E2E50);       // Bordes sutiles
  static const Color textSecondaryColor = Color(0xFF9999BB); // Texto secundario

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: secondaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        error: Color(0xFFCF6679),
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 0.5),
        ),
        shadowColor: Colors.black54,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: secondaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: secondaryColor),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: secondaryColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: secondaryColor,
        unselectedLabelColor: textSecondaryColor,
        indicatorColor: secondaryColor,
        dividerColor: borderColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          elevation: 4,
          shadowColor: Colors.black45,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: secondaryColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariantColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondaryColor),
        hintStyle: const TextStyle(color: textSecondaryColor),
        prefixIconColor: textSecondaryColor,
        suffixIconColor: textSecondaryColor,
        errorStyle: const TextStyle(color: Color(0xFFCF6679)),
      ),
      dividerTheme: const DividerThemeData(color: borderColor, thickness: 0.5),
      iconTheme: const IconThemeData(color: Colors.white70),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Color(0xFFCCCCDD)),
        bodySmall: TextStyle(color: textSecondaryColor),
        labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceVariantColor,
        contentTextStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: const DialogTheme(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(color: Color(0xFFCCCCDD), fontSize: 14),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Colors.white,
        subtitleTextStyle: TextStyle(color: textSecondaryColor),
        iconColor: Colors.white70,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: secondaryColor,
        linearTrackColor: borderColor,
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: surfaceVariantColor,
        labelStyle: TextStyle(color: Colors.white),
        side: BorderSide.none,
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(color: Colors.white),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: surfaceColor,
        textStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  // Mantener lightTheme por compatibilidad
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
