import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';
import { Button } from '../../components/common/Button';
import { Alert } from '../../components/common/Alert';
import { Card, CardBody, CardHeader } from '../../components/common/Card';
import type { Story } from '../../types/models';
import {
  ArrowLeftIcon,
  BookOpenIcon,
  SparklesIcon,
  StarIcon,
  ClockIcon,
  GlobeAltIcon,
  UserIcon,
  UserGroupIcon,
  TagIcon,
  CalendarIcon,
  CheckCircleIcon,
  ArchiveBoxIcon,
  DocumentTextIcon,
} from '@heroicons/react/24/outline';
import { StarIcon as StarIconSolid } from '@heroicons/react/24/solid';

export const StoryDetailPage: React.FC = () => {
  const { user, signOut } = useAuth();
  const { storyId } = useParams<{ storyId: string }>();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [story, setStory] = useState<Story | null>(null);
  const [parentStory, setParentStory] = useState<Story | null>(null);
  const [rating, setRating] = useState<number>(0);
  const [hoveredStar, setHoveredStar] = useState<number | null>(null);

  useEffect(() => {
    if (storyId) {
      fetchStory(storyId);
    }
  }, [storyId]);

  const handleSignOut = async () => {
    try {
      await signOut();
      navigate('/login');
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  const fetchStory = async (id: string) => {
    try {
      setLoading(true);
      setError(null);
      
      const { data, error } = await supabase
        .from('stories')
        .select('*')
        .eq('id', id)
        .eq('user_id', user?.id || '')
        .single();
      
      if (error) {
        if (error.code === 'PGRST116') {
          throw new Error('Story not found');
        } else {
          throw new Error(error.message);
        }
      }
      
      if (!data) {
        throw new Error('Story not found');
      }
      
      setStory(data);
      
      if (data.rating) {
        setRating(data.rating);
      }

      // Fetch parent story if this is a continuation
      if (data.parent_id) {
        fetchParentStory(data.parent_id);
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch story';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  const fetchParentStory = async (parentId: string) => {
    if (!user) return;

    try {
      const { data, error } = await supabase
        .from('stories')
        .select('*')
        .eq('id', parentId)
        .eq('user_id', user.id)
        .single();
      
      if (error) {
        console.error('Failed to fetch parent story:', error);
        return;
      }
      
      if (data) {
        setParentStory(data);
      }
    } catch (err) {
      console.error('Error fetching parent story:', err);
    }
  };

  const handleRatingChange = async (newRating: number) => {
    if (!storyId || !story || !user) return;
    
    try {
      setRating(newRating);
      
      const { error } = await supabase
        .from('stories')
        .update({ 
          rating: newRating, 
          updated_at: new Date().toISOString() 
        })
        .eq('id', storyId)
        .eq('user_id', user.id);
      
      if (error) {
        throw new Error(error.message);
      }
      
      setStory({ ...story, rating: newRating });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to update rating';
      setError(message);
      setRating(story?.rating || 0);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const getLanguageDisplay = (lang: string) => {
    switch (lang) {
      case 'en': return 'English';
      case 'ru': return 'Русский';
      default: return lang;
    }
  };

  const getStatusDisplay = (status: string) => {
    switch (status) {
      case 'new': return 'New';
      case 'read': return 'Read';
      case 'archived': return 'Archived';
      default: return status;
    }
  };

  const getStatusBadgeColor = (status: string) => {
    switch (status) {
      case 'new': return 'bg-indigo-100 text-indigo-700';
      case 'read': return 'bg-green-100 text-green-700';
      case 'archived': return 'bg-gray-100 text-gray-700';
      default: return 'bg-gray-100 text-gray-700';
    }
  };

  const getStoryTypeDisplay = (type: string) => {
    switch (type) {
      case 'child': return 'Child Story';
      case 'hero': return 'Hero Story';
      case 'combined': return 'Combined Adventure';
      default: return 'Child Story';
    }
  };

  const getStoryTypeBadgeColor = (type: string) => {
    switch (type) {
      case 'child': return 'bg-blue-100 text-blue-700';
      case 'hero': return 'bg-amber-100 text-amber-700';
      case 'combined': return 'bg-purple-100 text-purple-700';
      default: return 'bg-blue-100 text-blue-700';
    }
  };

  const updateStoryStatus = async (newStatus: string) => {
    if (!storyId || !story || !user) return;
    
    try {
      const { error } = await supabase
        .from('stories')
        .update({ 
          status: newStatus, 
          updated_at: new Date().toISOString() 
        })
        .eq('id', storyId)
        .eq('user_id', user.id);
      
      if (error) {
        throw new Error(error.message);
      }
      
      setStory({ ...story, status: newStatus });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to update status';
      setError(message);
    }
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

  if (error || !story) {
    return (
      <div className="min-h-screen bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <Alert type="error" message={error || 'Story not found'} />
          <div className="mt-4">
            <Button onClick={() => navigate('/stories')} variant="outline">
              Back to Stories
            </Button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="flex justify-between items-start mb-8">
          <div>
            <Button
              onClick={() => navigate('/stories')}
              variant="outline"
              size="sm"
              className="mb-4"
              leftIcon={<ArrowLeftIcon className="h-4 w-4" />}
            >
              Back to Stories
            </Button>
            <h1 className="text-3xl font-semibold text-gray-900 mb-2">Story Details</h1>
            <p className="text-gray-600">Read and manage your personalized tale</p>
          </div>
        </div>

        {error && (
          <div className="mb-6">
            <Alert type="error" message={error} onClose={() => setError(null)} />
          </div>
        )}

        {/* Story Header Card */}
        <Card className="mb-6">
          <CardBody>
            <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-4">
              <div className="flex-1">
                <div className="flex items-start gap-3 mb-4">
                  <div className="w-12 h-12 bg-indigo-100 rounded-lg flex items-center justify-center flex-shrink-0">
                    <BookOpenIcon className="h-6 w-6 text-indigo-600" />
                  </div>
                  <div className="flex-1">
                    <h2 className="text-2xl font-semibold text-gray-900 mb-3">{story.title}</h2>
                    <div className="flex flex-wrap items-center gap-2 mb-3">
                      <span className={`px-2.5 py-1 text-xs font-medium rounded-full ${getStoryTypeBadgeColor(story.story_type || 'child')}`}>
                        {getStoryTypeDisplay(story.story_type || 'child')}
                      </span>
                      <span className={`px-2.5 py-1 text-xs font-medium rounded-full ${getStatusBadgeColor(story.status)}`}>
                        {getStatusDisplay(story.status)}
                      </span>
                      {story.parent_id && (
                        <span className="px-2.5 py-1 text-xs font-medium rounded-full bg-purple-100 text-purple-700 flex items-center gap-1">
                          <svg className="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
                          </svg>
                          Continuation
                        </span>
                      )}
                      {story.rating && (
                        <span className="px-2.5 py-1 text-xs font-medium rounded-full bg-yellow-100 text-yellow-700 flex items-center gap-1">
                          <StarIconSolid className="h-3 w-3" />
                          {story.rating}/10
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Story Metadata */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-4 border-t border-gray-100">
              <div className="space-y-2">
                <div className="flex items-center text-sm text-gray-600">
                  <GlobeAltIcon className="h-4 w-4 mr-2 text-gray-400" />
                  <span className="font-medium mr-2">Language:</span>
                  <span>{getLanguageDisplay(story.language)}</span>
                </div>
                {story.story_length && (
                  <div className="flex items-center text-sm text-gray-600">
                    <ClockIcon className="h-4 w-4 mr-2 text-gray-400" />
                    <span className="font-medium mr-2">Length:</span>
                    <span>{story.story_length} minutes</span>
                  </div>
                )}
                {story.model_used && (
                  <div className="flex items-center text-sm text-gray-600">
                    <SparklesIcon className="h-4 w-4 mr-2 text-gray-400" />
                    <span className="font-medium mr-2">Model:</span>
                    <span className="font-mono text-xs">{story.model_used}</span>
                  </div>
                )}
              </div>
              <div className="space-y-2">
                {story.child_name && (
                  <div className="flex items-center text-sm text-gray-600">
                    <UserIcon className="h-4 w-4 mr-2 text-gray-400" />
                    <span className="font-medium mr-2">Child:</span>
                    <span>{story.child_name}</span>
                    {story.child_age && (
                      <span className="text-gray-500 ml-1">({story.child_age} years)</span>
                    )}
                  </div>
                )}
                {story.hero_name && (
                  <div className="flex items-center text-sm text-gray-600">
                    <UserGroupIcon className="h-4 w-4 mr-2 text-gray-400" />
                    <span className="font-medium mr-2">Hero:</span>
                    <span>{story.hero_name}</span>
                    {story.hero_gender && (
                      <span className="text-gray-500 ml-1">({story.hero_gender})</span>
                    )}
                  </div>
                )}
                {story.moral && (
                  <div className="flex items-center text-sm text-gray-600">
                    <TagIcon className="h-4 w-4 mr-2 text-gray-400" />
                    <span className="font-medium mr-2">Moral:</span>
                    <span className="px-2 py-0.5 text-xs font-medium rounded-full bg-purple-100 text-purple-700">
                      {story.moral}
                    </span>
                  </div>
                )}
              </div>
            </div>
          </CardBody>
        </Card>

        {/* Parent Story Info */}
        {story.parent_id && (
          <Card className="mb-6">
            <CardHeader>
              <h3 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
                <svg className="h-5 w-5 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 17l-5-5m0 0l5-5m-5 5h12" />
                </svg>
                Previous Story
              </h3>
            </CardHeader>
            <CardBody>
              {parentStory ? (
                <div className="space-y-3">
                  <div>
                    <h4 className="font-semibold text-gray-900 mb-1">{parentStory.title}</h4>
                    <p className="text-sm text-gray-600 line-clamp-2">{parentStory.content.substring(0, 200)}...</p>
                  </div>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => navigate(`/stories/${parentStory.id}`)}
                  >
                    View Previous Story
                  </Button>
                </div>
              ) : (
                <p className="text-sm text-gray-600">
                  This story is a continuation of another story. Parent story information is loading...
                </p>
              )}
            </CardBody>
          </Card>
        )}

        {/* Story Content */}
        <Card className="mb-6">
          <CardHeader>
            <h3 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
              <DocumentTextIcon className="h-5 w-5 text-indigo-600" />
              Story Content
            </h3>
          </CardHeader>
          <CardBody>
            <div className="prose prose-indigo max-w-none">
              <div className="whitespace-pre-wrap text-gray-700 leading-relaxed font-serif text-base">
                {story.content}
              </div>
            </div>
          </CardBody>
        </Card>

        {/* Rating Section */}
        <Card className="mb-6">
          <CardHeader>
            <h3 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
              <StarIcon className="h-5 w-5 text-indigo-600" />
              Rate this Story
            </h3>
          </CardHeader>
          <CardBody>
            <p className="text-sm text-gray-600 mb-4">How much did you enjoy this story?</p>
            <div className="flex items-center gap-1">
              {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((star) => (
                <button
                  key={star}
                  type="button"
                  onClick={() => handleRatingChange(star)}
                  onMouseEnter={() => setHoveredStar(star)}
                  onMouseLeave={() => setHoveredStar(null)}
                  className="p-1 transition-transform hover:scale-110 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 rounded"
                  aria-label={`Rate ${star} out of 10`}
                >
                  {(hoveredStar ? star <= hoveredStar : star <= rating) ? (
                    <StarIconSolid className="h-8 w-8 text-yellow-400" />
                  ) : (
                    <StarIcon className="h-8 w-8 text-gray-300" />
                  )}
                </button>
              ))}
              <span className="ml-4 text-lg font-semibold text-gray-900">
                {rating > 0 ? `${rating}/10` : 'Not rated'}
              </span>
            </div>
          </CardBody>
        </Card>

        {/* Story Status Management */}
        <Card className="mb-6">
          <CardHeader>
            <h3 className="text-lg font-semibold text-gray-900">Story Status</h3>
          </CardHeader>
          <CardBody>
            <p className="text-sm text-gray-600 mb-4">Manage the status of this story</p>
            <div className="flex flex-wrap gap-2">
              <Button
                variant={story.status === 'new' ? 'primary' : 'outline'}
                size="sm"
                onClick={() => updateStoryStatus('new')}
                leftIcon={<DocumentTextIcon className="h-4 w-4" />}
                disabled={story.status === 'new'}
              >
                Mark as New
              </Button>
              <Button
                variant={story.status === 'read' ? 'primary' : 'outline'}
                size="sm"
                onClick={() => updateStoryStatus('read')}
                leftIcon={<CheckCircleIcon className="h-4 w-4" />}
                disabled={story.status === 'read'}
              >
                Mark as Read
              </Button>
              <Button
                variant={story.status === 'archived' ? 'primary' : 'outline'}
                size="sm"
                onClick={() => updateStoryStatus('archived')}
                leftIcon={<ArchiveBoxIcon className="h-4 w-4" />}
                disabled={story.status === 'archived'}
              >
                Archive
              </Button>
            </div>
          </CardBody>
        </Card>

        {/* Story Info Footer */}
        <Card>
          <CardBody>
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 text-sm text-gray-600">
              <div className="flex items-center gap-2">
                <CalendarIcon className="h-4 w-4 text-gray-400" />
                <span>
                  <span className="font-medium">Created:</span> {formatDate(story.created_at)}
                </span>
              </div>
              <div className="flex items-center gap-2">
                <CalendarIcon className="h-4 w-4 text-gray-400" />
                <span>
                  <span className="font-medium">Updated:</span> {formatDate(story.updated_at)}
                </span>
              </div>
            </div>
          </CardBody>
        </Card>

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row gap-3 mt-6">
          <Button
            onClick={() => navigate('/stories')}
            variant="outline"
            className="flex-1"
            leftIcon={<ArrowLeftIcon className="h-5 w-5" />}
          >
            Back to Stories
          </Button>
          {story.child_id && (
            <Button
              onClick={() => navigate(`/stories/generate?childId=${story.child_id}&parentId=${story.id}`)}
              variant="primary"
              className="flex-1"
              leftIcon={
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7l5 5m0 0l-5 5m5-5H6" />
                </svg>
              }
            >
              Continue This Story
            </Button>
          )}
          <Button
            onClick={() => navigate('/stories/generate')}
            variant="primary"
            className="flex-1"
            leftIcon={<SparklesIcon className="h-5 w-5" />}
          >
            Generate New Story
          </Button>
        </div>
      </div>
    </div>
  );
};
