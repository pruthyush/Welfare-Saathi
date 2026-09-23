import 'package:flutter/foundation.dart';
import '../engine/eligibility_engine.dart';
import '../models/eligibility_result.dart';
import '../models/household_profile.dart';
import '../models/scheme.dart';
import '../services/scheme_repository.dart';

class ScreeningController extends ChangeNotifier {
  final SchemeRepository repository;
  final EligibilityEngine engine;

  HouseholdProfile _profile = HouseholdProfile.empty();
  List<EligibilityResult> _results = [];
  Scheme? _selectedScheme;
  int _currentStep = 0;
  bool _highContrast = false;
  bool _largeText = false;
  bool _hasRunScreening = false;

  ScreeningController({
    required this.repository,
    this.engine = const EligibilityEngine(),
  });

  HouseholdProfile get profile => _profile;
  List<EligibilityResult> get results => List.unmodifiable(_results);
  Scheme? get selectedScheme => _selectedScheme;
  int get currentStep => _currentStep;
  bool get highContrast => _highContrast;
  bool get largeText => _largeText;
  bool get hasRunScreening => _hasRunScreening;

  List<EligibilityResult> get potentiallyEligible =>
      engine.getPotentiallyEligible(_results);

  List<EligibilityResult> get moreInformationNeeded =>
      engine.getMoreInformationRequired(_results);

  List<EligibilityResult> get notMatched =>
      engine.getNotMatched(_results);

  void setStep(int step) {
    if (step >= 0 && step <= 2) {
      _currentStep = step;
      notifyListeners();
    }
  }

  void nextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      notifyListeners();
    }
  }

  void prevStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void selectScheme(Scheme scheme) {
    _selectedScheme = scheme;
    notifyListeners();
  }

  void clearSelectedScheme() {
    _selectedScheme = null;
    notifyListeners();
  }

  void toggleHighContrast() {
    _highContrast = !_highContrast;
    notifyListeners();
  }

  void toggleLargeText() {
    _largeText = !_largeText;
    notifyListeners();
  }

  /// Updates profile attributes and automatically re-evaluates if screening has already run.
  void updateProfile(HouseholdProfile newProfile) {
    _profile = newProfile;
    if (_hasRunScreening) {
      evaluateCurrentProfile();
    } else {
      notifyListeners();
    }
  }

  /// Evaluates current profile against all schemes deterministically.
  void evaluateCurrentProfile() {
    _results = engine.evaluateAll(
      schemes: repository.schemes,
      profile: _profile,
    );
    _hasRunScreening = true;
    notifyListeners();
  }

  /// Loads one of the organiser / benchmark sample profiles and evaluates it immediately.
  void loadSampleProfile(SampleProfileItem sample) {
    _profile = sample.profile;
    _currentStep = 0;
    evaluateCurrentProfile();
  }

  /// Resets the screening session in memory (preserves user privacy).
  void reset() {
    _profile = HouseholdProfile.empty();
    _results = [];
    _selectedScheme = null;
    _currentStep = 0;
    _hasRunScreening = false;
    notifyListeners();
  }
}
