import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final SupabaseClient _supabase;

  UserRepositoryImpl(this._supabase);

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      // Если профиль не найден, возвращаем null
      return null;
    }
  }

  @override
  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    final response = await _supabase
        .from('user_profiles')
        .update(profile.toJson())
        .eq('id', profile.id)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  @override
  Future<UserProfile> createUserProfile(UserProfile profile) async {
    final response = await _supabase
        .from('user_profiles')
        .insert(profile.toJson())
        .select()
        .single();

    return UserProfile.fromJson(response);
  }
}
