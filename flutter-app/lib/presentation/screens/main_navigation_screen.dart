import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../utils/platform_utils.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'children_screen.dart';
import 'profile_screen.dart';
import 'generate_story_screen.dart';
import 'free_stories_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          ChildrenScreen(),
          FreeStoriesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == -1) {
            // Plus button - navigate to generate story screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GenerateStoryScreen(),
              ),
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        onLogout: () => _showLogoutDialog(context, ref),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        if (PlatformUtils.useCupertino) {
          return CupertinoAlertDialog(
            title: Text(l10n.logoutFromAccount),
            content: Text(l10n.areYouSureYouWantToLogout),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () async {
                  Navigator.pop(context);
                  await _logout(ref);
                },
                child: Text(l10n.logout),
              ),
            ],
          );
        }
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(l10n.logoutFromAccount),
          content: Text(l10n.areYouSureYouWantToLogout),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _logout(ref);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade300,
              ),
              child: Text(l10n.logout),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(WidgetRef ref) async {
    try {
      await Supabase.instance.client.auth.signOut();
      // Инвалидируем провайдер профиля
      ref.invalidate(userProfileProvider);
    } catch (e) {
      // Ошибка выхода обрабатывается автоматически через StreamBuilder в AuthWrapper
    }
  }
}
