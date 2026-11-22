import 'package:flutter/material.dart';

import 'app/buddytalk_app.dart';
import 'app/router/routes/index.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerAllRoutes();
  runApp(const BuddyTalkApp());
}
