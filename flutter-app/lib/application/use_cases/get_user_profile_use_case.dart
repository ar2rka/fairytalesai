import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';

class GetUserProfileUseCase {
  final UserRepository _repository;

  GetUserProfileUseCase(this._repository);

  Future<UserProfile?> execute() async {
    return await _repository.getCurrentUserProfile();
  }
}

