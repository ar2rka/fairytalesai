import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile.dart';
import 'use_cases_provider.dart';

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final useCase = ref.watch(getUserProfileUseCaseProvider);
  return await useCase.execute();
});

