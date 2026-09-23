import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/household_profile.dart';
import 'auth_service.dart';

/// Repository interface managing household profile persistence.
///
/// Keeps UI screens isolated from direct Firestore or database dependencies.
abstract class ProfileRepository {
  Future<void> saveProfile(HouseholdProfile profile);
  Future<HouseholdProfile?> loadProfile();
  Future<void> updateProfile(HouseholdProfile profile);
  Future<bool> hasProfile();
  Future<void> clearProfile();
}

/// Firestore-backed profile repository adhering to the user ownership boundary:
/// `users/{uid}/householdProfile`.
class FirestoreProfileRepository implements ProfileRepository {
  final FirebaseFirestore? _firestore;
  final AuthService _authService;
  final Map<String, HouseholdProfile> _localCache = {};

  FirestoreProfileRepository({
    required AuthService authService,
    FirebaseFirestore? firestore,
  })  : _authService = authService,
        _firestore = firestore ?? _tryGetFirestore();

  static FirebaseFirestore? _tryGetFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  String? get _currentUid => _authService.currentUser?.uid;

  @override
  Future<void> saveProfile(HouseholdProfile profile) async {
    final uid = _currentUid;
    if (uid == null) {
      throw 'Cannot save profile without an authenticated user account.';
    }

    _localCache[uid] = profile;

    final db = _firestore;
    if (db == null) return;

    try {
      await db
          .collection('users')
          .doc(uid)
          .set({
        'uid': uid,
        'phoneNumber': _authService.currentUser?.phoneNumber ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
        'householdProfile': profile.toMap(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Local cache ensures offline operation continues
    }
  }

  @override
  Future<HouseholdProfile?> loadProfile() async {
    final uid = _currentUid;
    if (uid == null) return null;

    final db = _firestore;
    if (db == null) {
      return _localCache[uid];
    }

    try {
      final doc = await db.collection('users').doc(uid).get();
      if (!doc.exists) {
        return _localCache[uid];
      }

      final data = doc.data();
      if (data != null && data.containsKey('householdProfile')) {
        final profileMap = Map<String, dynamic>.from(data['householdProfile'] as Map);
        final profile = HouseholdProfile.fromMap(profileMap);
        _localCache[uid] = profile;
        return profile;
      }
      return _localCache[uid];
    } catch (e) {
      return _localCache[uid];
    }
  }

  @override
  Future<void> updateProfile(HouseholdProfile profile) async {
    return saveProfile(profile);
  }

  @override
  Future<bool> hasProfile() async {
    final profile = await loadProfile();
    return profile != null;
  }

  @override
  Future<void> clearProfile() async {
    final uid = _currentUid;
    if (uid == null) return;

    _localCache.remove(uid);

    final db = _firestore;
    if (db == null) return;

    try {
      await db.collection('users').doc(uid).update({
        'householdProfile': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}

/// In-memory mock profile repository for tests.
class MockProfileRepository implements ProfileRepository {
  final Map<String, HouseholdProfile> _store = {};
  String? currentUid;

  MockProfileRepository({this.currentUid = 'mock-user-1'});

  @override
  Future<void> saveProfile(HouseholdProfile profile) async {
    if (currentUid == null) throw 'No user authenticated';
    _store[currentUid!] = profile;
  }

  @override
  Future<HouseholdProfile?> loadProfile() async {
    if (currentUid == null) return null;
    return _store[currentUid!];
  }

  @override
  Future<void> updateProfile(HouseholdProfile profile) async {
    return saveProfile(profile);
  }

  @override
  Future<bool> hasProfile() async {
    return loadProfile().then((p) => p != null);
  }

  @override
  Future<void> clearProfile() async {
    if (currentUid != null) {
      _store.remove(currentUid);
    }
  }
}
