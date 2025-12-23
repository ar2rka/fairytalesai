import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';
import { Button } from '../../components/common/Button';
import { Input } from '../../components/common/Input';
import { Alert } from '../../components/common/Alert';
import { Card, CardBody, CardHeader } from '../../components/common/Card';
import { XMarkIcon, PlusIcon } from '@heroicons/react/24/outline';
import { AGE_CATEGORIES, type AgeCategory } from '../../utils/ageCategories';

interface ChildFormData {
  name: string;
  ageCategory: AgeCategory;
  gender: 'male' | 'female';
  interests: string[];
}

export const AddChildPage: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [interestInput, setInterestInput] = useState('');
  
  const [formData, setFormData] = useState<ChildFormData>({
    name: '',
    ageCategory: '3-5',
    gender: 'male',
    interests: []
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleInterestChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setInterestInput(e.target.value);
  };

  const addInterest = () => {
    if (interestInput.trim() && !formData.interests.includes(interestInput.trim())) {
      setFormData(prev => ({
        ...prev,
        interests: [...prev.interests, interestInput.trim()]
      }));
      setInterestInput('');
    }
  };

  const removeInterest = (interest: string) => {
    setFormData(prev => ({
      ...prev,
      interests: prev.interests.filter(i => i !== interest)
    }));
  };

  const validateForm = (): boolean => {
    if (!formData.name.trim()) {
      setError('Name is required');
      return false;
    }
    
    if (formData.name.trim().length < 2) {
      setError('Name must be at least 2 characters');
      return false;
    }
    
    if (formData.name.trim().length > 50) {
      setError('Name must not exceed 50 characters');
      return false;
    }
    
    if (formData.interests.length === 0) {
      setError('Please add at least one interest');
      return false;
    }
    
    return true;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }
    
    if (!user) {
      setError('You must be logged in to add a child');
      return;
    }
    
    try {
      setError(null);
      setLoading(true);
      
      // Insert child into database
      const { error: insertError } = await supabase
        .from('children')
        .insert([
          {
            name: formData.name.trim(),
            age_category: formData.ageCategory,
            gender: formData.gender,
            interests: formData.interests,
            user_id: user.id,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          }
        ]);
      
      if (insertError) {
        throw new Error(insertError.message);
      }
      
      setSuccess(true);
      
      // Redirect to dashboard after successful creation
      setTimeout(() => {
        navigate('/');
      }, 2000);
      
    } catch (err) {
      const message = err instanceof Error ? err.message : 'An error occurred while adding the child';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F5F5F5]">
      <div className="max-w-2xl mx-auto px-8 py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-semibold text-neutral-900 mb-2">Add Child Profile</h1>
          <p className="text-neutral-600">Create a profile for your child to generate personalized stories</p>
        </div>

        <Card>
          <CardHeader>
            <h2 className="text-lg font-semibold text-neutral-900">Child Information</h2>
          </CardHeader>
          <CardBody>
            {error && (
              <div className="mb-6">
                <Alert type="error" message={error} onClose={() => setError(null)} />
              </div>
            )}
            {success && (
              <div className="mb-6">
                <Alert
                  type="success"
                  message="Child profile created successfully! Redirecting to dashboard..."
                />
              </div>
            )}
            
            <form className="space-y-6" onSubmit={handleSubmit}>
              <Input
                label="Child's Name"
                type="text"
                name="name"
                value={formData.name}
                onChange={handleChange}
                required
                placeholder="Enter child's name"
              />
              
              <div>
                <label htmlFor="ageCategory" className="block text-sm font-medium text-gray-700 mb-1.5">
                  Возрастная категория
                </label>
                <select
                  id="ageCategory"
                  name="ageCategory"
                  value={formData.ageCategory}
                  onChange={handleChange}
                  className="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 bg-white text-gray-900"
                  required
                >
                  {AGE_CATEGORIES.map((category) => (
                    <option key={category.value} value={category.value}>
                      {category.label}
                    </option>
                  ))}
                </select>
              </div>
              
              <div>
                <label htmlFor="gender" className="block text-sm font-medium text-gray-700 mb-1.5">
                  Gender
                </label>
                <select
                  id="gender"
                  name="gender"
                  value={formData.gender}
                  onChange={handleChange}
                  className="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 bg-white text-gray-900"
                >
                  <option value="male">Male</option>
                  <option value="female">Female</option>
                </select>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  Interests
                </label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={interestInput}
                    onChange={handleInterestChange}
                    placeholder="Enter an interest"
                    className="flex-1 px-3 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 bg-white text-gray-900"
                    onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addInterest())}
                  />
                  <Button
                    type="button"
                    onClick={addInterest}
                    variant="primary"
                    leftIcon={<PlusIcon className="h-5 w-5" />}
                  >
                    Add
                  </Button>
                </div>
                <p className="mt-1.5 text-sm text-gray-500">
                  Press Enter or click Add to include an interest
                </p>
                
                {/* Display added interests */}
                {formData.interests.length > 0 && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {formData.interests.map((interest, index) => (
                      <span
                        key={index}
                        className="inline-flex items-center px-3 py-1.5 rounded-full text-sm font-medium bg-indigo-100 text-indigo-700"
                      >
                        {interest}
                        <button
                          type="button"
                          onClick={() => removeInterest(interest)}
                          className="ml-2 inline-flex items-center justify-center w-4 h-4 rounded-full text-indigo-400 hover:bg-indigo-200 hover:text-indigo-600 focus:outline-none transition-colors"
                        >
                          <XMarkIcon className="h-3 w-3" />
                        </button>
                      </span>
                    ))}
                  </div>
                )}
              </div>
              
              <div className="flex gap-4 pt-4">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => navigate('/')}
                  disabled={loading}
                  fullWidth
                >
                  Cancel
                </Button>
                <Button
                  type="submit"
                  variant="primary"
                  loading={loading}
                  disabled={success}
                  fullWidth
                >
                  Add Child
                </Button>
              </div>
            </form>
          </CardBody>
        </Card>
      </div>
    </div>
  );
};
