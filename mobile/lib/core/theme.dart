import 'package:flutter/material.dart';

const _seed = Color(0xFF7C3AED);

final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light),
  scaffoldBackgroundColor: const Color(0xFFF8FAFC), // slate-50
  appBarTheme: const AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.2),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: _seed.withOpacity(0.5), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    elevation: 0,
    color: Colors.white,
  ),
  navigationBarTheme: NavigationBarThemeData(
    elevation: 0,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    indicatorColor: _seed.withOpacity(0.1),
    indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED));
      }
      return const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8));
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(size: 24, color: Color(0xFF7C3AED));
      }
      return const IconThemeData(size: 22, color: Color(0xFF94A3B8));
    }),
  ),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 0,
  ),
);
