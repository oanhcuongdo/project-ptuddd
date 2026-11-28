import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/firebase_auth_data_source.dart';
import '../models/app_user_mapper.dart';

/// Hiện thực [AuthRepository] bằng Firebase Authentication.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final FirebaseAuthDataSource _dataSource;

  @override
  Stream<AppUser?> authStateChanges() =>
      _dataSource.authStateChanges().map(mapUserOrNull);

  @override
  AppUser? get currentUser => mapUserOrNull(_dataSource.currentUser);

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final user = await _dataSource.signIn(email: email, password: password);
    return user.toAppUser();
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final user = await _dataSource.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
    return user.toAppUser();
  }

  @override
  Future<void> signOut() => _dataSource.signOut();
}
