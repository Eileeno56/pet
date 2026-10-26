import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petreminder_user/core/theme/app_theme.dart';
import 'package:petreminder_user/providers/router_provider.dart';
import 'package:petreminder_user/core/widgets/app_background.dart';

class PetReminderApp extends ConsumerWidget {
  const PetReminderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PetReminder',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      builder: (context, child) =>
          AppBackground(child: child ?? const SizedBox()),
      routerConfig: router,
    );
  }
}
