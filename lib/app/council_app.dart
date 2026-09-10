import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/meetings/domain/repositories/meeting_repository.dart';
import 'router.dart';
import 'theme.dart';

class CouncilApp extends StatefulWidget {
  const CouncilApp({required this.repository, super.key});

  final MeetingRepository repository;

  @override
  State<CouncilApp> createState() => _CouncilAppState();
}

class _CouncilAppState extends State<CouncilApp> {
  late final GoRouter _router = buildRouter(widget.repository);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Stadtrat Langenzenn',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routerConfig: _router,
    );
  }
}
