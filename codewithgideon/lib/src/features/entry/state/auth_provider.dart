import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show FutureProvider, Provider, Ref;
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
export '../data/auth_repository.dart' show EnrollmentStatus;

enum AuthStatus { booting, unauthenticated, authenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.session,
    this.errorMessage,
    this.isLoading = false,
  });

  final AuthStatus status;
  final AuthSession? session;
  final String? errorMessage;
  final bool isLoading;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  EnrollmentStatus get enrollmentStatus =>
      session?.enrollmentStatus ?? EnrollmentStatus.notRegistered;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    String? errorMessage,
    bool? isLoading,
    bool clearSession = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: clearSession ? null : session ?? this.session,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final apiClientProvider = Provider<ApiClient>((ref) => const ApiClient());

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final preferences = await ref.watch(sharedPreferencesProvider.future);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firebaseFirestore = ref.watch(firebaseFirestoreProvider);
  return AuthRepository(
    preferences: preferences,
    firebaseAuth: firebaseAuth,
    firebaseFirestore: firebaseFirestore,
  );
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref)
    : super(const AuthState(status: AuthStatus.booting, isLoading: true)) {
    _bootstrap();
  }

  final Ref _ref;

  Future<AuthRepository> get _repository async =>
      _ref.read(authRepositoryProvider.future);

  Future<void> _bootstrap() async {
    try {
      final repository = await _repository;
      final session = await repository.restoreSession();
      state = AuthState(
        status: session == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
        session: session,
        isLoading: false,
      );
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: 'Could not restore your session.',
      );
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = await _repository;
      final session = await repository.login(email: email, password: password);
      state = AuthState(
        status: AuthStatus.authenticated,
        session: session,
        isLoading: false,
      );
    } catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repository = await _repository;
      final session = await repository.createAccount(
        email: email,
        password: password,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        session: session,
        isLoading: false,
      );
    } catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> completeRegistration(EnrollmentStatus status) async {
    if (state.session == null) return;
    final repository = await _repository;
    final updated = state.session!.copyWith(enrollmentStatus: status);
    await repository.persistSession(updated);
    state = state.copyWith(session: updated);
  }

  Future<void> refreshSession() async {
    final repository = await _repository;
    final session = await repository.restoreSession();
    state = AuthState(
      status: session == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated,
      session: session,
      isLoading: false,
    );
  }

  Future<void> logout() async {
    final repository = await _repository;
    await repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> markOnboardingSeen() async {
    final repository = await _repository;
    await repository.markOnboardingSeen();
    _ref.invalidate(hasSeenOnboardingProvider);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref);
  },
);

final hasSeenOnboardingProvider = FutureProvider<bool>((ref) async {
  final repository = await ref.watch(authRepositoryProvider.future);
  return repository.hasSeenOnboarding();
});
