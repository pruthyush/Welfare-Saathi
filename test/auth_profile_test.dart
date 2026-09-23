import 'package:flutter_test/flutter_test.dart';
import 'package:welfare_saathi/controllers/screening_controller.dart';
import 'package:welfare_saathi/models/eligibility_result.dart';
import 'package:welfare_saathi/models/household_profile.dart';
import 'package:welfare_saathi/services/auth_service.dart';
import 'package:welfare_saathi/services/profile_repository.dart';
import 'package:welfare_saathi/services/scheme_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SchemeRepository schemeRepository;
  late MockAuthService mockAuth;
  late MockProfileRepository mockProfileRepo;
  late ScreeningController controller;

  setUpAll(() async {
    schemeRepository = SchemeRepository();
    await schemeRepository.loadData();
  });

  setUp(() {
    mockAuth = MockAuthService();
    mockProfileRepo = MockProfileRepository(currentUid: null);
    controller = ScreeningController(
      repository: schemeRepository,
      profileRepository: mockProfileRepo,
      authService: mockAuth,
    );
  });

  group('PHONE NUMBER AUTHENTICATION FLOW TESTS', () {
    test('1. Unauthenticated state is initial and reports no current user', () {
      expect(mockAuth.isAuthenticated, isFalse);
      expect(mockAuth.currentUser, isNull);
    });

    test('2. Send OTP with valid 10-digit mobile number sets pending phone number with +91', () async {
      await mockAuth.sendOtp(phoneNumber: '9847123456');

      expect(mockAuth.pendingPhoneNumber, equals('+919847123456'));
      expect(mockAuth.isAuthenticated, isFalse);
    });

    test('3. Verify OTP with valid 6-digit code authenticates user and sets display format', () async {
      await mockAuth.sendOtp(phoneNumber: '9847123456');
      await mockAuth.verifyOtp(otpCode: '123456');

      expect(mockAuth.isAuthenticated, isTrue);
      expect(mockAuth.currentUser, isNotNull);
      expect(mockAuth.currentUser!.phoneNumber, equals('+919847123456'));
      expect(mockAuth.currentUser!.displayPhoneNumber, equals('+91 98471 23456'));
      expect(mockAuth.currentUser!.uid, isNotEmpty);
    });

    test('4. Direct sign-in helper authenticates user with phone and OTP', () async {
      await mockAuth.signInWithPhoneNumber(
        phoneNumber: '9447012345',
        otp: '123456',
      );

      expect(mockAuth.isAuthenticated, isTrue);
      expect(mockAuth.currentUser!.phoneNumber, equals('+919447012345'));
    });

    test('5. Sign out clears authentication state completely', () async {
      await mockAuth.signInWithPhoneNumber(
        phoneNumber: '9847123456',
        otp: '123456',
      );
      expect(mockAuth.isAuthenticated, isTrue);

      await mockAuth.signOut();
      expect(mockAuth.isAuthenticated, isFalse);
      expect(mockAuth.currentUser, isNull);
      expect(mockAuth.pendingPhoneNumber, isNull);
    });
  });

  group('PROFILE PERSISTENCE & RETURNING USER TESTS', () {
    test('5. No saved profile exists initially for a new user', () async {
      mockProfileRepo.currentUid = 'new-user-123';
      final hasProfile = await mockProfileRepo.hasProfile();
      final loaded = await mockProfileRepo.loadProfile();

      expect(hasProfile, isFalse);
      expect(loaded, isNull);
    });

    test('6. Save profile persists full household answers under authenticated user boundary', () async {
      const uid = 'fisherman-uid-456';
      mockProfileRepo.currentUid = uid;

      const profile = HouseholdProfile(
        occupation: 'fishing',
        district: 'Alappuzha',
        age: 62,
        isBoardMember: true,
        yearsOfMembership: 6,
        monthlyIncome: 7000,
        rationCardCategory: 'PHH',
        housingCondition: 'kutcha',
        hasStudentChild: false,
        specialStatus: 'none',
      );

      await mockProfileRepo.saveProfile(profile);

      expect(await mockProfileRepo.hasProfile(), isTrue);
      final loaded = await mockProfileRepo.loadProfile();
      expect(loaded, isNotNull);
      expect(loaded!.occupation, equals('fishing'));
      expect(loaded.district, equals('Alappuzha'));
      expect(loaded.age, equals(62));
      expect(loaded.isBoardMember, isTrue);
      expect(loaded.yearsOfMembership, equals(6));
      expect(loaded.monthlyIncome, equals(7000));
      expect(loaded.rationCardCategory, equals('PHH'));
    });

    test('7. Returning user: edit-only-changed-fields preserves all other fields', () async {
      const uid = 'returning-worker-789';
      mockProfileRepo.currentUid = uid;

      // Saved profile from previous visit
      const initialProfile = HouseholdProfile(
        occupation: 'fishing',
        district: 'Alappuzha',
        age: 62,
        isBoardMember: true,
        yearsOfMembership: 6,
        monthlyIncome: 7000,
        rationCardCategory: 'PHH',
        housingCondition: 'kutcha',
        hasStudentChild: false,
        specialStatus: 'none',
      );
      await mockProfileRepo.saveProfile(initialProfile);

      // Load profile on returning visit
      final loaded = await mockProfileRepo.loadProfile();
      expect(loaded, isNotNull);

      // User changes ONLY income: 7000 -> 8000
      final updatedProfile = loaded!.copyWith(monthlyIncome: 8000);
      await mockProfileRepo.updateProfile(updatedProfile);

      final reloaded = await mockProfileRepo.loadProfile();
      expect(reloaded, isNotNull);
      // Changed field
      expect(reloaded!.monthlyIncome, equals(8000));
      // Preserved unchanged fields
      expect(reloaded.occupation, equals('fishing'));
      expect(reloaded.district, equals('Alappuzha'));
      expect(reloaded.age, equals(62));
      expect(reloaded.isBoardMember, isTrue);
      expect(reloaded.yearsOfMembership, equals(6));
      expect(reloaded.rationCardCategory, equals('PHH'));
      expect(reloaded.housingCondition, equals('kutcha'));
      expect(reloaded.hasStudentChild, isFalse);
    });

    test('8. Clear field produces null without restoring artificial defaults', () async {
      const profile = HouseholdProfile(
        occupation: 'plantation',
        age: 55,
        monthlyIncome: 9000,
        isBoardMember: true,
      );

      final cleared = profile.copyWith(
        clearMonthlyIncome: true,
        clearAge: true,
        clearIsBoardMember: true,
      );

      expect(cleared.monthlyIncome, isNull);
      expect(cleared.age, isNull);
      expect(cleared.isBoardMember, isNull);
      // Occupation was not cleared
      expect(cleared.occupation, equals('plantation'));
    });

    test('9. Start New Screening produces clean profile without copying old answers', () async {
      // Simulate controller currently holding a finished screening
      const previousProfile = HouseholdProfile(
        occupation: 'fishing',
        district: 'Kollam',
        age: 45,
        monthlyIncome: 12000,
        isBoardMember: true,
      );
      controller.updateProfile(previousProfile);
      controller.evaluateCurrentProfile();
      expect(controller.profile.occupation, equals('fishing'));
      expect(controller.hasRunScreening, isTrue);

      // Action: Choose "Start New Screening"
      controller.startNewScreening();

      // Old answers must NOT be silently copied
      expect(controller.profile.occupation, isNull);
      expect(controller.profile.district, isNull);
      expect(controller.profile.age, isNull);
      expect(controller.profile.monthlyIncome, isNull);
      expect(controller.profile.isBoardMember, isNull);
      expect(controller.currentStep, equals(0));
      expect(controller.hasRunScreening, isFalse);
      expect(controller.results, isEmpty);
    });
  });

  group('DETERMINISTIC ELIGIBILITY RECALCULATION TESTS', () {
    test('10. Loaded profile evaluates identically to manually entered profile', () {
      const manualProfile = HouseholdProfile(
        occupation: 'fishing',
        district: 'Alappuzha',
        age: 62,
        isBoardMember: true,
        yearsOfMembership: 6,
        monthlyIncome: 7000,
        rationCardCategory: 'PHH',
      );

      // Manual evaluation
      controller.updateProfile(manualProfile);
      controller.evaluateCurrentProfile();
      final manualEligibleIds = controller.potentiallyEligible.map((r) => r.scheme.id).toSet();

      // Reset and simulate loading from persistence
      controller.reset();
      expect(controller.results, isEmpty);

      // Continue with Saved Details
      controller.continueWithSavedProfile(manualProfile);
      final loadedEligibleIds = controller.potentiallyEligible.map((r) => r.scheme.id).toSet();

      expect(loadedEligibleIds, equals(manualEligibleIds));
    });

    test('11. Corrected profile deterministically recalculates without stale results', () {
      // Step A: Household with missing income
      const incompleteProfile = HouseholdProfile(
        occupation: 'fishing',
        district: 'Alappuzha',
        age: 62,
        isBoardMember: true,
        yearsOfMembership: 6,
        monthlyIncome: null, // missing income
      );

      controller.updateProfile(incompleteProfile);
      controller.evaluateCurrentProfile();

      // SCHEME-01 requires monthly income (< ₹8,333). Since it was skipped, it must require more info!
      final incompleteSchemeResult = controller.results
          .firstWhere((r) => r.scheme.id == 'SCHEME-01');
      expect(incompleteSchemeResult.status, equals(EligibilityStatus.moreInformationRequired));

      // Step B: User provides income = 7000 (qualifies)
      final correctedProfile = incompleteProfile.copyWith(monthlyIncome: 7000);
      controller.updateProfile(correctedProfile);
      controller.evaluateCurrentProfile();

      final updatedSchemeResult = controller.results
          .firstWhere((r) => r.scheme.id == 'SCHEME-01');
      expect(updatedSchemeResult.status, equals(EligibilityStatus.potentiallyEligible));
      expect(updatedSchemeResult.missingRules, isEmpty);
    });
  });
}
