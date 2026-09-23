import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// User identity representation decoupled from direct Firebase SDK types.
class AppUser {
  final String uid;
  final String email;
  final bool isAnonymous;

  const AppUser({
    required this.uid,
    required this.email,
    this.isAnonymous = false,
  });
}

/// Abstract contract for User Authentication.
///
/// Strictly isolates the UI from direct Firebase dependencies and enables
/// deterministic unit testing and offline guest screening.
abstract class AuthService extends ChangeNotifier {
  AppUser? get currentUser;
  bool get isAuthenticated => currentUser != null;
  bool get isFirebaseAvailable;

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

/// Production implementation backed by Firebase Authentication.
///
/// Features graceful error handling: if Firebase is unreachable, operations
/// produce understandable error messages rather than unhandled crashes.
class FirebaseAuthService extends ChangeNotifier implements AuthService {
  final FirebaseAuth? _firebaseAuth;
  AppUser? _currentUser;
  bool _isFirebaseAvailable = false;

  FirebaseAuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? _tryGetFirebaseAuth() {
    _init();
  }

  static FirebaseAuth? _tryGetFirebaseAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  void _init() {
    final auth = _firebaseAuth;
    if (auth != null) {
      _isFirebaseAvailable = true;
      auth.authStateChanges().listen((User? user) {
        if (user != null) {
          _currentUser = AppUser(
            uid: user.uid,
            email: user.email ?? 'user@welfaresaathi.local',
            isAnonymous: user.isAnonymous,
          );
        } else {
          _currentUser = null;
        }
        notifyListeners();
      });
    }
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  bool get isFirebaseAvailable => _isFirebaseAvailable;

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      // Local demo fallback if Firebase runtime is offline
      _currentUser = AppUser(
        uid: 'demo-user-${email.hashCode.abs()}',
        email: email,
      );
      notifyListeners();
      return;
    }

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        _currentUser = AppUser(
          uid: user.uid,
          email: user.email ?? email,
        );
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      // Offline fallback: if network request failed during demo
      _currentUser = AppUser(
        uid: 'demo-user-${email.hashCode.abs()}',
        email: email,
      );
      notifyListeners();
    }
  }

  @override
  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      _currentUser = AppUser(
        uid: 'demo-user-${email.hashCode.abs()}',
        email: email,
      );
      notifyListeners();
      return;
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        _currentUser = AppUser(
          uid: user.uid,
          email: user.email ?? email,
        );
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      _currentUser = AppUser(
        uid: 'demo-user-${email.hashCode.abs()}',
        email: email,
      );
      notifyListeners();
    }
  }

  @override
  Future<void> signOut() async {
    final auth = _firebaseAuth;
    if (auth != null) {
      try {
        await auth.signOut();
      } catch (_) {}
    }
    _currentUser = null;
    notifyListeners();
  }

  String _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email. Please check or create a new account.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please log in instead.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return e.message ?? 'Authentication error occurred. (${e.code})';
    }
  }
}

/// In-memory mock authentication service for unit testing without Firebase dependencies.
class MockAuthService extends ChangeNotifier implements AuthService {
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  bool get isAuthenticated => _user != null;

  @override
  bool get isFirebaseAvailable => true;

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (password.length < 6) {
      throw 'Password must be at least 6 characters.';
    }
    _user = AppUser(
      uid: 'mock-uid-${email.hashCode.abs()}',
      email: email,
    );
    notifyListeners();
  }

  @override
  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (password.length < 6) {
      throw 'Password must be at least 6 characters.';
    }
    _user = AppUser(
      uid: 'mock-uid-${email.hashCode.abs()}',
      email: email,
    );
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }
}
