import 'package:get_it/get_it.dart';
import 'core/services/audio_service.dart';
import 'core/services/storage_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Services
  sl.registerLazySingleton<AudioService>(() => AudioService());
  sl.registerLazySingleton<StorageService>(() => StorageService());
}
