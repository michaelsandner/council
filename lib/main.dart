import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/council_app.dart';
import 'features/meetings/data/datasources/council_data_source.dart';
import 'features/meetings/data/repositories/meeting_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE');

  runApp(
    CouncilApp(
      repository: MeetingRepositoryImpl(dataSource: CouncilDataSource()),
    ),
  );
}
