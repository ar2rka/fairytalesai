import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'l10n/app_localizations.dart';
import 'infrastructure/config/supabase_config.dart';
import 'infrastructure/storage/local_story_storage.dart';
import 'presentation/screens/main_navigation_screen.dart';
import 'presentation/screens/auth_screen.dart';
// Ленивая загрузка онбординга - загружается только когда нужен
import 'presentation/screens/onboarding_loader.dart'
    deferred as onboarding_loader;
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/children_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/utils/platform_utils.dart';
import 'domain/entities/user_profile.dart';
import 'domain/entities/child.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await LocalStoryStorage.init();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    postgrestOptions: const PostgrestClientOptions(
      schema: 'tales',
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Tale Generator',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
      ],
      builder: (context, child) {
        // Обёртка для применения Cupertino темы на iOS
        if (PlatformUtils.useCupertino) {
          return CupertinoTheme(
            data: AppTheme.cupertinoTheme,
            child: child!,
          );
        }
        return child!;
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final hasSession = Supabase.instance.client.auth.currentSession != null;
        return hasSession ? const ProfileCheckWrapper() : const AuthScreen();
      },
    );
  }
}

class ProfileCheckWrapper extends ConsumerWidget {
  const ProfileCheckWrapper({super.key});

  bool _needsOnboarding(UserProfile? userProfile, List<Child> children) {
    return userProfile == null || children.isEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final childrenAsync = ref.watch(childrenProvider);

    return userProfileAsync.when(
      data: (userProfile) => childrenAsync.when(
        data: (children) => _needsOnboarding(userProfile, children)
            ? const _LazyOnboardingWidget()
            : const MainNavigationScreen(),
        loading: () => _loadingWidget,
        error: (_, __) => const _LazyOnboardingWidget(),
      ),
      loading: () => _loadingWidget,
      error: (_, __) => const _LazyOnboardingWidget(),
    );
  }

  static Widget get _loadingWidget => Scaffold(
        body: Center(
          child: PlatformUtils.useCupertino
              ? const CupertinoActivityIndicator()
              : const CircularProgressIndicator(),
        ),
      );
}

class _LazyOnboardingWidget extends StatelessWidget {
  const _LazyOnboardingWidget();

  static bool _onboardingLoaded = false;
  static Future<void>? _loadingFuture;

  Future<void> _loadOnboarding() async {
    if (!_onboardingLoaded) {
      _loadingFuture ??= onboarding_loader.loadLibrary().then((_) {
        _onboardingLoaded = true;
      });
      await _loadingFuture;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadOnboarding(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: PlatformUtils.useCupertino
                  ? const CupertinoActivityIndicator()
                  : const CircularProgressIndicator(),
            ),
          );
        }
        return onboarding_loader.OnboardingScreen();
      },
    );
  }
}
