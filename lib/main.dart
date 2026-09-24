import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'controllers/alert_controller.dart';
import 'controllers/screening_controller.dart';
import 'firebase_options.dart';
import 'screens/alerts_screen.dart';
import 'screens/login_screen.dart';
import 'screens/results_screen.dart';
import 'screens/review_screen.dart';
import 'screens/scheme_detail_screen.dart';
import 'screens/scheme_directory_screen.dart';
import 'screens/screening_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/alert_repository.dart';
import 'services/auth_service.dart';
import 'services/localization_service.dart';
import 'services/profile_repository.dart';
import 'services/scheme_repository.dart';
import 'widgets/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase without blocking startup if it fails
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  final authService = FirebaseAuthService();
  final profileRepository = FirestoreProfileRepository(authService: authService);

  // Parallelize all data loading — run concurrently instead of sequentially
  final repository = SchemeRepository();
  final alertRepository = AlertRepository();
  final loc = LocalizationService();

  await Future.wait([
    repository.loadData(),
    alertRepository.loadLocalAlerts(), // load local only — no blocking Firestore call
    loc.loadTranslations(),
  ]);

  // Fetch live Firestore alerts asynchronously in background (non-blocking)
  alertRepository.fetchLiveAlerts().catchError((e) {
    debugPrint('Live alert fetch notice: $e');
  });

  final controller = ScreeningController(
    repository: repository,
    profileRepository: profileRepository,
    authService: authService,
  );
  final alertController = AlertController(repository: alertRepository);

  runApp(WelfareSaathiApp(
    repository: repository,
    alertRepository: alertRepository,
    loc: loc,
    controller: controller,
    alertController: alertController,
    authService: authService,
    profileRepository: profileRepository,
  ));
}

class WelfareSaathiApp extends StatefulWidget {
  final SchemeRepository repository;
  final AlertRepository alertRepository;
  final LocalizationService loc;
  final ScreeningController controller;
  final AlertController alertController;
  final AuthService? authService;
  final ProfileRepository? profileRepository;

  WelfareSaathiApp({
    super.key,
    required this.repository,
    AlertRepository? alertRepository,
    required this.loc,
    required this.controller,
    AlertController? alertController,
    this.authService,
    this.profileRepository,
  })  : alertRepository = alertRepository ?? AlertRepository(),
        alertController = alertController ??
            (alertRepository != null
                ? AlertController(repository: alertRepository)
                : AlertController(repository: AlertRepository()));

  @override
  State<WelfareSaathiApp> createState() => _WelfareSaathiAppState();
}

class _WelfareSaathiAppState extends State<WelfareSaathiApp> {
  // Navigation stack state
  // 'welcome' | 'screening' | 'results' | 'detail' | 'review' | 'alerts' | 'directory'
  final List<String> _routeHistory = ['welcome'];

  String get _currentRoute => _routeHistory.isNotEmpty ? _routeHistory.last : 'welcome';
  bool _hasLoadedStartupProfile = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStateChange);
    widget.loc.addListener(_onStateChange);
    widget.alertController.addListener(_onStateChange);
    widget.authService?.addListener(_onStateChange);
    _checkStartupProfile();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStateChange);
    widget.loc.removeListener(_onStateChange);
    widget.alertController.removeListener(_onStateChange);
    widget.authService?.removeListener(_onStateChange);
    super.dispose();
  }

  void _checkStartupProfile() {
    final auth = widget.authService;
    if (auth != null && auth.isAuthenticated && !_hasLoadedStartupProfile) {
      _hasLoadedStartupProfile = true;
      widget.controller.loadProfileFromRemote();
    } else if (auth != null && !auth.isAuthenticated) {
      _hasLoadedStartupProfile = false;
    }
  }

  void _onStateChange() {
    _checkStartupProfile();
    setState(() {});
  }

  void _navigateTo(String route) {
    setState(() {
      if (route == 'welcome') {
        _routeHistory.clear();
        _routeHistory.add('welcome');
      } else if (route == 'results' && _routeHistory.contains('results')) {
        while (_routeHistory.isNotEmpty && _routeHistory.last != 'results') {
          _routeHistory.removeLast();
        }
      } else {
        if (_routeHistory.isEmpty || _routeHistory.last != route) {
          _routeHistory.add(route);
        }
      }
    });
  }

  void _navigateBack([String? fallbackRoute]) {
    setState(() {
      if (_routeHistory.length > 1) {
        _routeHistory.removeLast();
      } else {
        _routeHistory.clear();
        _routeHistory.add(fallbackRoute ?? 'welcome');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final loc = widget.loc;
    final theme = controller.highContrast
        ? AppTheme.highContrastTheme()
        : AppTheme.lightTheme();

    return MaterialApp(
      title: 'Welfare Saathi / വെൽഫെയർ സാഥി',
      debugShowCheckedModeBanner: false,
      theme: theme,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(controller.largeText ? 1.22 : 1.0),
          ),
          child: child!,
        );
      },
      home: _buildCurrentScreen(controller, loc),
    );
  }

  Widget _buildCurrentScreen(
    ScreeningController controller,
    LocalizationService loc,
  ) {
    // -----------------------------------------------------------------
    // AUTHENTICATION GATE & PERSISTENT SESSION SOURCE OF TRUTH
    // -----------------------------------------------------------------
    final auth = widget.authService;
    if (auth != null) {
      // 1. Initializing check (prevents premature Home flash or navigation flicker)
      if (!auth.isInitialized) {
        return SplashScreen(loc: loc);
      }

      // 2. Unauthenticated state -> Enforce single-time Login first
      if (!auth.isAuthenticated) {
        return LoginScreen(
          authService: auth,
          loc: loc,
          controller: controller,
          onAuthenticated: () async {
            await widget.controller.loadProfileFromRemote();
            _navigateTo('welcome');
          },
        );
      }
    }

    // 3. Authenticated session active -> proceed to app screens
    switch (_currentRoute) {
      case 'screening':
        return ScreeningScreen(
          controller: controller,
          loc: loc,
          onComplete: () => _navigateTo('results'),
          onBackToWelcome: () => _navigateBack('welcome'),
        );

      case 'results':
        return ResultsScreen(
          controller: controller,
          loc: loc,
          alertController: widget.alertController,
          onBack: () => _navigateBack('screening'),
          onOpenAlerts: () => _navigateTo('alerts'),
          onSelectScheme: (scheme) {
            controller.selectScheme(scheme);
            _navigateTo('detail');
          },
          onReviewAnswers: () => _navigateTo('review'),
          onReset: () {
            controller.reset();
            _navigateTo('welcome');
          },
          onOpenDirectory: () => _navigateTo('directory'),
        );

      case 'directory':
        return SchemeDirectoryScreen(
          controller: controller,
          loc: loc,
          onSelectScheme: (scheme) {
            controller.selectScheme(scheme);
            _navigateTo('detail');
          },
          onStartScreening: () {
            controller.setStep(0);
            _navigateTo('screening');
          },
          onBack: () => _navigateBack('welcome'),
        );

      case 'alerts':
        return AlertsScreen(
          alertController: widget.alertController,
          loc: loc,
          onBack: () => _navigateBack('welcome'),
        );

      case 'detail':
        final scheme = controller.selectedScheme;
        if (scheme == null) {
          return ResultsScreen(
            controller: controller,
            loc: loc,
            alertController: widget.alertController,
            onBack: () => _navigateBack('welcome'),
            onOpenAlerts: () => _navigateTo('alerts'),
            onSelectScheme: (s) {
              controller.selectScheme(s);
              _navigateTo('detail');
            },
            onReviewAnswers: () => _navigateTo('review'),
            onReset: () {
              controller.reset();
              _navigateTo('welcome');
            },
            onOpenDirectory: () => _navigateTo('directory'),
          );
        }
        return SchemeDetailScreen(
          scheme: scheme,
          controller: controller,
          loc: loc,
          onBack: () => _navigateBack(controller.hasRunScreening ? 'results' : 'directory'),
          onStartScreening: () {
            controller.setStep(0);
            _navigateTo('screening');
          },
        );

      case 'review':
        return ReviewScreen(
          controller: controller,
          loc: loc,
          onRecalculate: () => _navigateTo('results'),
          onBack: () => _navigateBack(controller.hasRunScreening ? 'results' : 'welcome'),
        );

      case 'welcome':
      default:
        return WelcomeScreen(
          controller: controller,
          loc: loc,
          alertController: widget.alertController,
          authService: widget.authService,
          onOpenAlerts: () => _navigateTo('alerts'),
          onReviewProfile: () => _navigateTo('review'),
          onStartScreening: () {
            controller.setStep(0);
            _navigateTo('screening');
          },
          onSampleLoaded: () => _navigateTo('results'),
          onOpenDirectory: () => _navigateTo('directory'),
        );
    }
  }
}

