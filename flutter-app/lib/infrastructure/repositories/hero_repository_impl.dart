import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/hero.dart';
import '../../domain/repositories/hero_repository.dart';

class HeroRepositoryImpl implements HeroRepository {
  final SupabaseClient _supabase;

  HeroRepositoryImpl(this._supabase);

  @override
  Future<List<Hero>> getHeroes() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('heroes')
        .select()
        .or('user_id.is.null,user_id.eq.$userId')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Hero.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Hero?> getHeroById(String id) async {
    final response = await _supabase
        .from('heroes')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Hero.fromJson(response);
  }

  @override
  Future<Hero> createHero(Hero hero) async {
    final response = await _supabase
        .from('heroes')
        .insert(hero.toJson())
        .select()
        .single();

    return Hero.fromJson(response);
  }

  @override
  Future<Hero> updateHero(Hero hero) async {
    if (hero.id == null) {
      throw Exception('Hero ID is required for update');
    }

    final response = await _supabase
        .from('heroes')
        .update(hero.toJson())
        .eq('id', hero.id!)
        .select()
        .single();

    return Hero.fromJson(response);
  }

  @override
  Future<void> deleteHero(String id) async {
    await _supabase.from('tales.heroes').delete().eq('id', id);
  }
}

