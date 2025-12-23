import '../../domain/entities/child.dart';
import '../../domain/repositories/child_repository.dart';

class GetChildrenUseCase {
  final ChildRepository _repository;

  GetChildrenUseCase(this._repository);

  Future<List<Child>> execute() async {
    return await _repository.getChildren();
  }
}

