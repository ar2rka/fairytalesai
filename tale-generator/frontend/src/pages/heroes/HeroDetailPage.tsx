import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';
import { Button } from '../../components/common/Button';
import { Alert } from '../../components/common/Alert';
import { Card, CardBody, CardHeader } from '../../components/common/Card';
import type { Hero } from '../../types/models';
import { 
  UserIcon, 
  PencilIcon, 
  SparklesIcon,
  ArrowLeftIcon 
} from '@heroicons/react/24/outline';

export const HeroDetailPage: React.FC = () => {
  const { user } = useAuth();
  const { heroId } = useParams<{ heroId: string }>();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hero, setHero] = useState<Hero | null>(null);

  useEffect(() => {
    if (heroId) {
      fetchHero(heroId);
    }
  }, [heroId]);


  const fetchHero = async (id: string) => {
    try {
      setLoading(true);
      setError(null);
      
      // Fetch hero with ownership check
      // Allow access to all users for hero details
      const { data, error } = await supabase
        .from('heroes')
        .select('*')
        .eq('id', id)
        .single();
      
      if (error) {
        if (error.code === 'PGRST116') { // No rows returned
          throw new Error('Hero not found');
        } else {
          throw new Error(error.message);
        }
      }
      
      if (!data) {
        throw new Error('Hero not found');
      }
      
      setHero(data);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch hero';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

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

  if (loading) {
    return (
      <div className="min-h-screen bg-[#F5F5F5]">
        <div className="flex justify-center items-center" style={{ height: '400px' }}>
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        </div>
      </div>
    );
  }

  if (error || !hero) {
    return (
      <div className="min-h-screen bg-[#F5F5F5]">
        <div className="max-w-7xl mx-auto px-8 py-8">
          <Alert type="error" message={error || 'Hero not found'} />
          <div className="mt-4">
            <Button onClick={() => navigate('/heroes')} variant="outline">
              Back to Heroes
            </Button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F5F5F5]">
      <div className="max-w-4xl mx-auto px-8 py-8">
        {/* Header */}
        <div className="flex justify-between items-start mb-8">
          <div>
            <Button
              onClick={() => navigate('/heroes')}
              variant="outline"
              size="sm"
              className="mb-4"
              leftIcon={<ArrowLeftIcon className="h-4 w-4" />}
            >
              Back to Heroes
            </Button>
            <h1 className="text-3xl font-semibold text-neutral-900 mb-2">{hero.name}</h1>
            <p className="text-neutral-600">Hero character details and information</p>
          </div>
          <div className="flex gap-2">
            {hero.user_id === user?.id && (
              <Button
                onClick={() => navigate(`/heroes/${hero.id}/edit`)}
                variant="outline"
                leftIcon={<PencilIcon className="h-5 w-5" />}
              >
                Edit Hero
              </Button>
            )}
            <Button
              onClick={() => navigate('/stories/generate')}
              variant="primary"
              leftIcon={<SparklesIcon className="h-5 w-5" />}
            >
              Generate Story
            </Button>
          </div>
        </div>

        {/* Hero Information Card */}
        <Card className="mb-6">
          <CardHeader>
            <div className="flex justify-between items-center">
              <h2 className="text-lg font-semibold text-neutral-900">Hero Information</h2>
              <div className="flex gap-2">
                <span className="px-2.5 py-1 text-xs font-medium rounded-full bg-primary-100 text-primary-700">
                  {getLanguageDisplay(hero.language)}
                </span>
                {hero.user_id === user?.id && (
                  <span className="px-2.5 py-1 text-xs font-medium rounded-full bg-green-100 text-green-700">
                    Your Hero
                  </span>
                )}
              </div>
            </div>
          </CardHeader>
          <CardBody>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
              <div>
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-16 h-16 bg-indigo-100 rounded-full flex items-center justify-center">
                    <UserIcon className="h-8 w-8 text-indigo-600" />
                  </div>
                  <div>
                    <h3 className="text-xl font-semibold text-neutral-900">{hero.name}</h3>
                    <div className="flex items-center text-sm text-neutral-600 space-x-2">
                      <span className="capitalize">{hero.gender}</span>
                    </div>
                  </div>
                </div>
              </div>
              <div>
                <h4 className="text-sm font-medium text-neutral-500 mb-2 uppercase tracking-wide">Appearance</h4>
                <p className="text-sm text-neutral-700">{hero.appearance}</p>
              </div>
            </div>

            {/* Personality Traits */}
            <div className="mb-6">
              <h4 className="text-sm font-medium text-neutral-500 mb-3 uppercase tracking-wide">Personality Traits</h4>
              <div className="flex flex-wrap gap-2">
                {hero.personality_traits && hero.personality_traits.length > 0 ? (
                  hero.personality_traits.map((trait, index) => (
                    <span
                      key={index}
                      className="px-2.5 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-700"
                    >
                      {trait}
                    </span>
                  ))
                ) : (
                  <span className="text-sm text-neutral-400">No personality traits specified</span>
                )}
              </div>
            </div>

            {/* Interests */}
            <div className="mb-6">
              <h4 className="text-sm font-medium text-neutral-500 mb-3 uppercase tracking-wide">Interests</h4>
              <div className="flex flex-wrap gap-2">
                {hero.interests && hero.interests.length > 0 ? (
                  hero.interests.map((interest, index) => (
                    <span
                      key={index}
                      className="px-2.5 py-1 text-xs font-medium rounded-full bg-green-100 text-green-700"
                    >
                      {interest}
                    </span>
                  ))
                ) : (
                  <span className="text-sm text-neutral-400">No interests specified</span>
                )}
              </div>
            </div>

            {/* Strengths */}
            <div className="mb-4">
              <h4 className="text-sm font-medium text-neutral-500 mb-3 uppercase tracking-wide">Strengths & Powers</h4>
              <div className="flex flex-wrap gap-2">
                {hero.strengths && hero.strengths.length > 0 ? (
                  hero.strengths.map((strength, index) => (
                    <span
                      key={index}
                      className="px-2.5 py-1 text-xs font-medium rounded-full bg-yellow-100 text-yellow-700"
                    >
                      {strength}
                    </span>
                  ))
                ) : (
                  <span className="text-sm text-neutral-400">No strengths specified</span>
                )}
              </div>
            </div>

            <div className="pt-4 border-t border-neutral-100 text-xs text-neutral-500">
              <div className="flex justify-between">
                <span>Created on {formatDate(hero.created_at)}</span>
                <span>Last updated on {formatDate(hero.updated_at)}</span>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>
    </div>
  );
};
