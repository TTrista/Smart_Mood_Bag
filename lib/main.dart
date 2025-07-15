import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'home_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showHome = false;
  Locale? _locale;

  void _onSplashEnd() {
    setState(() {
      _showHome = true;
    });
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Heart Health',
      theme: AppTheme.themeData,
      locale: _locale,
      supportedLocales: const [Locale('en'), Locale('zh')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: GradientBackground(
        child:
            _showHome
                ? HomePage(onLocaleChange: setLocale)
                : SplashScreen(onAnimationEnd: _onSplashEnd),
      ),
    );
  }
}

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.mainBackground),
      child: child,
    );
  }
}
