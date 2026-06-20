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

  @override
  State<JamiaApp> createState() => _JamiaAppState();
}

class _JamiaAppState extends State<JamiaApp> {
  Locale _locale = const Locale('ar');

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_locale);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: strings.appName,
      locale: _locale,
      navigatorObservers: widget.enableTelemetry
          ? [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)]
          : const [],
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'sans-serif',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F55C7),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FC),
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'sans-serif',
          bodyColor: const Color(0xFF111827),
          displayColor: const Color(0xFF111827),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFFF5F7FC),
          foregroundColor: Color(0xFF111827),
          titleTextStyle: TextStyle(
            fontFamily: 'sans-serif',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF9AAEF0), width: 1.4),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          iconColor: Color(0xFF2F55C7),
          titleTextStyle: TextStyle(
            fontFamily: 'sans-serif',
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
          ),
          subtitleTextStyle: TextStyle(
            fontFamily: 'sans-serif',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF7D8AA2),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDE5F6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2F55C7), width: 1.6),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 50),
            side: const BorderSide(color: Color(0xFF9AAEF0), width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFEFF3FF),
          labelStyle: const TextStyle(
            color: Color(0xFF2F55C7),
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      home: Directionality(
        textDirection: strings.textDirection,
        child: widget.useAuthGate
            ? const AuthGate()
            : const HomeShell(enableLiveData: false),
      ),
    );
  }
}
