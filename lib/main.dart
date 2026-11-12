import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'domain/models.dart';
import 'presentation/providers.dart';
import 'presentation/screens.dart';

void main() {
  runApp(const ProviderScope(child: TitilarasApp()));
}

class TitilarasApp extends ConsumerWidget {
  const TitilarasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final settings = app.value?.pengaturan ?? Pengaturan.bawaan();
    return MaterialApp(
      title: 'Belajar Titilaras Sunda',
      debugShowCheckedModeBanner: false,
      locale: const Locale('id'),
      supportedLocales: const [Locale('id')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.tema == ModeTema.gelap
          ? ThemeMode.dark
          : ThemeMode.light,
      home: const HomeShell(),
    );
  }
}
