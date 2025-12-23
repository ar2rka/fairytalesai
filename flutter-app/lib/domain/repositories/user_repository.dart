import '../entities/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile?> getCurrentUserProfile();
  Future<UserProfile> updateUserProfile(UserProfile profile);
  Future<UserProfile> createUserProfile(UserProfile profile);
}

