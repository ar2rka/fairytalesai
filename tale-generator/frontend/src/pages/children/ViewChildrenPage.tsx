import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';
import { Button } from '../../components/common/Button';
import { Alert } from '../../components/common/Alert';
import { Card, CardBody } from '../../components/common/Card';
import type { ChildProfile } from '../../types/models';
import { UserGroupIcon, PlusIcon, PencilIcon, TrashIcon, EyeIcon } from '@heroicons/react/24/outline';
import { getAgeCategoryDisplay } from '../../utils/ageCategories';

export const ViewChildrenPage: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [children, setChildren] = useState<ChildProfile[]>([]);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  useEffect(() => {
    fetchChildren();
  }, [user]);

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
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch children';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (childId: string) => {
    if (!user) return;

    if (!window.confirm('Are you sure you want to delete this child profile? This action cannot be undone.')) {
      return;
    }

    try {
      setDeletingId(childId);
      
      const { error: deleteError } = await supabase
        .from('children')
        .delete()
        .eq('id', childId)
        .eq('user_id', user.id);

      if (deleteError) {
        throw new Error(deleteError.message);
      }

      // Remove the child from the local state
      setChildren(prev => prev.filter(child => child.id !== childId));
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to delete child';
      setError(message);
    } finally {
      setDeletingId(null);
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
            <h1 className="text-3xl font-semibold text-neutral-900 mb-2">Children Profiles</h1>
            <p className="text-neutral-600">Manage your children's profiles and preferences</p>
          </div>
          <Button 
            onClick={() => navigate('/children/add')} 
            variant="primary"
            leftIcon={<PlusIcon className="h-5 w-5" />}
          >
            Add New Child
          </Button>
        </div>

        {error && (
          <div className="mb-6">
            <Alert type="error" message={error} onClose={() => setError(null)} />
          </div>
        )}

        {loading ? (
          <div className="flex justify-center items-center" style={{ height: '300px' }}>
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
          </div>
        ) : children.length === 0 ? (
          <Card>
            <CardBody className="text-center py-12">
              <div className="w-16 h-16 mx-auto mb-4 bg-primary-100 rounded-full flex items-center justify-center">
                <UserGroupIcon className="h-8 w-8 text-primary-600" />
              </div>
              <h3 className="text-xl font-semibold text-neutral-900 mb-2">No children profiles found</h3>
              <p className="text-neutral-600 mb-6">Get started by adding a new child profile.</p>
              <Button 
                onClick={() => navigate('/children/add')} 
                variant="primary"
                leftIcon={<PlusIcon className="h-5 w-5" />}
              >
                Add Your First Child
              </Button>
            </CardBody>
          </Card>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {children.map((child) => (
              <Card 
                key={child.id} 
                hover 
                className="flex flex-col cursor-pointer"
                onClick={() => navigate(`/children/${child.id}`)}
              >
                <CardBody className="flex-1 p-6">
                  <div className="flex justify-between items-start mb-4">
                    <div className="flex-1">
                      <h3 className="text-lg font-semibold text-neutral-900 mb-1">{child.name}</h3>
                      <div className="flex items-center text-sm text-neutral-600 space-x-2">
                        <span>{getAgeCategoryDisplay(child.age_category)}</span>
                        <span>•</span>
                        <span className="capitalize">{child.gender}</span>
                      </div>
                    </div>
                    <span className="px-2.5 py-1 text-xs font-medium rounded-full bg-primary-100 text-primary-700 capitalize">
                      {child.gender}
                    </span>
                  </div>

                  <div className="mb-4">
                    <h4 className="text-xs font-medium text-neutral-500 mb-2 uppercase tracking-wide">Interests</h4>
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
                        <span className="text-sm text-neutral-400">No interests specified</span>
                      )}
                    </div>
                  </div>

                  <div className="text-xs text-neutral-500 pt-4 border-t border-neutral-100">
                    Added on {formatDate(child.created_at)}
                  </div>
                </CardBody>
                
                <div className="px-6 py-4 border-t border-neutral-100 bg-neutral-50/50">
                  <div className="flex gap-2">
                    <Button
                      variant="primary"
                      onClick={(e) => {
                        e.stopPropagation();
                        navigate(`/children/${child.id}`);
                      }}
                      size="sm"
                      fullWidth
                      leftIcon={<EyeIcon className="h-4 w-4" />}
                    >
                      View
                    </Button>
                    <Button
                      variant="outline"
                      onClick={(e) => {
                        e.stopPropagation();
                        navigate(`/children/edit/${child.id}`);
                      }}
                      size="sm"
                      fullWidth
                      leftIcon={<PencilIcon className="h-4 w-4" />}
                    >
                      Edit
                    </Button>
                    <Button
                      variant="danger"
                      onClick={(e) => {
                        e.stopPropagation();
                        handleDelete(child.id);
                      }}
                      loading={deletingId === child.id}
                      size="sm"
                      fullWidth
                      leftIcon={<TrashIcon className="h-4 w-4" />}
                    >
                      Delete
                    </Button>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
