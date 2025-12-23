import '../entities/child.dart';

abstract class ChildRepository {
  Future<List<Child>> getChildren();
  Future<Child> getChildById(String id);
  Future<Child> createChild(Child child);
  Future<Child> updateChild(Child child);
  Future<void> deleteChild(String id);
}

