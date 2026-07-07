import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'theme/tokens.dart';
import 'icons/app_icons.dart';
import 'models/user_profile.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/tabs/home_tab.dart';
import 'screens/tabs/calendar_tab.dart';
import 'screens/tabs/memories_tab.dart';
import 'screens/tabs/journal_tab.dart';
import 'screens/tabs/circle_tab.dart';
import 'screens/tabs/me_tab.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MeTimeClubApp());
}

class MeTimeClubApp extends StatelessWidget {
  const MeTimeClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Me Time Club',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppTokens.day.bg,
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  UserProfile? _user;
  String _tab = 'home';
  bool _night = false;
  final Map<int, DailyPageContent> _dailyPages = {};
  bool _loadingSession = true;
  bool _showLogin = false;
  bool _showingTransitionLoader = false;
  UserProfile? _pendingUser;
  bool _hasCheckedToday = false;

  AppTokens get t => _night ? AppTokens.night : AppTokens.day;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user_profile');
      if (userStr != null) {
        final decoded = jsonDecode(userStr);
        final profile = UserProfile.fromJson(decoded);
        setState(() {
          _user = profile;
        });
      }
    } catch (e) {
      debugPrint('Failed to load session: $e');
    } finally {
      setState(() {
        _loadingSession = false;
      });
    }
  }

  Future<void> _saveSession(UserProfile user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile', jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Failed to save session: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile');
    } catch (e) {
      debugPrint('Failed to clear session: $e');
    }
  }

  void _startTransitionLoader(UserProfile user) {
    setState(() {
      _showingTransitionLoader = true;
      _pendingUser = user;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _user = _pendingUser;
          _showingTransitionLoader = false;
          _pendingUser = null;
        });
        if (_user != null) {
          _saveSession(_user!);
        }
      }
    });
  }

  void _onOnboardingComplete(UserProfile user) {
    _startTransitionLoader(user);
  }

  void _onUpdateUser(UserProfile updated) {
    setState(() => _user = updated);
    _saveSession(updated);
  }

  void _onLogout() async {
    final token = _user?.token;
    if (token != null && token.isNotEmpty) {
      await ApiService.logout(token: token);
    }
    await _clearSession();
    setState(() {
      _user = null;
      _showLogin = false;
      _tab = 'home';
      _dailyPages.clear();
      _hasCheckedToday = false;
    });
  }

  void _onSavePage(int dayNum, DailyPageContent? page) {
    setState(() {
      if (page == null) {
        _dailyPages.remove(dayNum);
      } else {
        _dailyPages[dayNum] = page;
      }
    });
  }

  void _toggleNight() {
    setState(() => _night = !_night);
  }

  @override
  Widget build(BuildContext context) {
    // System UI overlay based on theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _night ? Brightness.light : Brightness.dark,
      ),
    );

    if (_loadingSession) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1C1A),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB8706A)),
          ),
        ),
      );
    }

    if (_showingTransitionLoader) {
      return _buildTransitionLoader();
    }

    if (_user == null) {
      if (_showLogin) {
        return LoginScreen(
          onLoginSuccess: (profile) {
            _startTransitionLoader(profile as UserProfile);
          },
          onNavigateToRegister: () {
            setState(() {
              _showLogin = false;
            });
          },
        );
      } else {
        return OnboardingScreen(
          onComplete: _onOnboardingComplete,
          onNavigateToLogin: () {
            setState(() {
              _showLogin = true;
            });
          },
        );
      }
    }

    return Scaffold(
      backgroundColor: t.bg,
      body: Column(
        children: [
          // Header
          _buildHeader(),
          // Tab content
          Expanded(child: _buildTabContent()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Header ──────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 8,
        18,
        13,
      ),
      decoration: BoxDecoration(
        color: t.header,
        border: Border(bottom: BorderSide(color: t.border)),
        boxShadow: t.headerShadow,
      ),
      child: Row(
        children: [
          // Logo mark
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: Image.asset(
                _night
                    ? 'assets/metimeclub_logo_night_bg.png'
                    : 'assets/metimeclub_logo_cream_bg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Brand + subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tab == 'home' ? 'Me Time Club' : _tabTitle,
                style: AppTypography.playfair(_tab == 'home' ? 17 : 16, t.text),
              ),
              if (_tab == 'home')
                Text(
                  'Your daily sanctuary',
                  style: AppTypography.cormorantItalic(11, t.accent),
                ),
            ],
          ),
          const Spacer(),
          // Day/Night toggle
          GestureDetector(
            onTap: _toggleNight,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color:
                    _night
                        ? const Color(0xFF302C28)
                        : const Color(0xFFE8DDD5).withValues(alpha: 0.18),
                border: Border.all(
                  color: _night ? t.border : t.gold.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _night
                      ? AppIcons.moon(c: t.accent, s: 15)
                      : AppIcons.sun2(c: t.gold, s: 15),
                  const SizedBox(width: 6),
                  Text(
                    _night ? 'Night' : 'Day',
                    style: AppTypography.lato700(
                      11,
                      _night ? t.accent : t.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _tabTitle {
    switch (_tab) {
      case 'calendar':
        return 'Calendar';
      case 'memories':
        return 'Memories';
      case 'journal':
        return 'Journal';
      case 'circle':
        return 'Circle';
      case 'me':
        return 'Me';
      default:
        return 'Me Time Club';
    }
  }

  // ─── Tab Content ─────────────────────────────────
  Widget _buildTabContent() {
    switch (_tab) {
      case 'home':
        return HomeTab(
          user: _user!,
          t: t,
          onSavePage: _onSavePage,
          initialPage: _dailyPages[DateTime.now().day],
          hasCheckedToday: _hasCheckedToday,
          onCheckedToday: () => setState(() => _hasCheckedToday = true),
        );
      case 'calendar':
        return CalendarTab(user: _user!, t: t, dailyPages: _dailyPages);
      case 'memories':
        return MemoriesTab(user: _user!, t: t);
      case 'journal':
        return JournalTab(user: _user!, t: t);
      case 'circle':
        return CircleTab(user: _user!, t: t, userName: _user!.name);
      case 'me':
        return MeTab(
          user: _user!,
          t: t,
          onUpdateUser: _onUpdateUser,
          onLogout: _onLogout,
        );
      default:
        return HomeTab(
          user: _user!,
          t: t,
          onSavePage: _onSavePage,
          initialPage: _dailyPages[DateTime.now().day],
          hasCheckedToday: _hasCheckedToday,
          onCheckedToday: () => setState(() => _hasCheckedToday = true),
        );
    }
  }

  // ─── Bottom Navigation ───────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: t.navBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _night ? 0.4 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              _navItem('home', 'Home', (c, s) => AppIcons.home(c: c, s: s)),
              _navItem(
                'calendar',
                'Calendar',
                (c, s) => AppIcons.calendar(c: c, s: s),
              ),
              _navItem(
                'memories',
                'Memories',
                (c, s) => AppIcons.memories(c: c, s: s),
              ),
              _navItem(
                'journal',
                'Journal',
                (c, s) => AppIcons.journal(c: c, s: s),
              ),
              _navItem(
                'circle',
                'Circle',
                (c, s) => AppIcons.circle(c: c, s: s),
              ),
              _navItem('me', 'Me', (c, s) => AppIcons.me(c: c, s: s)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    String tab,
    String label,
    Widget Function(Color, double) iconBuilder,
  ) {
    final active = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: active ? t.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconBuilder(active ? t.accent : t.muted, 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: active
                    ? AppTypography.lato700(9, t.accent)
                    : AppTypography.lato400(9, t.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransitionLoader() {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1C1A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset('assets/chamomile_background.png', fit: BoxFit.cover),
          // Cozy Dark Overlay
          Container(color: const Color(0xFF1E1C1A).withValues(alpha: 0.8)),
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/metimeclub_logo_transparent.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFB8706A),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Preparing your daily sanctuary...',
                  style: AppTypography.cormorantItalic(
                    16,
                    const Color(0xFFC4945A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
