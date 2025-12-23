import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';
import { Button } from '../../components/common/Button';
import { Input } from '../../components/common/Input';
import { Alert } from '../../components/common/Alert';

interface HeroForm {
  name: string;
  gender: string;
  appearance: string;
  personalityTraits: string;
  interests: string;
  strengths: string;
  language: string;
}

export const CreateHeroPage: React.FC = () => {
  const { user, signOut } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [formData, setFormData] = useState<HeroForm>({
    name: '',
    gender: '',
    appearance: '',
    personalityTraits: '',
    interests: '',
    strengths: '',
    language: 'en'
  });

  const handleSignOut = async () => {
    try {
      await signOut();
      navigate('/login');
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!user) {
      setError('You must be logged in to create a hero');
      return;
    }

    try {
      setLoading(true);
      setError(null);
      setSuccess(null);

      // Validate required fields
      if (!formData.name.trim()) {
        throw new Error('Hero name is required');
      }
      
      if (!formData.gender.trim()) {
        throw new Error('Hero gender is required');
      }
      
      if (!formData.appearance.trim()) {
        throw new Error('Hero appearance is required');
      }

      // Prepare hero data
      const heroData = {
        name: formData.name.trim(),
        gender: formData.gender.trim(),
        appearance: formData.appearance.trim(),
        personality_traits: formData.personalityTraits
          .split(',')
          .map(trait => trait.trim())
          .filter(trait => trait.length > 0),
        interests: formData.interests
          .split(',')
          .map(interest => interest.trim())
          .filter(interest => interest.length > 0),
        strengths: formData.strengths
          .split(',')
          .map(strength => strength.trim())
          .filter(strength => strength.length > 0),
        language: formData.language,
        user_id: user.id  // Set the current user as the owner
      };

      // Insert hero into database
      const { data, error } = await supabase
        .from('heroes')
        .insert([heroData])
        .select();

      if (error) {
        throw new Error(error.message);
      }

      if (data && data.length > 0) {
        setSuccess('Hero created successfully!');
        // Reset form
        setFormData({
          name: '',
          gender: '',
          appearance: '',
          personalityTraits: '',
          interests: '',
          strengths: '',
          language: 'en'
        });
        // Navigate to heroes list after a short delay
        setTimeout(() => {
          navigate('/heroes');
        }, 2000);
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to create hero';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-light min-vh-100">
      <div className="container my-4">
        <div className="d-flex justify-content-between align-items-center mb-4">
          <h1 className="h3 mb-0">Create New Hero</h1>
          <Button onClick={() => navigate('/heroes')} variant="outline">
            Back to Heroes
          </Button>
        </div>

        {error && <Alert type="error" message={error} onClose={() => setError(null)} />}
        {success && <Alert type="success" message={success} onClose={() => setSuccess(null)} />}

        <div className="card">
          <div className="card-body">
            <form onSubmit={handleSubmit}>
              <div className="mb-3">
                <label htmlFor="name" className="form-label">Hero Name *</label>
                <Input
                  type="text"
                  id="name"
                  name="name"
                  value={formData.name}
                  onChange={handleChange}
                  placeholder="Enter hero name"
                  required
                />
              </div>

              <div className="mb-3">
                <label htmlFor="gender" className="form-label">Gender *</label>
                <select
                  id="gender"
                  name="gender"
                  className="form-select"
                  value={formData.gender}
                  onChange={handleChange}
                  required
                >
                  <option value="">Select gender</option>
                  <option value="male">Male</option>
                  <option value="female">Female</option>
                  <option value="other">Other</option>
                </select>
              </div>

              <div className="mb-3">
                <label htmlFor="appearance" className="form-label">Appearance *</label>
                <textarea
                  id="appearance"
                  name="appearance"
                  className="form-control"
                  rows={3}
                  value={formData.appearance}
                  onChange={handleChange}
                  placeholder="Describe the hero's physical appearance"
                  required
                />
              </div>

              <div className="mb-3">
                <label htmlFor="personalityTraits" className="form-label">Personality Traits</label>
                <Input
                  type="text"
                  id="personalityTraits"
                  name="personalityTraits"
                  value={formData.personalityTraits}
                  onChange={handleChange}
                  placeholder="Comma-separated traits (e.g., brave, curious, kind)"
                />
                <div className="form-text">Enter traits separated by commas</div>
              </div>

              <div className="mb-3">
                <label htmlFor="interests" className="form-label">Interests</label>
                <Input
                  type="text"
                  id="interests"
                  name="interests"
                  value={formData.interests}
                  onChange={handleChange}
                  placeholder="Comma-separated interests (e.g., music, sports, reading)"
                />
                <div className="form-text">Enter interests separated by commas</div>
              </div>

              <div className="mb-3">
                <label htmlFor="strengths" className="form-label">Strengths/Powers</label>
                <Input
                  type="text"
                  id="strengths"
                  name="strengths"
                  value={formData.strengths}
                  onChange={handleChange}
                  placeholder="Comma-separated strengths (e.g., super speed, telekinesis, wisdom)"
                />
                <div className="form-text">Enter strengths separated by commas</div>
              </div>

              <div className="mb-3">
                <label htmlFor="language" className="form-label">Language</label>
                <select
                  id="language"
                  name="language"
                  className="form-select"
                  value={formData.language}
                  onChange={handleChange}
                >
                  <option value="en">English</option>
                  <option value="ru">Русский</option>
                </select>
              </div>

              <div className="d-grid gap-2 d-md-flex justify-content-md-end">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => navigate('/heroes')}
                  disabled={loading}
                >
                  Cancel
                </Button>
                <Button
                  type="submit"
                  variant="primary"
                  loading={loading}
                  disabled={loading}
                >
                  Create Hero
                </Button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
};