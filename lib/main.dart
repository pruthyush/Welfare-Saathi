import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'controllers/alert_controller.dart';
import 'controllers/screening_controller.dart';
import 'firebase_options.dart';
import 'screens/alerts_screen.dart';
import 'screens/results_screen.dart';
import 'screens/review_screen.dart';
import 'screens/scheme_detail_screen.dart';
import 'screens/scheme_directory_screen.dart';
import 'screens/screening_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/alert_repository.dart';
import 'services/auth_service.dart';
import 'services/localization_service.dart';
import 'services/profile_repository.dart';
import 'services/scheme_repository.dart';
import 'widgets/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  final authService = FirebaseAuthService();
  final profileRepository = FirestoreProfileRepository(authService: authService);

  final repository = SchemeRepository();
  await repository.loadData();

  final alertRepository = AlertRepository();
  await alertRepository.loadAlerts();
  // Fetch live alerts from Firestore if available
  alertRepository.fetchLiveAlerts().catchError((e) {
    debugPrint('Live alert fetch notice: $e');
  });

  final loc = LocalizationService();
  await loc.loadTranslations();

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
  // Navigation state enum
  // 'welcome' | 'screening' | 'results' | 'detail' | 'review' | 'alerts'
  String _currentRoute = 'welcome';
  String _previousRoute = 'welcome';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStateChange);
    widget.loc.addListener(_onStateChange);
    widget.alertController.addListener(_onStateChange);
    widget.authService?.addListener(_onStateChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStateChange);
    widget.loc.removeListener(_onStateChange);
    widget.alertController.removeListener(_onStateChange);
    widget.authService?.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    setState(() {});
  }

  void _navigateTo(String route) {
    setState(() {
      _previousRoute = _currentRoute;
      _currentRoute = route;
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
    switch (_currentRoute) {
      case 'screening':
        return ScreeningScreen(
          controller: controller,
          loc: loc,
          onComplete: () => _navigateTo('results'),
          onBackToWelcome: () => _navigateTo('welcome'),
        );

      case 'results':
        return ResultsScreen(
          controller: controller,
          loc: loc,
          alertController: widget.alertController,
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
          onBack: () => _navigateTo('welcome'),
        );

      case 'alerts':
        return AlertsScreen(
          alertController: widget.alertController,
          loc: loc,
          onBack: () => _navigateTo(_previousRoute == 'alerts' ? 'welcome' : _previousRoute),
        );

      case 'detail':
        final scheme = controller.selectedScheme;
        if (scheme == null) {
          return ResultsScreen(
            controller: controller,
            loc: loc,
            alertController: widget.alertController,
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
          onBack: () => _navigateTo(_currentRoute == 'detail' && controller.hasRunScreening ? 'results' : 'directory'),
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
          onBack: () => _navigateTo('results'),
        );

      case 'welcome':
      default:
        return WelcomeScreen(
          controller: controller,
          loc: loc,
          alertController: widget.alertController,
          authService: widget.authService,
          onOpenAlerts: () => _navigateTo('alerts'),
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
