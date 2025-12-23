import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/child.dart';
import 'use_cases_provider.dart';

final childrenProvider = FutureProvider<List<Child>>((ref) async {
  final useCase = ref.watch(getChildrenUseCaseProvider);
  return await useCase.execute();
});

