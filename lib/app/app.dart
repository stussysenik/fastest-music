import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class FastestMusicApp extends StatelessWidget {
  const FastestMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fastest Music',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
