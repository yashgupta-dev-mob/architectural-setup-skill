import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/login_screen.dart';
import 'screens/notes_screen.dart';

void main() {
  runApp(const FieldNotesApp());
}

class FieldNotesApp extends StatelessWidget {
  const FieldNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) => NotesProvider(
            onUnauthorized: () =>
                context.read<AuthProvider>().handleUnauthorized(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer2<SettingsProvider, AuthProvider>(
        builder: (context, settings, auth, _) {
          return MaterialApp(
            title: 'Field notes',
            theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
            darkTheme: ThemeData.dark(),
            themeMode: settings.isDark ? ThemeMode.dark : ThemeMode.light,
            home: auth.isLoggedIn ? const NotesScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
