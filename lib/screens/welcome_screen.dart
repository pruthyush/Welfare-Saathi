import 'package:flutter/material.dart';
import '../controllers/alert_controller.dart';
import '../controllers/screening_controller.dart';
import '../models/household_profile.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/language_selector.dart';
import 'auth_dialog.dart';

class WelcomeScreen extends StatefulWidget {
  final ScreeningController controller;
  final LocalizationService loc;
  final VoidCallback onStartScreening;
  final VoidCallback onSampleLoaded;
  final VoidCallback onOpenDirectory;
  final AlertController? alertController;
  final VoidCallback? onOpenAlerts;
  final VoidCallback? onReviewProfile;
  final AuthService? authService;

  const WelcomeScreen({
    super.key,
    required this.controller,
    required this.loc,
    required this.onStartScreening,
    required this.onSampleLoaded,
    required this.onOpenDirectory,
    this.alertController,
    this.onOpenAlerts,
    this.onReviewProfile,
    this.authService,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  HouseholdProfile? _savedProfile;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    widget.authService?.addListener(_onAuthChanged);
    _checkAndLoadProfile();
  }

  @override
  void didUpdateWidget(covariant WelcomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authService != widget.authService) {
      oldWidget.authService?.removeListener(_onAuthChanged);
      widget.authService?.addListener(_onAuthChanged);
      _checkAndLoadProfile();
    }
  }

  @override
  void dispose() {
    widget.authService?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    _checkAndLoadProfile();
  }

  Future<void> _checkAndLoadProfile() async {
    final auth = widget.authService;
    if (auth != null && auth.isAuthenticated) {
      setState(() => _isLoadingProfile = true);
      try {
        final profile = await widget.controller.loadProfileFromRemote();
        if (mounted) {
          setState(() {
            _savedProfile = profile;
            _isLoadingProfile = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isLoadingProfile = false);
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _savedProfile = null;
          _isLoadingProfile = false;
        });
      }
    }
  }

  void _openAuthDialog() {
    if (widget.authService == null) return;
    AuthDialog.show(
      context: context,
      authService: widget.authService!,
      loc: widget.loc,
      onAuthenticated: () {
        _checkAndLoadProfile();
      },
    );
  }

  void _confirmSignOut() {
    final loc = widget.loc;
    final isMl = loc.isMalayalam;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isMl ? 'ലോഗ് ഔട്ട് ചെയ്യണോ?' : 'Sign Out?'),
        content: Text(
          isMl
              ? 'നിങ്ങൾ ലോഗ് ഔട്ട് ചെയ്താൽ നിങ്ങളുടെ വിവരങ്ങൾ ഇവിടെ നിന്ന് ഒഴിവാകും. അടുത്ത തവണ ലോഗിൻ ചെയ്യുമ്പോൾ വീണ്ടും ലഭിക്കുന്നതാണ്.'
              : 'Signing out will clear the active in-memory session. Your profile remains safely stored in the cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.authService?.signOut();
              widget.controller.reset();
              _checkAndLoadProfile();
            },
            child: Text(isMl ? 'ലോഗ് ഔട്ട്' : 'Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final loc = widget.loc;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 880;
    final isMobile = !isDesktop;
    final isMl = loc.isMalayalam;
    final auth = widget.authService;
    final isAuthenticated = auth?.isAuthenticated ?? false;
    final currentUser = auth?.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.tr('appTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: isMobile
            ? [
                if (auth != null && isAuthenticated)
                  PopupMenuButton<String>(
                    tooltip: currentUser?.displayPhoneNumber ?? 'User Account',
                    icon: Icon(
                      Icons.phone_android_rounded,
                      size: 20,
                      color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                    ),
                    onSelected: (val) {
                      if (val == 'signout') {
                        _confirmSignOut();
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text(
                          currentUser?.displayPhoneNumber ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'signout',
                        child: Row(
                          children: [
                            const Icon(Icons.logout, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              isMl ? 'ലോഗ് ഔട്ട് (Sign Out)' : 'Sign Out',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                IconButton(
                  tooltip: loc.tr('schemeDirectory'),
                  icon: const Icon(Icons.menu_book_rounded),
                  onPressed: widget.onOpenDirectory,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (val) {
                    if (val == 'contrast') controller.toggleHighContrast();
                    if (val == 'font') controller.toggleLargeText();
                    if (val == 'alerts' && widget.onOpenAlerts != null) widget.onOpenAlerts!();
                  },
                  itemBuilder: (ctx) => [
                    if (widget.onOpenAlerts != null)
                      PopupMenuItem(
                        value: 'alerts',
                        child: Row(
                          children: [
                            Badge(
                              isLabelVisible: (widget.alertController?.unreadCount ?? 0) > 0,
                              label: Text('${widget.alertController?.unreadCount ?? 0}'),
                              child: const Icon(Icons.shield_outlined, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(loc.tr('safetyAlerts')),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'contrast',
                      child: Row(
                        children: [
                          Icon(controller.highContrast ? Icons.contrast : Icons.contrast_outlined, size: 20),
                          const SizedBox(width: 10),
                          Text(loc.tr('highContrast')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'font',
                      child: Row(
                        children: [
                          Icon(controller.largeText ? Icons.text_fields : Icons.format_size, size: 20),
                          const SizedBox(width: 10),
                          Text(loc.tr('fontSize')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                LanguageSelector(loc: loc, compact: true),
                const SizedBox(width: 10),
              ]
            : [
                // User Account Action
                if (auth != null)
                  if (isAuthenticated)
                    PopupMenuButton<String>(
                      tooltip: currentUser?.displayPhoneNumber ?? 'User Account',
                      icon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF333333) : const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_android_rounded,
                              size: 18,
                              color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              currentUser?.displayPhoneNumber ?? 'User',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF004D40),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 18),
                          ],
                        ),
                      ),
                      onSelected: (val) {
                        if (val == 'signout') {
                          _confirmSignOut();
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser?.displayPhoneNumber ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isMl
                                    ? 'ഉപയോക്താവിന്റെ അക്കൗണ്ട് (വിവരങ്ങൾ സൂക്ഷിക്കാൻ മാത്രം)'
                                    : 'User Account (Profile storage only)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'signout',
                          child: Row(
                            children: [
                              const Icon(Icons.logout, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                isMl ? 'ലോഗ് ഔട്ട് (Sign Out)' : 'Sign Out',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    TextButton.icon(
                      icon: const Icon(Icons.lock_person_outlined, size: 18),
                      label: Text(
                        isMl ? 'ലോഗിൻ' : 'Sign In',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _openAuthDialog,
                    ),

                if (widget.onOpenAlerts != null)
                  IconButton(
                    tooltip: loc.tr('safetyAlerts'),
                    icon: Badge(
                      isLabelVisible: (widget.alertController?.unreadCount ?? 0) > 0,
                      label: Text('${widget.alertController?.unreadCount ?? 0}'),
                      child: const Icon(Icons.shield_outlined),
                    ),
                    onPressed: widget.onOpenAlerts,
                  ),
                IconButton(
                  tooltip: loc.tr('schemeDirectory'),
                  icon: const Icon(Icons.menu_book_rounded),
                  onPressed: widget.onOpenDirectory,
                ),
                IconButton(
                  tooltip: loc.tr('highContrast'),
                  icon: Icon(controller.highContrast ? Icons.contrast : Icons.contrast_outlined),
                  onPressed: () => controller.toggleHighContrast(),
                ),
                IconButton(
                  tooltip: loc.tr('fontSize'),
                  icon: Icon(controller.largeText ? Icons.text_fields : Icons.format_size),
                  onPressed: () => controller.toggleLargeText(),
                ),
                const SizedBox(width: 8),
                LanguageSelector(loc: loc),
                const SizedBox(width: 16),
              ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 20,
            vertical: isDesktop ? 32 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1180 : 680),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Branding, Legal Disclaimer, Directory, Alerts
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeroHeader(loc, isMl, isDark),
                            const SizedBox(height: 20),
                            DisclaimerBanner(loc: loc),
                            const SizedBox(height: 20),
                            _buildDirectoryButton(isMl),
                            if (widget.onOpenAlerts != null) ...[
                              const SizedBox(height: 14),
                              _buildSafetyAlertsBanner(loc, isMl, isDark, theme),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 28),
                      // Right Column: Active Profile / Screening Workflow & Benchmarks
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildProfilePersistenceCard(context, isAuthenticated),
                            const SizedBox(height: 24),
                            _buildSampleProfilesSection(controller, loc, isMl, isDark, theme),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeroHeader(loc, isMl, isDark),
                      const SizedBox(height: 20),
                      DisclaimerBanner(loc: loc),
                      const SizedBox(height: 24),
                      _buildProfilePersistenceCard(context, isAuthenticated),
                      const SizedBox(height: 16),
                      _buildDirectoryButton(isMl),
                      if (widget.onOpenAlerts != null) ...[
                        const SizedBox(height: 12),
                        _buildSafetyAlertsBanner(loc, isMl, isDark, theme),
                      ],
                      const SizedBox(height: 28),
                      _buildSampleProfilesSection(controller, loc, isMl, isDark, theme),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(LocalizationService loc, bool isMl, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF2A2A2A)]
              : [const Color(0xFF006D77), const Color(0xFF0F4C5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('appTitle'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMl ? 'തോട്ടം & മത്സ്യത്തൊഴിലാളി ക്ഷേമസഹായി' : 'Plantation & Fisherfolk Welfare Assistant',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFFFD166) : const Color(0xFFFFDDD2),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            loc.tr('appSubtitle'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            loc.tr('welcomeBanner'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryButton(bool isMl) {
    return OutlinedButton.icon(
      onPressed: widget.onOpenDirectory,
      icon: const Icon(Icons.menu_book_rounded, size: 20),
      label: Text(
        isMl
            ? 'എല്ലാ 16 ക്ഷേമപദ്ധതികളും കാണുക (Scheme Directory)'
            : 'Browse All 16 Verified Schemes & Handbook',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildSafetyAlertsBanner(LocalizationService loc, bool isMl, bool isDark, ThemeData theme) {
    return InkWell(
      onTap: widget.onOpenAlerts,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF261D12) : const Color(0xFFFFFBEB),
          border: Border.all(
            color: isDark ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFFD97706), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        loc.tr('safetyAlerts'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF856404), width: 0.5),
                        ),
                        child: Text(
                          isMl ? 'ഡെമോ' : 'DEMO',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF856404),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMl
                        ? 'തീരദേശ & മലയോര തോട്ടം സുരക്ഷാ ജാഗ്രതാ നിർദ്ദേശങ്ങൾ'
                        : 'Coastal & Hill Plantation Safety Advisories (INCOIS / KSDMA)',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFD97706)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePersistenceCard(BuildContext context, bool isAuthenticated) {
    if (_isLoadingProfile) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (isAuthenticated && _savedProfile != null) {
      return _buildReturningUserCard(context, _savedProfile!);
    } else if (isAuthenticated && _savedProfile == null) {
      return _buildFirstTimeAuthenticatedCard(context);
    } else {
      return _buildGuestUserCard(context);
    }
  }

  Widget _buildSampleProfilesSection(
    ScreeningController controller,
    LocalizationService loc,
    bool isMl,
    bool isDark,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                loc.tr('loadSampleProfile'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        ...controller.repository.sampleProfiles.map((sample) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: isDark ? const Color(0xFF333333) : const Color(0xFFE0F2F1),
                child: Icon(
                  sample.profile.occupation == 'fishing'
                      ? Icons.phishing_rounded
                      : sample.profile.occupation == 'plantation'
                          ? Icons.eco_rounded
                          : Icons.work_outline_rounded,
                  color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                ),
              ),
              title: Text(
                sample.getTitle(isMl),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Text(
                sample.getDescription(isMl),
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                controller.loadSampleProfile(sample);
                widget.onSampleLoaded();
              },
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // RETURNING USER EXPERIENCE (Section 10 & 11)
  // ==========================================
  Widget _buildReturningUserCard(BuildContext context, HouseholdProfile profile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMl = widget.loc.isMalayalam;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2824) : const Color(0xFFF0FDF4),
        border: Border.all(
          color: isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMl
                          ? 'നിങ്ങളുടെ കുടുംബ വിവരങ്ങൾ സേവ് ചെയ്തിട്ടുണ്ട്.'
                          : 'Your household details are already saved.',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMl
                          ? 'അക്കൗണ്ട്: ${widget.authService?.currentUser?.displayPhoneNumber}'
                          : 'Account: ${widget.authService?.currentUser?.displayPhoneNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Summary Chips of Saved Profile
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSummaryBadge(
                  label: isMl ? 'തൊഴിൽ' : 'Work',
                  value: _formatOccupation(profile.occupation, isMl),
                  icon: Icons.work_outline_rounded,
                ),
                _buildSummaryBadge(
                  label: isMl ? 'ജില്ല' : 'District',
                  value: profile.district ?? (isMl ? 'തിരഞ്ഞെടുത്തിട്ടില്ല' : 'Not set'),
                  icon: Icons.location_on_outlined,
                ),
                if (profile.age != null)
                  _buildSummaryBadge(
                    label: isMl ? 'പ്രായം' : 'Age',
                    value: '${profile.age} ${isMl ? 'വയസ്സ്' : 'yrs'}',
                    icon: Icons.cake_outlined,
                  ),
                if (profile.monthlyIncome != null)
                  _buildSummaryBadge(
                    label: isMl ? 'വരുമാനം' : 'Income',
                    value: '₹${profile.monthlyIncome}/mo',
                    icon: Icons.currency_rupee_rounded,
                  ),
                if (profile.isBoardMember != null)
                  _buildSummaryBadge(
                    label: isMl ? 'ബോർഡ് അംഗം' : 'Board Member',
                    value: profile.isBoardMember == true
                        ? (isMl ? 'അംഗമാണ്' : 'Yes')
                        : (isMl ? 'അല്ല' : 'No'),
                    icon: Icons.badge_outlined,
                  ),
                if (profile.rationCardCategory != null)
                  _buildSummaryBadge(
                    label: isMl ? 'റേഷൻ കാർഡ്' : 'Ration Card',
                    value: profile.rationCardCategory!,
                    icon: Icons.credit_card_rounded,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // BUTTON 1: Review My Details (Review previously saved household details & edit only what changed)
          ElevatedButton.icon(
            onPressed: () {
              widget.controller.editSavedProfile(profile);
              if (widget.onReviewProfile != null) {
                widget.onReviewProfile!();
              } else {
                widget.controller.setStep(0);
                widget.onStartScreening();
              }
            },
            icon: const Icon(Icons.rate_review_rounded, size: 22),
            label: Text(
              isMl ? 'വിവരങ്ങൾ പരിശോധിക്കുക (Review My Details)' : 'Review My Details',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D77),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 10),

          // BUTTON 2: Continue with Saved Details (Instant re-screening & results)
          OutlinedButton.icon(
            onPressed: () {
              widget.controller.continueWithSavedProfile(profile);
              widget.onSampleLoaded();
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: Text(
              isMl ? 'നേരിട്ട് പരിശോധനാ ഫലങ്ങൾ കാണുക' : 'Continue with Saved Details',
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 8),

          // BUTTON 3: Start New Screening (Clean profile, no silent copying)
          TextButton.icon(
            onPressed: () {
              widget.controller.startNewScreening();
              widget.onStartScreening();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              isMl ? 'മറ്റൊരു കുടുംബത്തിനായി പുതിയ പരിശോധന (Start New Screening)' : 'Start New Screening (Clean Session)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),

          const Divider(height: 20),

          // Sign Out Option
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: _confirmSignOut,
              icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 16),
              label: Text(
                isMl ? 'ലോഗ് ഔട്ട് (Sign Out)' : 'Sign Out / Log Out',
                style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FIRST-TIME AUTHENTICATED USER (Section 9)
  // ==========================================
  Widget _buildFirstTimeAuthenticatedCard(BuildContext context) {
    final isMl = widget.loc.isMalayalam;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2833) : const Color(0xFFF0F9FF),
        border: Border.all(
          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF0284C7), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMl ? 'സേവ് ചെയ്ത വിവരങ്ങൾ ഇല്ല' : 'No household profile found',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMl
                          ? 'നിങ്ങൾ ലോഗിൻ ചെയ്തിട്ടുണ്ട് (${widget.authService?.currentUser?.displayPhoneNumber}). പരിശോധന പൂർത്തിയാക്കുമ്പോൾ വിവരങ്ങൾ തനിയെ സേവ് ആകും.'
                          : 'Signed in as ${widget.authService?.currentUser?.displayPhoneNumber}. Complete screening once to save your profile.',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {
              widget.controller.startNewScreening();
              widget.onStartScreening();
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 22),
            label: Text(
              widget.loc.tr('startScreening'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D77),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // GUEST / UNAUTHENTICATED EXPERIENCE
  // ==========================================
  Widget _buildGuestUserCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMl = widget.loc.isMalayalam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary Start Screening Button
        ElevatedButton.icon(
          onPressed: () {
            widget.controller.startNewScreening();
            widget.onStartScreening();
          },
          icon: const Icon(Icons.arrow_forward_rounded, size: 24),
          label: Text(
            widget.loc.tr('startScreening'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
            foregroundColor: isDark ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Sign In Callout Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262626) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_sync_outlined, color: Color(0xFF006D77), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isMl
                      ? 'വിവരങ്ങൾ പിന്നീട് ഉപയോഗിക്കാൻ സൗജന്യമായി അക്കൗണ്ട് തുറക്കാം.'
                      : 'Sign in to save your household profile across visits.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _openAuthDialog,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  isMl ? 'ലോഗിൻ' : 'Sign In',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBadge({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF006D77).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF006D77)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatOccupation(String? occ, bool isMl) {
    if (occ == 'fishing') {
      return isMl ? 'മത്സ്യത്തൊഴിലാളി' : 'Fishing';
    } else if (occ == 'plantation') {
      return isMl ? 'തോട്ടം തൊഴിലാളി' : 'Plantation';
    } else if (occ == 'other') {
      return isMl ? 'മറ്റ് തൊഴിൽ' : 'Other';
    }
    return isMl ? 'തിരഞ്ഞെടുത്തിട്ടില്ല' : 'Not set';
  }
}
