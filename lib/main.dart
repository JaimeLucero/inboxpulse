import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'screens/landing_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ga/connect_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/privacy_screen.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }
  runApp(const InboxPulseApp());
}

// Auth notifier so go_router can react to sign-in / sign-out
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}

final _authNotifier = _AuthNotifier();

bool get _loggedIn => FirebaseAuth.instance.currentUser != null;

final _router = GoRouter(
  refreshListenable: _authNotifier,
  redirect: (context, state) {
    final path = state.uri.path;
    final publicPaths = ['/', '/login', '/signup', '/privacy'];
    if (!_loggedIn && !publicPaths.contains(path)) return '/';
    if (_loggedIn && (path == '/' || path == '/login' || path == '/signup')) {
      return '/dashboard';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, s) => const LandingScreen()),
    GoRoute(
      path: '/login',
      builder: (ctx, __) => LoginScreen(
        onNavigateToSignUp: () => ctx.go('/signup'),
      ),
    ),
    GoRoute(
      path: '/signup',
      builder: (ctx, __) => SignupScreen(
        onNavigateToLogin: () => ctx.go('/login'),
      ),
    ),
    GoRoute(path: '/dashboard', builder: (_, s) => const DashboardScreen()),
    GoRoute(path: '/ga', builder: (_, s) => const GaConnectScreen()),
    GoRoute(path: '/preferences', builder: (_, s) => const PreferencesScreen()),
    GoRoute(path: '/privacy', builder: (_, s) => const PrivacyScreen()),
  ],
);

class InboxPulseApp extends StatelessWidget {
  const InboxPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'InboxPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
