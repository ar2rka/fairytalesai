import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';
import { Button } from '../../components/common/Button';
import { Alert } from '../../components/common/Alert';
import { Card, CardBody } from '../../components/common/Card';
import { 
  MagnifyingGlassIcon, 
  FunnelIcon,
  SparklesIcon,
  BookOpenIcon
} from '@heroicons/react/24/outline';
import type { Story } from '../../types/models';

export const StoriesListPage: React.FC = () => {
  const { user, signOut } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [stories, setStories] = useState<Story[]>([]);
  const [filteredStories, setFilteredStories] = useState<Story[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [languageFilter, setLanguageFilter] = useState('');
  const [ratingFilter, setRatingFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [storyTypeFilter, setStoryTypeFilter] = useState('');

  useEffect(() => {
    fetchStories();
  }, [user]);

  const handleSignOut = async () => {
    try {
      await signOut();
      navigate('/login');
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  const fetchStories = async () => {
    if (!user) return;

    try {
      setLoading(true);
      setError(null);
      
      // Fetch stories directly from Supabase for the authenticated user
      const { data, error } = await supabase
        .from('stories')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });
      
      if (error) {
        throw new Error(error.message);
      }
      
      setStories(data || []);
      setFilteredStories(data || []);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch stories';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // Filter stories based on search term, language, rating, status, and story type
    let filtered = [...stories];
    
    // Apply search filter
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      filtered = filtered.filter(story => 
        story.title.toLowerCase().includes(term) ||
        (story.child_name && story.child_name.toLowerCase().includes(term)) ||
        (story.hero_name && story.hero_name.toLowerCase().includes(term)) ||
        story.moral.toLowerCase().includes(term)
      );
    }
    
    // Apply language filter
    if (languageFilter) {
      filtered = filtered.filter(story => story.language === languageFilter);
    }
    
    // Apply rating filter
    if (ratingFilter) {
      filtered = filtered.filter(story => {
        if (!story.rating) return false;
        if (ratingFilter === '1-3') return story.rating >= 1 && story.rating <= 3;
        if (ratingFilter === '4-7') return story.rating >= 4 && story.rating <= 7;
        if (ratingFilter === '8-10') return story.rating >= 8 && story.rating <= 10;
        return true;
      });
    }
    
    // Apply status filter
    if (statusFilter) {
      filtered = filtered.filter(story => story.status === statusFilter);
    }
    
    // Apply story type filter
    if (storyTypeFilter) {
      filtered = filtered.filter(story => (story.story_type || 'child') === storyTypeFilter);
    }
    
    setFilteredStories(filtered);
  }, [searchTerm, languageFilter, ratingFilter, statusFilter, storyTypeFilter, stories]);

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

  const getStatusDisplay = (status: string) => {
    switch (status) {
      case 'new': return 'New';
      case 'read': return 'Read';
      case 'archived': return 'Archived';
      default: return status;
    }
  };

  const getStatusBadgeClass = (status: string) => {
    switch (status) {
      case 'new': return 'bg-indigo-50 text-indigo-700 border-indigo-200';
      case 'read': return 'bg-green-50 text-green-700 border-green-200';
      case 'archived': return 'bg-neutral-100 text-neutral-700 border-neutral-200';
      default: return 'bg-neutral-50 text-neutral-700 border-neutral-200';
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

  const getStoryTypeBadgeClass = (type: string) => {
    switch (type) {
      case 'child': return 'bg-blue-50 text-blue-700 border-blue-200';
      case 'hero': return 'bg-amber-50 text-amber-700 border-amber-200';
      case 'combined': return 'bg-green-50 text-green-700 border-green-200';
      default: return 'bg-blue-50 text-blue-700 border-blue-200';
    }
  };

  return (
    <div className="min-h-screen bg-neutral-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-6 gap-4">
          <div>
            <h1 className="text-3xl font-semibold text-neutral-900 mb-2">My Stories</h1>
            <p className="text-neutral-600">
              Browse and manage all your generated stories
            </p>
          </div>
          <Button 
            onClick={() => navigate('/stories/generate')} 
            variant="gradient"
            leftIcon={<SparklesIcon className="h-5 w-5" />}
          >
            Generate New Story
          </Button>
        </div>

        {error && (
          <div className="mb-6">
            <Alert type="error" message={error} onClose={() => setError(null)} />
          </div>
        )}

        <Card className="mb-6">
          <CardBody>
            <div className="space-y-4">
              <div className="relative">
                <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-neutral-400" />
                <input
                  type="text"
                  className="w-full pl-10 pr-4 py-2.5 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-colors"
                  placeholder="Search stories by title, child, hero, or moral..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>
              
              <div className="flex flex-wrap gap-3">
                <div className="flex items-center gap-2 text-sm text-neutral-600">
                  <FunnelIcon className="h-4 w-4" />
                  <span className="font-medium">Filters:</span>
                </div>
                <select 
                  className="flex-1 min-w-[140px] px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none bg-white text-sm"
                  value={storyTypeFilter}
                  onChange={(e) => setStoryTypeFilter(e.target.value)}
                >
                  <option value="">All Types</option>
                  <option value="child">Child Stories</option>
                  <option value="hero">Hero Stories</option>
                  <option value="combined">Combined</option>
                </select>
                <select 
                  className="flex-1 min-w-[140px] px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none bg-white text-sm"
                  value={languageFilter}
                  onChange={(e) => setLanguageFilter(e.target.value)}
                >
                  <option value="">All Languages</option>
                  <option value="en">English</option>
                  <option value="ru">Русский</option>
                </select>
                <select 
                  className="flex-1 min-w-[140px] px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none bg-white text-sm"
                  value={ratingFilter}
                  onChange={(e) => setRatingFilter(e.target.value)}
                >
                  <option value="">All Ratings</option>
                  <option value="1-3">1-3 Stars</option>
                  <option value="4-7">4-7 Stars</option>
                  <option value="8-10">8-10 Stars</option>
                </select>
                <select 
                  className="flex-1 min-w-[140px] px-3 py-2 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none bg-white text-sm"
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                >
                  <option value="">All Statuses</option>
                  <option value="new">New</option>
                  <option value="read">Read</option>
                  <option value="archived">Archived</option>
                </select>
              </div>
            </div>
          </CardBody>
        </Card>

        {loading ? (
          <div className="flex justify-center items-center" style={{ height: '300px' }}>
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
          </div>
        ) : filteredStories.length === 0 ? (
          <Card>
            <CardBody className="text-center py-12">
              <BookOpenIcon className="h-16 w-16 text-neutral-300 mx-auto mb-4" />
              <h3 className="text-xl font-semibold text-neutral-900 mb-2">No stories found</h3>
              <p className="text-neutral-600 mb-6 max-w-md mx-auto">
                {stories.length === 0 
                  ? 'You haven\'t generated any stories yet. Create your first personalized tale!' 
                  : 'No stories match your search criteria. Try adjusting your filters.'}
              </p>
              <Button 
                onClick={() => navigate('/stories/generate')} 
                variant="gradient"
                leftIcon={<SparklesIcon className="h-5 w-5" />}
              >
                Generate Your First Story
              </Button>
            </CardBody>
          </Card>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredStories.map((story) => (
              <Card key={story.id} hover className="flex flex-col">
                <CardBody className="flex-1 flex flex-col">
                  <div className="flex justify-between items-start mb-3">
                    <h5 className="text-lg font-semibold text-neutral-900 mb-0 flex-1 pr-2 line-clamp-2">
                      {story.title}
                    </h5>
                    <div className="flex flex-col items-end gap-1 flex-shrink-0">
                      {story.rating && (
                        <span className="px-2 py-1 text-xs font-semibold rounded-full bg-amber-100 text-amber-800 border border-amber-200">
                          {story.rating}/10
                        </span>
                      )}
                      <span className={`px-2 py-1 text-xs font-semibold rounded-full border ${getStatusBadgeClass(story.status)}`}>
                        {getStatusDisplay(story.status)}
                      </span>
                    </div>
                  </div>
                  
                  <div className="mb-3">
                    <span className={`inline-block px-2.5 py-1 text-xs font-semibold rounded-full border ${getStoryTypeBadgeClass(story.story_type || 'child')}`}>
                      {getStoryTypeDisplay(story.story_type || 'child')}
                    </span>
                  </div>
                  
                  <div className="mb-3 flex flex-wrap items-center gap-2 text-sm text-neutral-600">
                    <span className="flex items-center gap-1">
                      <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129" />
                      </svg>
                      {getLanguageDisplay(story.language)}
                    </span>
                    {story.child_name && (
                      <>
                        <span>•</span>
                        <span>{story.child_name}</span>
                      </>
                    )}
                    {story.hero_name && (
                      <>
                        <span>•</span>
                        <span className="flex items-center gap-1">
                          <span>🦸</span>
                          {story.hero_name}
                        </span>
                      </>
                    )}
                    {story.story_length && (
                      <>
                        <span>•</span>
                        <span>{story.story_length} min</span>
                      </>
                    )}
                  </div>
                  
                  <div className="mb-3">
                    <span className="inline-block px-2.5 py-1 text-xs font-medium rounded-lg bg-indigo-50 text-indigo-700 border border-indigo-200">
                      {story.moral}
                    </span>
                  </div>
                  
                  <div className="text-xs text-neutral-500 mb-4 mt-auto">
                    Created on {formatDate(story.created_at)}
                  </div>
                  
                  <Button
                    variant="outline"
                    onClick={() => navigate(`/stories/${story.id}`)}
                    size="sm"
                    fullWidth
                  >
                    View Story
                  </Button>
                </CardBody>
              </Card>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};