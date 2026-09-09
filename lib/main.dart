import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n.dart';
import 'features/auth/session_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/portal/presentation/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CustomerApp()));
}

class CustomerApp extends ConsumerStatefulWidget {
  const CustomerApp({super.key});
  @override
  ConsumerState<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends ConsumerState<CustomerApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(sessionProvider.notifier).restore());
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final session = ref.watch(sessionProvider);
    return MaterialApp(
      title: 'My Internet',
      debugShowCheckedModeBanner: false,
      locale: Locale(language),
      supportedLocales: const [Locale('en'), Locale('fa'), Locale('ps')],
      localizationsDelegates: const [
        PashtoMaterialDelegate(),
        PashtoCupertinoDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: language == 'en' ? TextDirection.ltr : TextDirection.rtl,
        child: child!,
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff087f86),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff4f7f8),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
      home: !session.ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : session.signedIn
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}

// Flutter does not ship Pashto Material strings. Persian fallback covers system
// controls; all app-owned copy is explicitly translated into Pashto.
class PashtoMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const PashtoMaterialDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ps';
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('fa'));
  @override
  bool shouldReload(PashtoMaterialDelegate old) => false;
}

class PashtoCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const PashtoCupertinoDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ps';
  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('fa'));
  @override
  bool shouldReload(PashtoCupertinoDelegate old) => false;
}
