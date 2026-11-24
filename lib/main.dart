import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/storage/app_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The phone's copy of the session, preferences and last answers. Opening it
  // takes a few milliseconds (entries are read on first use), and lets the
  // first frame show the signed-in Home with content instead of a splash
  // followed by skeletons.
  final cache = await AppCache.open();
  // The native launch screen hands over to an in-app splash that looks the
  // same only on the first launch after an update, while the saved sign-in is
  // restored from the server; after that the app opens straight into Home.
  runApp(ProviderScope(
    overrides: [appCacheProvider.overrideWithValue(cache)],
    child: const App(),
  ));
}
