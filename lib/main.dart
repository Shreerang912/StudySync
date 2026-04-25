import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'supabase_config.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

final themeNotifier = ValueNotifier(ThemeMode.light);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   HttpOverrides.global = MyHttpOverrides();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const MyApp());
}
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: ValueListenableBuilder(
        valueListenable: themeNotifier,
        builder: (_, mode, __) => MaterialApp(
          title: 'StudySync',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(253, 59, 118, 228)),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromARGB(253, 59, 118, 228),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(253, 59, 118, 228),
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromARGB(253, 59, 118, 228),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFF1E1E2E),
            ),
          ),
          themeMode: mode,
          home: const AuthWrapper(),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color.fromARGB(253, 59, 118, 228)),
            ),
          );
        }
        final session = snapshot.data?.session;
        if (session != null) {
          return HomeScreen();
        }
        return LoginScreen();
      },
    );
  }
}