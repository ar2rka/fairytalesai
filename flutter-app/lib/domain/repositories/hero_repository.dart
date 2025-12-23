import '../entities/hero.dart';

abstract class HeroRepository {
  Future<List<Hero>> getHeroes();
  Future<Hero?> getHeroById(String id);
  Future<Hero> createHero(Hero hero);
  Future<Hero> updateHero(Hero hero);
  Future<void> deleteHero(String id);
}

