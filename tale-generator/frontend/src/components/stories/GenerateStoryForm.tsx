import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';
import { Button } from '../common/Button';
import { Alert } from '../common/Alert';
import { Input } from '../common/Input';
import { Card, CardBody, CardHeader } from '../common/Card';
import type { ChildProfile, Hero, Story } from '../../types/models';
import { getAgeCategoryDisplay } from '../../utils/ageCategories';

interface GenerateStoryFormProps {
  childId?: string | null;
  parentId?: string | null;
  onSuccess?: (storyId: string) => void;
  compact?: boolean;
}

export const GenerateStoryForm: React.FC<GenerateStoryFormProps> = ({
  childId: initialChildId,
  parentId: initialParentId,
  onSuccess,
  compact = false,
}) => {
  const { user, session } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [children, setChildren] = useState<ChildProfile[]>([]);
  const [selectedChildId, setSelectedChildId] = useState<string | null>(initialChildId || null);
  const [language, setLanguage] = useState<'en' | 'ru'>('en');
  const [storyLength, setStoryLength] = useState<number>(5);
  const [moral, setMoral] = useState<string>('');
  const [storyType, setStoryType] = useState<'child' | 'hero' | 'combined'>('child');
  const [heroes, setHeroes] = useState<Hero[]>([]);
  const [selectedHeroId, setSelectedHeroId] = useState<string | null>(null);
  const [filteredHeroes, setFilteredHeroes] = useState<Hero[]>([]);
  const [subscriptionPlan, setSubscriptionPlan] = useState<string>('free');
  const [maxStoryLength, setMaxStoryLength] = useState<number>(30);
  const [availableStories, setAvailableStories] = useState<Story[]>([]);
  const [selectedParentId, setSelectedParentId] = useState<string | null>(null);
  const [isContinuation, setIsContinuation] = useState<boolean>(false);

  useEffect(() => {
    if (user) {
      if (!initialChildId) {
        fetchChildren();
      } else {
        setLoading(false);
      }
      fetchHeroes();
      fetchSubscription();
      fetchAvailableStories();
    }
  }, [user, initialChildId]);

  useEffect(() => {
    // Fetch stories when child is selected for continuation
    if (selectedChildId && isContinuation) {
      fetchAvailableStories();
    }
  }, [selectedChildId, isContinuation]);

  useEffect(() => {
    if (initialChildId) {
      setSelectedChildId(initialChildId);
    }
    if (initialParentId) {
      setSelectedParentId(initialParentId);
      setIsContinuation(true);
    }
  }, [initialChildId, initialParentId]);

  useEffect(() => {
    // Filter heroes by selected language
    const filtered = heroes.filter(hero => hero.language === language);
    setFilteredHeroes(filtered);
    
    // Reset hero selection if current hero doesn't match language
    if (selectedHeroId && !filtered.find(h => h.id === selectedHeroId)) {
      setSelectedHeroId(filtered.length > 0 ? filtered[0].id : null);
    } else if (!selectedHeroId && filtered.length > 0) {
      setSelectedHeroId(filtered[0].id);
    }
  }, [language, heroes, selectedHeroId]);

  const fetchChildren = async () => {
    if (!user) return;

    try {
      setLoading(true);
      setError(null);
      
      const { data, error: fetchError } = await supabase
        .from('children')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (fetchError) {
        throw new Error(fetchError.message);
      }

      setChildren(data || []);
      
      // Select the first child if available
      if (data && data.length > 0 && !selectedChildId) {
        setSelectedChildId(data[0].id);
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch children';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  const fetchHeroes = async () => {
    if (!user) return;

    try {
      setError(null);
      
      // Fetch heroes (both user-owned and public heroes)
      const { data, error: fetchError } = await supabase
        .from('heroes')
        .select('*')
        .or(`user_id.is.null,user_id.eq.${user.id}`)
        .order('name', { ascending: true });

      if (fetchError) {
        throw new Error(fetchError.message);
      }

      setHeroes(data || []);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch heroes';
      console.error(message);
    }
  };

  const fetchSubscription = async () => {
    if (!user) return;

    try {
      const response = await fetch('http://localhost:8000/api/v1/users/subscription', {
        headers: {
          'Authorization': `Bearer ${session?.access_token}`,
        },
      });

      if (response.ok) {
        const data = await response.json();
        setSubscriptionPlan(data.subscription.plan);
        setMaxStoryLength(data.limits.max_story_length);
        
        // Adjust story length if it exceeds the limit
        if (storyLength > data.limits.max_story_length) {
          setStoryLength(data.limits.max_story_length);
        }
      }
    } catch (err) {
      console.error('Failed to fetch subscription:', err);
    }
  };

  const fetchAvailableStories = async () => {
    if (!user) return;

    try {
      // Fetch stories for the selected child (or all stories if no child selected)
      let query = supabase
        .from('stories')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })
        .limit(50);

      if (selectedChildId) {
        query = query.eq('child_id', selectedChildId);
      }

      const { data, error: fetchError } = await query;

      if (fetchError) {
        throw new Error(fetchError.message);
      }

      setAvailableStories(data || []);
    } catch (err) {
      console.error('Failed to fetch available stories:', err);
    }
  };

  const handleGenerateStory = async () => {
    if (!selectedChildId) {
      setError('Please select a child first');
      return;
    }

    // Validate hero selection for hero/combined stories
    if ((storyType === 'hero' || storyType === 'combined') && !selectedHeroId) {
      setError('Please select a hero for this story type');
      return;
    }

    // Validate parent story selection for continuation
    if (isContinuation && !selectedParentId) {
      setError('Please select a parent story for continuation');
      return;
    }

    try {
      setGenerating(true);
      setError(null);
      setSuccess(null);
      
      interface StoryRequest {
        language: 'en' | 'ru';
        child_id: string;
        story_type: 'child' | 'hero' | 'combined';
        story_length: number;
        moral?: string;
        hero_id?: string;
        parent_id?: string;
      }

      const requestBody: StoryRequest = {
        language,
        child_id: selectedChildId,
        story_type: storyType,
        story_length: storyLength,
        ...(moral && { moral }),
        ...((storyType === 'hero' || storyType === 'combined') && selectedHeroId && { hero_id: selectedHeroId }),
        ...(isContinuation && selectedParentId && { parent_id: selectedParentId }),
      };
      
      const response = await fetch('http://localhost:8000/api/v1/stories/generate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${session?.access_token}`,
        },
        body: JSON.stringify(requestBody),
      });

      if (!response.ok) {
        const errorData = await response.json();
        
        // Handle structured error responses from subscription validator
        if (errorData.detail && typeof errorData.detail === 'object') {
          const detail = errorData.detail;
          
          // Format user-friendly error messages based on error code
          if (detail.error_code === 'STORY_TYPE_NOT_ALLOWED') {
            throw new Error(
              `This story type is not available on your current plan (${detail.current_plan}). ` +
              `Please upgrade to access hero and combined stories, or choose "Child Story" instead.`
            );
          } else if (detail.error_code === 'MONTHLY_LIMIT_EXCEEDED') {
            const limitInfo = detail.limit_info;
            throw new Error(
              `Monthly story limit reached (${limitInfo.stories_used}/${limitInfo.monthly_limit}). ` +
              `Your limit resets on ${new Date(limitInfo.reset_date).toLocaleDateString()}.`
            );
          } else if (detail.error_code === 'AUDIO_NOT_ALLOWED') {
            throw new Error(
              `Audio generation is not available on your current plan (${detail.current_plan}). ` +
              `Please upgrade to access this feature.`
            );
          } else if (detail.error_code === 'STORY_LENGTH_EXCEEDED') {
            throw new Error(
              `Story length ${detail.requested_length} minutes exceeds your plan limit of ${detail.max_length} minutes.`
            );
          } else if (detail.error_code === 'SUBSCRIPTION_INACTIVE') {
            throw new Error(
              `Your subscription is ${detail.subscription_status}. Please contact support.`
            );
          } else {
            throw new Error(detail.detail || 'Failed to generate story');
          }
        }
        
        // Fallback to simple message or detail string
        throw new Error(errorData.detail || errorData.message || 'Failed to generate story');
      }

      const storyData = await response.json();
      setSuccess(`Story "${storyData.title}" generated successfully!`);
      
      // Call onSuccess callback if provided, otherwise navigate
      if (onSuccess) {
        setTimeout(() => {
          onSuccess(storyData.id);
        }, 1000);
      } else {
        setTimeout(() => {
          navigate(`/stories/${storyData.id}`);
        }, 2000);
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to generate story';
      setError(message);
    } finally {
      setGenerating(false);
    }
  };

  if (loading && !initialChildId) {
    return (
      <div className="flex justify-center items-center" style={{ height: '300px' }}>
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  if (!initialChildId && children.length === 0) {
    return (
      <Card>
        <CardBody className="text-center py-12">
          <h3 className="text-xl font-semibold text-gray-900 mb-2">No children found</h3>
          <p className="text-gray-600 mb-6">You need to add a child profile before generating stories.</p>
          <Button onClick={() => navigate('/children/add')} variant="primary">
            Add Your First Child
          </Button>
        </CardBody>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      {error && (
        <Alert type="error" message={error} onClose={() => setError(null)} />
      )}
      {success && (
        <Alert type="success" message={success} onClose={() => setSuccess(null)} />
      )}

      <Card>
        <CardHeader>
          <h2 className="text-lg font-semibold text-gray-900">Story Settings</h2>
        </CardHeader>
        <CardBody className="space-y-6">
          {/* Story Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-3">Story Type</label>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              <button
                type="button"
                onClick={() => setStoryType('child')}
                className={`p-4 rounded-lg border-2 transition-all text-left ${
                  storyType === 'child'
                    ? 'border-indigo-500 bg-indigo-50'
                    : 'border-gray-200 hover:border-gray-300 bg-white'
                }`}
              >
                <div className="font-semibold text-gray-900 mb-1">Child Story</div>
                <div className="text-sm text-gray-600">Story about the child</div>
              </button>
              <button
                type="button"
                onClick={() => setStoryType('hero')}
                disabled={subscriptionPlan === 'free'}
                className={`p-4 rounded-lg border-2 transition-all text-left ${
                  storyType === 'hero'
                    ? 'border-indigo-500 bg-indigo-50'
                    : 'border-gray-200 hover:border-gray-300 bg-white'
                } ${subscriptionPlan === 'free' ? 'opacity-50 cursor-not-allowed' : ''}`}
              >
                <div className="font-semibold text-gray-900 mb-1 flex items-center gap-2">
                  Hero Story
                  {subscriptionPlan === 'free' && (
                    <span className="text-xs px-2 py-0.5 bg-amber-100 text-amber-700 rounded-full">Premium</span>
                  )}
                </div>
                <div className="text-sm text-gray-600">Story about a hero</div>
              </button>
              <button
                type="button"
                onClick={() => setStoryType('combined')}
                disabled={subscriptionPlan === 'free'}
                className={`p-4 rounded-lg border-2 transition-all text-left ${
                  storyType === 'combined'
                    ? 'border-indigo-500 bg-indigo-50'
                    : 'border-gray-200 hover:border-gray-300 bg-white'
                } ${subscriptionPlan === 'free' ? 'opacity-50 cursor-not-allowed' : ''}`}
              >
                <div className="font-semibold text-gray-900 mb-1 flex items-center gap-2">
                  Combined Adventure
                  {subscriptionPlan === 'free' && (
                    <span className="text-xs px-2 py-0.5 bg-amber-100 text-amber-700 rounded-full">Premium</span>
                  )}
                </div>
                <div className="text-sm text-gray-600">Child & hero together</div>
              </button>
            </div>
          </div>
          
          {/* Select Child and Language */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {!initialChildId && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-3">
                  Select Child
                </label>
                <div className="flex flex-wrap gap-4">
                  {children.map((child) => (
                    <button
                      key={child.id}
                      type="button"
                      onClick={() => setSelectedChildId(child.id)}
                      className={`flex flex-col items-center transition-all ${
                        selectedChildId === child.id
                          ? 'opacity-100 scale-105'
                          : 'opacity-70 hover:opacity-100 hover:scale-105'
                      }`}
                    >
                      <div
                        className={`w-20 h-20 rounded-full border-4 overflow-hidden bg-gradient-to-br from-indigo-400 to-purple-500 flex items-center justify-center ${
                          selectedChildId === child.id
                            ? 'border-indigo-500 ring-4 ring-indigo-200'
                            : 'border-gray-200 hover:border-indigo-300'
                        }`}
                      >
                        <span className="text-white text-2xl font-bold">
                          {child.name.charAt(0).toUpperCase()}
                        </span>
                      </div>
                      <span className={`mt-2 text-sm font-medium ${
                        selectedChildId === child.id
                          ? 'text-indigo-600'
                          : 'text-gray-700'
                      }`}>
                        {child.name}
                      </span>
                      <span className="text-xs text-gray-500">{getAgeCategoryDisplay(child.age_category)}</span>
                    </button>
                  ))}
                </div>
              </div>
            )}
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-3">
                Language
              </label>
              <div className="inline-flex rounded-lg border border-gray-200 bg-gray-50 p-1">
                <button
                  type="button"
                  onClick={() => setLanguage('en')}
                  className={`px-4 py-2 rounded-md text-sm font-medium transition-all ${
                    language === 'en'
                      ? 'bg-white text-indigo-600 shadow-sm'
                      : 'text-gray-600 hover:text-gray-900'
                  }`}
                >
                  English
                </button>
                <button
                  type="button"
                  onClick={() => setLanguage('ru')}
                  className={`px-4 py-2 rounded-md text-sm font-medium transition-all ${
                    language === 'ru'
                      ? 'bg-white text-indigo-600 shadow-sm'
                      : 'text-gray-600 hover:text-gray-900'
                  }`}
                >
                  Русский
                </button>
              </div>
            </div>
          </div>
          
          {/* Select Hero */}
          {(storyType === 'hero' || storyType === 'combined') && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-3">
                Select Hero
              </label>
              {filteredHeroes.length === 0 ? (
                <div className="p-4 bg-amber-50 border border-amber-200 rounded-lg">
                  <p className="text-sm text-amber-900 mb-3">
                    No heroes available for {language === 'en' ? 'English' : 'Russian'} stories.
                  </p>
                  <Button 
                    onClick={() => navigate('/heroes/create')} 
                    variant="primary"
                    size="sm"
                  >
                    Create a Hero
                  </Button>
                </div>
              ) : (
                <div className="flex flex-wrap gap-4">
                  {filteredHeroes.map((hero) => (
                    <button
                      key={hero.id}
                      type="button"
                      onClick={() => setSelectedHeroId(hero.id)}
                      className={`flex flex-col items-center transition-all ${
                        selectedHeroId === hero.id
                          ? 'opacity-100 scale-105'
                          : 'opacity-70 hover:opacity-100 hover:scale-105'
                      }`}
                    >
                      <div
                        className={`w-20 h-20 rounded-full border-4 overflow-hidden bg-gradient-to-br from-yellow-400 to-orange-500 flex items-center justify-center ${
                          selectedHeroId === hero.id
                            ? 'border-indigo-500 ring-4 ring-indigo-200'
                            : 'border-gray-200 hover:border-indigo-300'
                        }`}
                      >
                        <span className="text-white text-2xl font-bold">
                          {hero.name.charAt(0).toUpperCase()}
                        </span>
                      </div>
                      <span className={`mt-2 text-sm font-medium text-center max-w-[100px] ${
                        selectedHeroId === hero.id
                          ? 'text-indigo-600'
                          : 'text-gray-700'
                      }`}>
                        {hero.name}
                      </span>
                    </button>
                  ))}
                </div>
              )}
            </div>
          )}
          
          {/* Story Length */}
          <div>
            <div className="flex items-center justify-between mb-3">
              <label className="block text-sm font-medium text-gray-700">
                Story Length
              </label>
              <div className="flex items-center gap-2">
                <span className="text-lg font-semibold text-indigo-600">
                  {storyLength} {storyLength === 1 ? 'minute' : 'minutes'}
                </span>
                {(subscriptionPlan === 'free' || subscriptionPlan === 'starter') && (
                  <span className="text-xs text-amber-600">
                    (Max {maxStoryLength} min)
                  </span>
                )}
              </div>
            </div>
            <div className="relative px-1">
              <input
                type="range"
                className="w-full h-3 bg-gray-200 rounded-lg appearance-none cursor-pointer story-length-slider"
                style={{
                  background: `linear-gradient(to right, rgb(99, 102, 241) 0%, rgb(99, 102, 241) ${((storyLength - 1) / (maxStoryLength - 1)) * 100}%, rgb(229, 231, 235) ${((storyLength - 1) / (maxStoryLength - 1)) * 100}%, rgb(229, 231, 235) 100%)`
                }}
                min="1"
                max={maxStoryLength}
                value={storyLength}
                onChange={(e) => setStoryLength(parseInt(e.target.value))}
              />
              <style>{`
                .story-length-slider::-webkit-slider-thumb {
                  appearance: none;
                  width: 20px;
                  height: 20px;
                  border-radius: 50%;
                  background: rgb(99, 102, 241);
                  cursor: pointer;
                  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
                  border: 2px solid white;
                  transition: transform 0.1s ease;
                }
                .story-length-slider::-webkit-slider-thumb:hover {
                  transform: scale(1.1);
                }
                .story-length-slider::-moz-range-thumb {
                  width: 20px;
                  height: 20px;
                  border-radius: 50%;
                  background: rgb(99, 102, 241);
                  cursor: pointer;
                  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
                  border: 2px solid white;
                  transition: transform 0.1s ease;
                }
                .story-length-slider::-moz-range-thumb:hover {
                  transform: scale(1.1);
                }
              `}</style>
            </div>
            <div className="flex justify-between text-xs text-gray-500 mt-2">
              <span>1 min</span>
              <span>{maxStoryLength} min</span>
            </div>
          </div>
          
          {/* Moral Value */}
          <div>
            <Input
              label="Moral Value (optional)"
              type="text"
              placeholder="Enter a moral value (e.g., kindness, honesty)"
              value={moral}
              onChange={(e) => setMoral(e.target.value)}
            />
          </div>

          {/* Story Continuation */}
          <div>
            <div className="flex items-center mb-3">
              <input
                type="checkbox"
                id="isContinuation"
                checked={isContinuation}
                onChange={(e) => {
                  setIsContinuation(e.target.checked);
                  if (!e.target.checked) {
                    setSelectedParentId(null);
                  }
                }}
                className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
              />
              <label htmlFor="isContinuation" className="ml-2 block text-sm font-medium text-gray-700">
                Generate as continuation of another story
              </label>
            </div>
            {isContinuation && (
              <div className="mt-3">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Select Parent Story
                </label>
                {availableStories.length === 0 ? (
                  <div className="p-4 bg-amber-50 border border-amber-200 rounded-lg">
                    <p className="text-sm text-amber-900">
                      No stories available for continuation. Please generate a story first.
                    </p>
                  </div>
                ) : (
                  <select
                    value={selectedParentId || ''}
                    onChange={(e) => setSelectedParentId(e.target.value || null)}
                    className="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 bg-white text-gray-900"
                  >
                    <option value="">Select a story to continue...</option>
                    {availableStories.map((story) => (
                      <option key={story.id} value={story.id}>
                        {story.title} ({story.language === 'en' ? 'English' : 'Русский'}, {new Date(story.created_at).toLocaleDateString()})
                      </option>
                    ))}
                  </select>
                )}
                {isContinuation && !selectedParentId && (
                  <p className="mt-2 text-sm text-amber-600">
                    Please select a parent story to continue from.
                  </p>
                )}
              </div>
            )}
          </div>
          
          {/* Generate Button */}
          <div className="pt-4">
            <Button
              onClick={handleGenerateStory}
              variant="primary"
              size="lg"
              loading={generating}
              disabled={!selectedChildId || generating}
              fullWidth
            >
              {generating ? 'Generating Story...' : 'Generate Story'}
            </Button>
          </div>
        </CardBody>
      </Card>
    </div>
  );
};








