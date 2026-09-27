import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EnrollmentStatus { enrolled, pending, notRegistered }

class PendingGoogleLinkException implements Exception {
  const PendingGoogleLinkException({required this.email});

  final String email;
}

class _PendingGoogleLink {
  const _PendingGoogleLink({required this.email, required this.credential});

  final String email;
  final AuthCredential credential;
}

class AuthSession {
  const AuthSession({
    required this.uid,
    required this.email,
    required this.accessToken,
    required this.enrollmentStatus,
    required this.isEmailVerified,
  });

  final String uid;
  final String email;
  final String accessToken;
  final EnrollmentStatus enrollmentStatus;
  final bool isEmailVerified;

  AuthSession copyWith({
    String? uid,
    String? email,
    String? accessToken,
    EnrollmentStatus? enrollmentStatus,
    bool? isEmailVerified,
  }) {
    return AuthSession(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      accessToken: accessToken ?? this.accessToken,
      enrollmentStatus: enrollmentStatus ?? this.enrollmentStatus,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'accessToken': accessToken,
      'enrollmentStatus': enrollmentStatus.name,
      'isEmailVerified': isEmailVerified,
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      uid: json['uid'] as String? ?? 'demo-user',
      email: json['email'] as String,
      accessToken: json['accessToken'] as String,
      enrollmentStatus: EnrollmentStatus.values.firstWhere(
        (item) => item.name == json['enrollmentStatus'],
        orElse: () => EnrollmentStatus.enrolled,
      ),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
    );
  }
}

class AuthRepository {
  AuthRepository({
    required SharedPreferences preferences,
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firebaseFirestore,
  }) : _preferences = preferences,
       _firebaseAuth = firebaseAuth,
       _firebaseFirestore = firebaseFirestore;

  final SharedPreferences _preferences;
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firebaseFirestore;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  _PendingGoogleLink? _pendingGoogleLink;
  bool _googleSignInInitialized = false;

  static const _onboardingSeenKey = 'auth.onboarding_seen';

  Future<AuthSession?> restoreSession() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return _buildSession(user);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    await _linkPendingGoogleIfNeeded(credential.user);
    await markOnboardingSeen();
    return _buildSession(credential.user!);
  }

  Future<AuthSession> createAccount({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await markOnboardingSeen();
    try {
      await credential.user?.sendEmailVerification();
    } on FirebaseAuthException {
      // The verification screen can resend if the first attempt fails.
    }
    final token = await credential.user?.getIdToken() ?? '';
    return AuthSession(
      uid: credential.user!.uid,
      email: credential.user!.email ?? email.trim(),
      accessToken: token,
      enrollmentStatus: EnrollmentStatus.notRegistered,
      isEmailVerified: credential.user?.emailVerified ?? false,
    );
  }

  Future<AuthSession> signInWithGoogle() async {
    if (kIsWeb) {
      return _signInWithGoogleProvider();
    }

    try {
      await _ensureGoogleSignInInitialized();
      if (!_googleSignIn.supportsAuthenticate()) {
        return _signInWithGoogleProvider();
      }

      // Keep the explicit account chooser behavior, but use Android's native
      // Credential Manager UI instead of Firebase's browser/custom-tab flow.
      await _googleSignIn.signOut();
      final googleAccount = await _googleSignIn.authenticate();
      final idToken = googleAccount.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError(
          'Google sign-in needs a quick setup update before it can continue. Please contact support.',
        );
      }

      final authCredential = GoogleAuthProvider.credential(idToken: idToken);
      return _signInWithGoogleCredential(authCredential);
    } on GoogleSignInException catch (error) {
      throw StateError(_friendlyGoogleSignInError(error));
    }
  }

  Future<AuthSession> _signInWithGoogleProvider() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters({'prompt': 'select_account'});

    try {
      final credential = await _firebaseAuth.signInWithProvider(provider);
      final user = credential.user;
      if (user == null) {
        throw StateError('Google sign-in did not return a user account.');
      }

      await markOnboardingSeen();
      return await _buildSession(user);
    } on FirebaseAuthException catch (error) {
      _handlePendingGoogleLink(error);
      rethrow;
    }
  }

  Future<AuthSession> _signInWithGoogleCredential(
    AuthCredential authCredential,
  ) async {
    try {
      final credential = await _firebaseAuth.signInWithCredential(
        authCredential,
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('Google sign-in did not return a user account.');
      }

      await markOnboardingSeen();
      return _buildSession(user);
    } on FirebaseAuthException catch (error) {
      _handlePendingGoogleLink(error);
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Your session expired. Please sign in again.');
    }

    await user.sendEmailVerification();
  }

  Future<void> logout() async {
    if (!kIsWeb) {
      try {
        await _ensureGoogleSignInInitialized();
        await _googleSignIn.signOut();
      } on Object {
        // Firebase Auth remains the source of truth for the app session.
      }
    }
    await _firebaseAuth.signOut();
  }

  Future<void> persistSession(AuthSession session) async {}

  bool hasSeenOnboarding() => _preferences.getBool(_onboardingSeenKey) ?? false;

  Future<void> markOnboardingSeen() async {
    await _preferences.setBool(_onboardingSeenKey, true);
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize();
    _googleSignInInitialized = true;
  }

  void _handlePendingGoogleLink(FirebaseAuthException error) {
    if (error.code != 'account-exists-with-different-credential') return;

    final email = error.email?.trim();
    final credential = error.credential;
    if (email == null || email.isEmpty || credential == null) return;

    _pendingGoogleLink = _PendingGoogleLink(
      email: email,
      credential: credential,
    );
    throw PendingGoogleLinkException(email: email);
  }

  String _friendlyGoogleSignInError(GoogleSignInException error) {
    return switch (error.code) {
      GoogleSignInExceptionCode.canceled ||
      GoogleSignInExceptionCode.interrupted =>
        'Google sign-in was cancelled before it finished.',
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        'Google sign-in needs a quick setup update before it can continue. Please contact support.',
      GoogleSignInExceptionCode.uiUnavailable =>
        'Google sign-in could not open on this device. Please try again.',
      _ =>
        error.description?.trim().isNotEmpty == true
            ? error.description!.trim()
            : 'Google sign-in could not start. Please try again.',
    };
  }

  Future<AuthSession> _buildSession(User user) async {
    try {
      await user.reload();
    } on FirebaseAuthException {
      // Fall back to the cached user so offline launches do not force logout.
    }
    final refreshedUser = _firebaseAuth.currentUser ?? user;
    final token = await refreshedUser.getIdToken(true) ?? '';
    final doc = await _firebaseFirestore
        .collection('users')
        .doc(refreshedUser.uid)
        .get();
    final data = doc.data();
    final pendingPayment = data?['pendingPayment'];
    final hasPendingInitialPayment =
        pendingPayment is Map &&
        pendingPayment['status'] == 'Pending' &&
        pendingPayment['kind'] != 'topup';
    final status = data?['status'];

    final enrollmentStatus = !doc.exists
        ? EnrollmentStatus.notRegistered
        : status == 'Pending' || hasPendingInitialPayment
        ? EnrollmentStatus.pending
        : EnrollmentStatus.enrolled;

    return AuthSession(
      uid: refreshedUser.uid,
      email: refreshedUser.email ?? '',
      accessToken: token,
      enrollmentStatus: enrollmentStatus,
      isEmailVerified: refreshedUser.emailVerified,
    );
  }

  Future<void> _linkPendingGoogleIfNeeded(User? user) async {
    final pending = _pendingGoogleLink;
    if (pending == null || user == null) return;

    final userEmail = user.email?.trim().toLowerCase();
    if (userEmail == null || userEmail != pending.email.toLowerCase()) return;

    try {
      await user.linkWithCredential(pending.credential);
    } on FirebaseAuthException catch (error) {
      // These cases mean the provider is already connected or the original
      // credential can no longer be reused safely. Either way, password login
      // should still succeed, so we clear the pending link and move on.
      if (error.code != 'provider-already-linked' &&
          error.code != 'credential-already-in-use' &&
          error.code != 'invalid-credential') {
        rethrow;
      }
    } finally {
      _pendingGoogleLink = null;
    }
  }
}
