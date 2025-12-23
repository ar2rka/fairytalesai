import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';

class CreateUserProfileUseCase {
  final UserRepository _repository;

  CreateUserProfileUseCase(this._repository);

  Future<UserProfile> execute(UserProfile profile) async {
    return await _repository.createUserProfile(profile);
  }
}

