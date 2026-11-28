import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/buddytalk_app.dart';
import 'app/router/routes/index.dart';
import 'core/network/firebase_config.dart';
import 'core/network/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await FirebaseConfig.initialize();
  await SupabaseConfig.initialize();
  registerAllRoutes();
  runApp(const BuddyTalkApp());
}
