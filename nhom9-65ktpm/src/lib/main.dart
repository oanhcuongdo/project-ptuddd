import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/buddytalk_app.dart';
import 'app/router/routes/index.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  registerAllRoutes();
  runApp(const BuddyTalkApp());
}
