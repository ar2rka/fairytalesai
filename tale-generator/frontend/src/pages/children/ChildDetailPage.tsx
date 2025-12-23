import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';
import { Button } from '../../components/common/Button';
import { Alert } from '../../components/common/Alert';
import { Card, CardBody, CardHeader } from '../../components/common/Card';
import { GenerateStoryForm } from '../../components/stories/GenerateStoryForm';
import type { ChildProfile, Story } from '../../types/models';
import { 
  UserGroupIcon, 
  PencilIcon, 
  BookOpenIcon,
  SparklesIcon 
} from '@heroicons/react/24/outline';
import { getAgeDisplay } from '../../utils/ageCategories';

export const ChildDetailPage: React.FC = () => {
  const { user, signOut } = useAuth();
  const { childId } = useParams<{ childId: string }>();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [storiesLoading, setStoriesLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [child, setChild] = useState<ChildProfile | null>(null);
  const [stories, setStories] = useState<Story[]>([]);

  useEffect(() => {
    if (childId && user) {
      fetchChild();
      fetchStories();
    }
  }, [childId, user]);

  const handleSignOut = async () => {
    try {
      await signOut();
      navigate('/login');
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  const fetchChild = async () => {
    if (!childId || !user) return;

    try {
      setLoading(true);
      setError(null);
      
      const { data, error: fetchError } = await supabase
        .from('children')
        .select('*')
        .eq('id', childId)
        .eq('user_id', user.id)
        .single();

      if (fetchError) {
        if (fetchError.code === 'PGRST116') {
          throw new Error('Child profile not found');
        } else {
          throw new Error(fetchError.message);
        }
      }

      if (!data) {
        throw new Error('Child profile not found');
      }

      setChild(data);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch child profile';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  const fetchStories = async () => {
    if (!childId || !user) return;

    try {
      setStoriesLoading(true);
      
      const { data, error: fetchError } = await supabase
        .from('stories')
        .select('*')
        .eq('child_id', childId)
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });

      if (fetchError) {
        throw new Error(fetchError.message);
      }

      setStories(data || []);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch stories';
      console.error(message);
    } finally {
      setStoriesLoading(false);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const getLanguageDisplay = (lang: string) => {
    switch (lang) {
      case 'en': return 'English';
      case 'ru': return 'Русский';
      default: return lang;
    }
  };

  const getStoryTypeDisplay = (type: string) => {
    switch (type) {
      case 'child': return 'Child Story';
      case 'hero': return 'Hero Story';
      case 'combined': return 'Combined';
      default: return 'Child Story';
    }
  };

  const handleGenerateStory = () => {
    if (childId) {
      navigate(`/stories/generate?childId=${childId}`);
    } else {
      navigate('/stories/generate');
    }
  };

  const handleStoryGenerated = (storyId: string) => {
    // Refresh stories list after generation
    fetchStories();
    // Navigate to the generated story
    navigate(`/stories/${storyId}`);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50">
        <div className="flex justify-center items-center" style={{ height: '400px' }}>
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
        </div>
      </div>
    );
  }

  if (error || !child) {
    return (
      <div className="min-h-screen bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <Alert type="error" message={error || 'Child profile not found'} />
          <div className="mt-4">
            <Button onClick={() => navigate('/children')} variant="outline">
              Back to Children
            </Button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="flex justify-between items-start mb-8">
          <div>
            <Button
              onClick={() => navigate('/children')}
              variant="outline"
              size="sm"
              className="mb-4"
            >
              ← Back to Children
            </Button>
            <h1 className="text-3xl font-semibold text-gray-900 mb-2">{child.name}'s Profile</h1>
            <p className="text-gray-600">View stories and generate new tales for {child.name}</p>
          </div>
          <div className="flex gap-2">
            <Button
              onClick={() => navigate(`/children/edit/${child.id}`)}
              variant="outline"
              leftIcon={<PencilIcon className="h-5 w-5" />}
            >
              Edit Profile
            </Button>
            <Button
              onClick={handleGenerateStory}
              variant="primary"
              leftIcon={<SparklesIcon className="h-5 w-5" />}
            >
              Generate Story
            </Button>
          </div>
        </div>

        {/* Child Information Card */}
        <Card className="mb-8">
          <CardHeader>
            <h2 className="text-lg font-semibold text-gray-900">Child Information</h2>
          </CardHeader>
          <CardBody>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-16 h-16 bg-indigo-100 rounded-full flex items-center justify-center">
                    <UserGroupIcon className="h-8 w-8 text-indigo-600" />
                  </div>
                  <div>
                    <h3 className="text-xl font-semibold text-gray-900">{child.name}</h3>
                    <div className="flex items-center text-sm text-gray-600 space-x-2">
                      <span>{getAgeDisplay(child.age)}</span>
                      <span>•</span>
                      <span className="capitalize">{child.gender}</span>
                    </div>
                  </div>
                </div>
              </div>
              <div>
                <h4 className="text-sm font-medium text-gray-500 mb-2 uppercase tracking-wide">Interests</h4>
                <div className="flex flex-wrap gap-2">
                  {child.interests && child.interests.length > 0 ? (
                    child.interests.map((interest, index) => (
                      <span
                        key={index}
                        className="px-2.5 py-1 text-xs font-medium rounded-full bg-green-100 text-green-700"
                      >
                        {interest}
                      </span>
                    ))
                  ) : (
                    <span className="text-sm text-gray-400">No interests specified</span>
                  )}
                </div>
              </div>
            </div>
          </CardBody>
        </Card>

        {/* Generate Story Form */}
        <Card className="mb-8">
          <CardHeader>
            <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
              <SparklesIcon className="h-5 w-5 text-indigo-600" />
              Generate New Story
            </h2>
          </CardHeader>
          <CardBody>
            <GenerateStoryForm 
              childId={childId || null}
              onSuccess={handleStoryGenerated}
              compact={true}
            />
          </CardBody>
        </Card>

        {/* Stories Section */}
        <div className="mb-8">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-2xl font-semibold text-gray-900">Stories</h2>
            <span className="text-sm text-gray-600">
              {stories.length} {stories.length === 1 ? 'story' : 'stories'}
            </span>
          </div>

          {storiesLoading ? (
            <div className="flex justify-center items-center" style={{ height: '200px' }}>
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
            </div>
          ) : stories.length === 0 ? (
            <Card>
              <CardBody className="text-center py-12">
                <div className="w-16 h-16 mx-auto mb-4 bg-indigo-100 rounded-full flex items-center justify-center">
                  <BookOpenIcon className="h-8 w-8 text-indigo-600" />
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-2">No stories yet</h3>
                <p className="text-gray-600 mb-6">
                  Start creating personalized stories for {child.name}!
                </p>
                <Button
                  onClick={handleGenerateStory}
                  variant="primary"
                  leftIcon={<SparklesIcon className="h-5 w-5" />}
                >
                  Generate First Story
                </Button>
              </CardBody>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {stories.map((story) => (
                <Card key={story.id} hover className="flex flex-col">
                  <CardBody className="flex-1 p-6">
                    <div className="flex justify-between items-start mb-3">
                      <h3 className="text-lg font-semibold text-gray-900 line-clamp-2">
                        {story.title}
                      </h3>
                      {story.rating && (
                        <span className="px-2.5 py-1 text-xs font-medium rounded-full bg-yellow-100 text-yellow-700 whitespace-nowrap ml-2">
                          ⭐ {story.rating}/10
                        </span>
                      )}
                    </div>

                    <div className="mb-3">
                      <span className="px-2.5 py-1 text-xs font-medium rounded-full bg-indigo-100 text-indigo-700">
                        {getStoryTypeDisplay(story.story_type || 'child')}
                      </span>
                    </div>

                    <div className="mb-3 space-y-1">
                      <div className="flex items-center text-sm text-gray-600">
                        <span className="mr-2">🌐</span>
                        <span>{getLanguageDisplay(story.language)}</span>
                      </div>
                      {story.story_length && (
                        <div className="flex items-center text-sm text-gray-600">
                          <span className="mr-2">⏱️</span>
                          <span>{story.story_length} minutes</span>
                        </div>
                      )}
                      {story.hero_name && (
                        <div className="flex items-center text-sm text-gray-600">
                          <span className="mr-2">🦸</span>
                          <span>{story.hero_name}</span>
                        </div>
                      )}
                    </div>

                    {story.moral && (
                      <div className="mb-3">
                        <span className="px-2.5 py-1 text-xs font-medium rounded-full bg-purple-100 text-purple-700">
                          {story.moral}
                        </span>
                      </div>
                    )}

                    <div className="text-xs text-gray-500 pt-3 border-t border-gray-100">
                      Created on {formatDate(story.created_at)}
                    </div>
                  </CardBody>
                  
                  <div className="px-6 py-4 border-t border-gray-100 bg-gray-50/50">
                    <Button
                      variant="outline"
                      onClick={() => navigate(`/stories/${story.id}`)}
                      size="sm"
                      fullWidth
                    >
                      View Story
                    </Button>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
