import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/value_objects/language.dart';
import '../providers/children_provider.dart';
import '../providers/repositories_provider.dart';
import '../theme/app_theme.dart';
import '../utils/platform_utils.dart';
import '../widgets/white_card.dart';
import '../widgets/gradient_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/platform_app_bar.dart';
import 'add_child_screen.dart';
import 'child_detail_screen.dart';

class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: PlatformAppBar(
        title: l10n.childrenTitle,
      ),
      body: childrenAsync.when(
        data: (children) {
          if (children.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GradientCard(
                      gradientColors: AppTheme.gradientBlue,
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.child_care,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noChildrenAddedYet,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.addYourFirstChildToCreatePersonalizedStories,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    GradientButton(
                      text: l10n.addYourFirstChild,
                      icon: Icons.add,
                      gradientColors: AppTheme.gradientPink,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddChildScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(childrenProvider.future),
            color: AppTheme.primaryPurple,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: children.length,
              itemBuilder: (context, index) {
                final child = children[index];
                final gradients = [
                  AppTheme.gradientPurple,
                  AppTheme.gradientPink,
                  AppTheme.gradientBlue,
                  AppTheme.gradientOrange,
                  AppTheme.gradientGreen,
                ];
                final gradient = gradients[index % gradients.length];

                return WhiteCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChildDetailScreen(child: child),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            child.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${child.ageCategoryEnum.displayLabel}, ${child.genderEnum.translate(Language.english)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (child.interests.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                children:
                                    child.interests.take(3).map((interest) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          gradient.first.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      interest,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: gradient.first,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Delete Button
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade300,
                        ),
                        onPressed: () async {
                          if (child.id != null) {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                if (PlatformUtils.useCupertino) {
                                  return CupertinoAlertDialog(
                                    title: Text(l10n.deleteChild),
                                    content: Text(
                                        l10n.areYouSureYouWantToDelete(child.name)),
                                    actions: [
                                      CupertinoDialogAction(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(l10n.cancel),
                                      ),
                                      CupertinoDialogAction(
                                        isDestructiveAction: true,
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(l10n.delete),
                                      ),
                                    ],
                                  );
                                }
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: Text(l10n.deleteChild),
                                  content: Text(
                                      l10n.areYouSureYouWantToDelete(child.name)),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(l10n.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red.shade300,
                                      ),
                                      child: Text(l10n.delete),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmed == true && child.id != null) {
                              try {
                                final repository =
                                    ref.read(childRepositoryProvider);
                                await repository.deleteChild(child.id!);
                                ref.invalidate(childrenProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.childDeleted),
                                      backgroundColor: AppTheme.primaryGreen,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          l10n.errorOccurred(e.toString())),
                                      backgroundColor: Colors.red.shade300,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => Center(
          child: PlatformUtils.useCupertino
              ? const CupertinoActivityIndicator()
              : const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.somethingWentWrong,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GradientButton(
                  text: l10n.retry,
                  gradientColors: AppTheme.gradientPurple,
                  onPressed: () => ref.refresh(childrenProvider),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.gradientPink,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPink.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddChildScreen(),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
