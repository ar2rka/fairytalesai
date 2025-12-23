import '../../domain/entities/child.dart';
import '../../domain/repositories/child_repository.dart';

class CreateChildUseCase {
  final ChildRepository _repository;

  CreateChildUseCase(this._repository);

  Future<Child> execute(Child child) async {
    return await _repository.createChild(child);
  }
}

