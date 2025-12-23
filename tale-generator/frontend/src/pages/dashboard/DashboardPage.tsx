import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';
import { Card, CardBody } from '../../components/common/Card';
import { Button } from '../../components/common/Button';
import type { ChildProfile } from '../../types/models';
import { 
  UserGroupIcon, 
  BookOpenIcon, 
  HeartIcon,
  PlusIcon,
  SparklesIcon,
  DocumentTextIcon,
  UserPlusIcon,
  ArrowRightIcon,
} from '@heroicons/react/24/outline';

interface SubscriptionInfo {
  subscription: {
    plan: 'free' | 'starter' | 'normal' | 'premium';
    status: string;
  };
  limits: {
    child_profiles_limit: number | null;
    child_profiles_count: number;
  };
}

export const DashboardPage: React.FC = () => {
  const { user, session } = useAuth();
  const navigate = useNavigate();
  const [children, setChildren] = useState<ChildProfile[]>([]);
  const [childrenCount, setChildrenCount] = useState<number>(0);
  const [storiesCount, setStoriesCount] = useState<number>(0);
  const [favoritesCount, setFavoritesCount] = useState<number>(0);
  const [loading, setLoading] = useState<boolean>(true);
  const [subscriptionInfo, setSubscriptionInfo] = useState<SubscriptionInfo | null>(null);

  useEffect(() => {
    const fetchStats = async () => {
      if (!user) return;
      
      try {
        setLoading(true);
        
        // Fetch children list
        const { data: childrenData, error: childrenError } = await supabase
          .from('children')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', { ascending: false });
        
        if (childrenError) throw childrenError;
        
        setChildren(childrenData || []);
        setChildrenCount(childrenData?.length || 0);
        
        // Fetch stories count
        const { count: storiesCount, error: storiesError } = await supabase
          .from('stories')
          .select('*', { count: 'exact', head: true })
          .eq('user_id', user.id);
        
        if (storiesError) throw storiesError;
        
        // For favorites, we'll count stories with rating >= 8
        const { count: favoritesCount, error: favoritesError } = await supabase
          .from('stories')
          .select('*', { count: 'exact', head: true })
          .eq('user_id', user.id)
          .gte('rating', 8);
        
        if (favoritesError) throw favoritesError;
        
        setStoriesCount(storiesCount || 0);
        setFavoritesCount(favoritesCount || 0);
        
        // Fetch subscription info
        if (session?.access_token) {
          try {
            const response = await fetch('http://localhost:8000/api/v1/users/subscription', {
              headers: {
                'Authorization': `Bearer ${session.access_token}`,
              },
            });
            
            if (response.ok) {
              const data = await response.json();
              setSubscriptionInfo({
                subscription: data.subscription,
                limits: data.limits,
              });
            }
          } catch (err) {
            console.error('Failed to fetch subscription:', err);
          }
        }
      } catch (error) {
        console.error('Error fetching stats:', error);
      } finally {
        setLoading(false);
      }
    };
    
    fetchStats();
  }, [user, session]);

  const userName = user?.user_metadata?.name || user?.email?.split('@')[0] || 'there';

  // Get greeting based on time of day
  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  };

  // Check if user can add more children
  const canAddChild = subscriptionInfo 
    ? subscriptionInfo.limits.child_profiles_limit === null 
      || subscriptionInfo.limits.child_profiles_count < subscriptionInfo.limits.child_profiles_limit
    : true;

  const featureCards = [
    {
      title: 'Generate Story',
      description: 'Create personalized stories',
      icon: SparklesIcon,
      color: 'from-blue-500 to-blue-600',
      onClick: () => navigate('/stories/generate'),
    },
    {
      title: 'My Stories',
      description: 'Browse your stories',
      icon: BookOpenIcon,
      color: 'from-purple-500 to-purple-600',
      onClick: () => navigate('/stories'),
    },
    {
      title: 'Children',
      description: 'Manage profiles',
      icon: UserGroupIcon,
      color: 'from-green-500 to-green-600',
      onClick: () => navigate('/children'),
    },
    {
      title: 'Heroes',
      description: 'Create characters',
      icon: SparklesIcon,
      color: 'from-orange-500 to-orange-600',
      onClick: () => navigate('/heroes'),
    },
    {
      title: 'Favorites',
      description: 'Your favorite stories',
      icon: HeartIcon,
      color: 'from-pink-500 to-pink-600',
      onClick: () => navigate('/stories'),
    },
    {
      title: 'Subscription',
      description: 'Manage plan',
      icon: DocumentTextIcon,
      color: 'from-indigo-500 to-indigo-600',
      onClick: () => navigate('/subscription'),
    },
  ];

  return (
    <div className="min-h-screen bg-[#F5F5F5]">
      <div className="px-8 py-8">
        {/* Header Section */}
        <div className="mb-8">
          <p className="text-sm font-medium text-neutral-500 mb-1">My Workspace</p>
          <h1 className="text-4xl font-bold text-neutral-900 mb-2">
            {getGreeting()}, {userName}
          </h1>
        </div>

        {/* Feature Cards Grid */}
        <div className="mb-12">
          <h2 className="text-xl font-semibold text-neutral-900 mb-6">My Workspace</h2>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
            {featureCards.map((feature) => {
              const Icon = feature.icon;
              return (
                <button
                  key={feature.title}
                  onClick={feature.onClick}
                  className="bg-white rounded-xl p-6 shadow-sm hover:shadow-md transition-all duration-200 hover:-translate-y-0.5 flex flex-col items-center text-center group"
                >
                  <div className={`w-12 h-12 rounded-lg bg-gradient-to-br ${feature.color} flex items-center justify-center mb-3 group-hover:scale-110 transition-transform`}>
                    <Icon className="h-6 w-6 text-white" />
                  </div>
                  <h3 className="text-sm font-semibold text-neutral-900 mb-1">{feature.title}</h3>
                  <p className="text-xs text-neutral-500">{feature.description}</p>
                </button>
              );
            })}
          </div>
        </div>

        {/* Stats Section */}
        <div className="mb-12">
          <h2 className="text-xl font-semibold text-neutral-900 mb-6">Overview</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Children Profiles Card */}
            <Card hover className="bg-white">
              <CardBody className="p-6">
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <p className="text-sm font-medium text-neutral-600 mb-1">Children Profiles</p>
                    <p className="text-3xl font-semibold text-neutral-900">{loading ? '...' : childrenCount}</p>
                  </div>
                  <div className="p-3 rounded-lg bg-primary-100">
                    <UserGroupIcon className="h-6 w-6 text-primary-600" />
                  </div>
                </div>
                
                {/* Children circles */}
                <div className="flex flex-wrap gap-3 items-center">
                  {loading ? (
                    <div className="text-sm text-neutral-500">Loading...</div>
                  ) : children.length > 0 ? (
                    <>
                      {children.slice(0, 4).map((child) => (
                        <button
                          key={child.id}
                          type="button"
                          onClick={() => navigate(`/children/${child.id}`)}
                          className="flex flex-col items-center transition-all opacity-80 hover:opacity-100 hover:scale-105"
                        >
                          <div className="w-12 h-12 rounded-full border-2 overflow-hidden bg-gradient-to-br from-primary-400 to-primary-600 flex items-center justify-center border-neutral-200 hover:border-primary-300 transition-colors">
                            <span className="text-white text-sm font-bold">
                              {child.name.charAt(0).toUpperCase()}
                            </span>
                          </div>
                          <span className="mt-1.5 text-xs font-medium text-neutral-700 max-w-[48px] truncate">
                            {child.name}
                          </span>
                        </button>
                      ))}
                      {canAddChild && (
                        <button
                          type="button"
                          onClick={() => navigate('/children/add')}
                          className="flex flex-col items-center transition-all opacity-70 hover:opacity-100 hover:scale-105"
                        >
                          <div className="w-12 h-12 rounded-full border-2 border-dashed border-neutral-300 hover:border-primary-400 flex items-center justify-center bg-neutral-50 hover:bg-primary-50 transition-colors">
                            <PlusIcon className="h-5 w-5 text-neutral-400 hover:text-primary-500" />
                          </div>
                          <span className="mt-1.5 text-xs font-medium text-neutral-500">
                            Add
                          </span>
                        </button>
                      )}
                    </>
                  ) : (
                    <div className="flex items-center gap-3">
                      <div className="text-sm text-neutral-500">No children yet</div>
                      {canAddChild && (
                        <button
                          type="button"
                          onClick={() => navigate('/children/add')}
                          className="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-primary-600 hover:text-primary-700 border border-primary-300 rounded-lg hover:bg-primary-50 transition-colors"
                        >
                          <PlusIcon className="h-4 w-4" />
                          Add Child
                        </button>
                      )}
                    </div>
                  )}
                </div>
              </CardBody>
            </Card>

            {/* Stories Created Card */}
            <Card hover className="bg-white">
              <CardBody className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-neutral-600 mb-1">Stories Created</p>
                    <p className="text-3xl font-semibold text-neutral-900">{loading ? '...' : storiesCount}</p>
                  </div>
                  <div className="p-3 rounded-lg bg-secondary-100">
                    <BookOpenIcon className="h-6 w-6 text-secondary-600" />
                  </div>
                </div>
              </CardBody>
            </Card>

            {/* Favorites Card */}
            <Card hover className="bg-white">
              <CardBody className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-neutral-600 mb-1">Favorites</p>
                    <p className="text-3xl font-semibold text-neutral-900">{loading ? '...' : favoritesCount}</p>
                  </div>
                  <div className="p-3 rounded-lg bg-warm-100">
                    <HeartIcon className="h-6 w-6 text-warm-600" />
                  </div>
                </div>
              </CardBody>
            </Card>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="mb-8">
          <h2 className="text-xl font-semibold text-neutral-900 mb-6">Quick Actions</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Card hover className="bg-white cursor-pointer" onClick={() => navigate('/children/add')}>
              <CardBody className="p-6">
                <div className="flex items-start space-x-4">
                  <div className="w-12 h-12 rounded-lg bg-primary-100 flex items-center justify-center flex-shrink-0">
                    <UserPlusIcon className="h-6 w-6 text-primary-600" />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-lg font-semibold text-neutral-900 mb-1">Add Child Profile</h3>
                    <p className="text-sm text-neutral-600 mb-4">
                      Create a new profile for your child to personalize their stories
                    </p>
                    <div className="flex items-center text-sm font-medium text-primary-600">
                      <span>Get started</span>
                      <ArrowRightIcon className="h-4 w-4 ml-1" />
                    </div>
                  </div>
                </div>
              </CardBody>
            </Card>

            <Card hover className="bg-white cursor-pointer" onClick={() => navigate('/stories/generate')}>
              <CardBody className="p-6">
                <div className="flex items-start space-x-4">
                  <div className="w-12 h-12 rounded-lg bg-secondary-100 flex items-center justify-center flex-shrink-0">
                    <SparklesIcon className="h-6 w-6 text-secondary-600" />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-lg font-semibold text-neutral-900 mb-1">Generate Story</h3>
                    <p className="text-sm text-neutral-600 mb-4">
                      Create a personalized tale for your child in minutes
                    </p>
                    <div className="flex items-center text-sm font-medium text-secondary-600">
                      <span>Create story</span>
                      <ArrowRightIcon className="h-4 w-4 ml-1" />
                    </div>
                  </div>
                </div>
              </CardBody>
            </Card>
          </div>
        </div>

        {/* Getting Started CTA */}
        {childrenCount === 0 && (
          <Card variant="gradient" className="bg-gradient-to-br from-primary-50 to-secondary-50">
            <CardBody className="p-8">
              <div className="flex flex-col md:flex-row items-center justify-between gap-6">
                <div className="flex-1">
                  <h3 className="text-xl font-semibold text-neutral-900 mb-2">
                    Ready to get started?
                  </h3>
                  <p className="text-neutral-600">
                    Add your first child profile to begin creating personalized stories tailored just for them.
                  </p>
                </div>
                <Button
                  onClick={() => navigate('/children/add')}
                  variant="primary"
                  size="lg"
                >
                  Add Your First Child
                </Button>
              </div>
            </CardBody>
          </Card>
        )}
      </div>
    </div>
  );
};
