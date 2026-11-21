import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/data/firebase_auth_repository.dart';
import '../firebase_options.dart';
import 'backend_config.dart';

Future<FirebaseAuthRepository> initializeBackend() async {
  final firebase = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final auth = FirebaseAuthRepository(FirebaseAuth.instanceFor(app: firebase));

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
    accessToken: auth.accessToken,
    debug: false,
  );
  return auth;
}
