import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';
import { Button } from '../../components/common/Button';
import { Alert } from '../../components/common/Alert';
import { Card, CardBody } from '../../components/common/Card';
import type { Hero } from '../../types/models';
import { SparklesIcon, PlusIcon, UserIcon } from '@heroicons/react/24/outline';

export const HeroesListPage: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [heroes, setHeroes] = useState<Hero[]>([]);
  const [filteredHeroes, setFilteredHeroes] = useState<Hero[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [languageFilter, setLanguageFilter] = useState('');

  useEffect(() => {
    fetchHeroes();
  }, [user]);

  const fetchHeroes = async () => {
    if (!user) return;

    try {
      setLoading(true);
      setError(null);
      
      // Fetch heroes with ownership filter
      // Show only user-owned heroes or heroes without owners
      let query = supabase
        .from('heroes')
        .select('*')
        .or(`user_id.is.null,user_id.eq.${user.id}`)
        .order('name', { ascending: true });
      
      const { data, error } = await query;
      
      if (error) {
        throw new Error(error.message);
      }
      
      setHeroes(data || []);
      setFilteredHeroes(data || []);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch heroes';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // Filter heroes based on search term and language
    let filtered = heroes;
    
    // Apply search filter
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      filtered = filtered.filter(hero => 
        hero.name.toLowerCase().includes(term) ||
        hero.appearance.toLowerCase().includes(term) ||
        hero.personality_traits.some(trait => trait.toLowerCase().includes(term)) ||
        hero.interests.some(interest => interest.toLowerCase().includes(term)) ||
        hero.strengths.some(strength => strength.toLowerCase().includes(term))
      );
    }
    
    // Apply language filter
    if (languageFilter) {
      filtered = filtered.filter(hero => hero.language === languageFilter);
    }
    
    setFilteredHeroes(filtered);
  }, [searchTerm, languageFilter, heroes]);

  const getLanguageDisplay = (lang: string) => {
    switch (lang) {
      case 'en': return 'English';
      case 'ru': return 'Русский';
      default: return lang;
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  return (
    <div className="min-h-screen bg-[#F5F5F5]">
      <div className="max-w-7xl mx-auto px-8 py-8">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-semibold text-neutral-900 mb-2">Heroes</h1>
            <p className="text-neutral-600">Manage your hero characters for stories</p>
          </div>
          <div className="flex gap-2">
            <Button 
              onClick={() => navigate('/heroes/create')} 
              variant="primary"
              leftIcon={<PlusIcon className="h-5 w-5" />}
            >
              Create Hero
            </Button>
            <Button 
              onClick={() => navigate('/stories/generate')} 
              variant="outline"
              leftIcon={<SparklesIcon className="h-5 w-5" />}
            >
              Generate Story
            </Button>
          </div>
        </div>

        {error && (
          <div className="mb-6">
            <Alert type="error" message={error} onClose={() => setError(null)} />
          </div>
        )}

        {/* Filters */}
        <Card className="mb-6">
          <CardBody>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <input
                  type="text"
                  className="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 bg-white text-gray-900"
                  placeholder="Search heroes by name, traits, interests..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>
              <div>
                <select 
                  className="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 bg-white text-gray-900"
                  value={languageFilter}
                  onChange={(e) => setLanguageFilter(e.target.value)}
                >
                  <option value="">All Languages</option>
                  <option value="en">English</option>
                  <option value="ru">Русский</option>
                </select>
              </div>
            </div>
          </CardBody>
        </Card>

        {loading ? (
          <div className="flex justify-center items-center" style={{ height: '300px' }}>
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
          </div>
        ) : filteredHeroes.length === 0 ? (
          <Card>
            <CardBody className="text-center py-12">
              <div className="w-16 h-16 mx-auto mb-4 bg-primary-100 rounded-full flex items-center justify-center">
                <UserIcon className="h-8 w-8 text-primary-600" />
              </div>
              <h3 className="text-xl font-semibold text-neutral-900 mb-2">No heroes found</h3>
              <p className="text-neutral-600 mb-6">
                {heroes.length === 0 
                  ? 'There are no heroes available yet. Create your first hero to get started!' 
                  : 'No heroes match your search criteria.'}
              </p>
              <div className="flex justify-center gap-2">
                <Button 
                  onClick={() => navigate('/heroes/create')} 
                  variant="primary"
                  leftIcon={<PlusIcon className="h-5 w-5" />}
                >
                  Create Your First Hero
                </Button>
                <Button 
                  onClick={() => navigate('/stories/generate')} 
                  variant="outline"
                  leftIcon={<SparklesIcon className="h-5 w-5" />}
                >
                  Generate a Story
                </Button>
              </div>
            </CardBody>
          </Card>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredHeroes.map((hero) => (
              <Card key={hero.id} hover className="flex flex-col">
                <CardBody className="flex-1 p-6">
                  <div className="flex justify-between items-start mb-4">
                    <div className="flex-1">
                      <h3 className="text-lg font-semibold text-neutral-900 mb-1">{hero.name}</h3>
                      <div className="flex items-center text-sm text-neutral-600 space-x-2">
                        <span className="capitalize">{hero.gender}</span>
                        {hero.user_id === user?.id && (
                          <>
                            <span>•</span>
                            <span className="px-2 py-0.5 text-xs font-medium rounded-full bg-green-100 text-green-700">
                              Your Hero
                            </span>
                          </>
                        )}
                      </div>
                    </div>
                    <span className="px-2.5 py-1 text-xs font-medium rounded-full bg-primary-100 text-primary-700">
                      {getLanguageDisplay(hero.language)}
                    </span>
                  </div>

                  <div className="mb-4">
                    <p className="text-sm text-neutral-600 line-clamp-2 mb-2">
                      <span className="font-medium">Appearance:</span> {hero.appearance}
                    </p>
                  </div>

                  <div className="mb-4">
                    <h4 className="text-xs font-medium text-neutral-500 mb-2 uppercase tracking-wide">Personality Traits</h4>
                    <div className="flex flex-wrap gap-2">
                      {hero.personality_traits && hero.personality_traits.length > 0 ? (
                        <>
                          {hero.personality_traits.slice(0, 3).map((trait, index) => (
                            <span
                              key={index}
                              className="px-2.5 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-700"
                            >
                              {trait}
                            </span>
                          ))}
                          {hero.personality_traits.length > 3 && (
                            <span className="px-2.5 py-1 text-xs font-medium rounded-full bg-gray-100 text-gray-700">
                              +{hero.personality_traits.length - 3} more
                            </span>
                          )}
                        </>
                      ) : (
                        <span className="text-sm text-neutral-400">No traits specified</span>
                      )}
                    </div>
                  </div>

                  <div className="text-xs text-neutral-500 pt-4 border-t border-neutral-100">
                    Created on {formatDate(hero.created_at)}
                  </div>
                </CardBody>
                
                <div className="px-6 py-4 border-t border-neutral-100 bg-neutral-50/50">
                  <Button
                    variant="outline"
                    onClick={() => navigate(`/heroes/${hero.id}`)}
                    size="sm"
                    fullWidth
                  >
                    View Details
                  </Button>
                </div>
              </Card>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
