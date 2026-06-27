import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_strings.dart';
import 'core/services/firebase_bootstrap.dart';
import 'features/auth/auth_gate.dart';
import 'features/home/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();

  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  runApp(const JamiaApp());
}

class JamiaApp extends StatefulWidget {
  const JamiaApp({
    super.key,
    this.useAuthGate = true,
    this.enableTelemetry = true,
  });

  final bool useAuthGate;
  final bool enableTelemetry;

  static const appName = '\u062c\u0645\u0639\u064a\u0629';

  static void setLocale(BuildContext context, Locale locale) {
    context.findAncestorStateOfType<_JamiaAppState>()?.setLocale(locale);
  }

  static void toggleTheme(BuildContext context) {
    context.findAncestorStateOfType<_JamiaAppState>()?.toggleTheme();
  }

  @override
  State<JamiaApp> createState() => _JamiaAppState();
}

class _JamiaAppState extends State<JamiaApp> {
  Locale _locale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.light;

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_locale);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: strings.appName,
      locale: _locale,
      themeMode: _themeMode,
      navigatorObservers: widget.enableTelemetry
          ? [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)]
          : const [],
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: Directionality(
        textDirection: strings.textDirection,
        child: widget.useAuthGate
            ? const AuthGate()
            : const HomeShell(enableLiveData: false),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2F55C7),
      brightness: brightness,
    );
    final surface = isDark ? const Color(0xFF101827) : const Color(0xFFF5F7FC);
    final cardColor = isDark ? const Color(0xFF172033) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF3B4A70)
        : const Color(0xFF9AAEF0);
    final textColor = isDark
        ? const Color(0xFFF3F6FF)
        : const Color(0xFF111827);
    final mutedTextColor = isDark
        ? const Color(0xFF9BA8C4)
        : const Color(0xFF4F5C7D);

    // نص الأزرار - قوي وسميك جداً
    const buttonTextStyle = TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: 16,
      letterSpacing: 0.5,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'sans-serif',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      textTheme: (isDark ? ThemeData.dark() : ThemeData.light()).textTheme
          .apply(
            fontFamily: 'sans-serif',
            bodyColor: textColor,
            displayColor: textColor,
          )
          .copyWith(
            displayLarge: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
            displayMedium: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
            displaySmall: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
            headlineLarge: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
            headlineMedium: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
            headlineSmall: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
            titleLarge: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
            titleMedium: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
            titleSmall: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
            bodyLarge: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            bodyMedium: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            bodySmall: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: mutedTextColor,
            ),
            labelLarge: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
            labelMedium: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
            labelSmall: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: mutedTextColor,
            ),
          ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: textColor,
        titleTextStyle: TextStyle(
          fontFamily: 'sans-serif',
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor, width: 1.4),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        iconColor: colorScheme.primary,
        titleTextStyle: TextStyle(
          fontFamily: 'sans-serif',
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'sans-serif',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: mutedTextColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF354361) : const Color(0xFFDDE5F6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: mutedTextColor,
        ),
        hintStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: mutedTextColor,
        ),
      ),
      // ⭐ تحسين الأزرار الممتلئة (FilledButton)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: buttonTextStyle,
        ),
      ),
      // ⭐ تحسين الأزرار المخطط (OutlinedButton)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          side: BorderSide(color: borderColor, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: buttonTextStyle,
        ),
      ),
      // ⭐ تحسين الأزرار النصية (TextButton)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: buttonTextStyle,
        ),
      ),
      // ⭐ تحسين الزر العائم (FloatingActionButton)
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        sizeConstraints: const BoxConstraints.tightFor(width: 56, height: 56),
        elevation: 8,
        highlightElevation: 12,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? const Color(0xFF233052)
            : const Color(0xFFEFF3FF),
        labelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    );
  }
}
