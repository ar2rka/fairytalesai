import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';
import { Button } from '../../components/common/Button';
import { Input } from '../../components/common/Input';
import { Alert } from '../../components/common/Alert';
import type { Hero } from '../../types/models';

interface HeroForm {
  name: string;
  gender: string;
  appearance: string;
  personalityTraits: string;
  interests: string;
  strengths: string;
  language: string;
}

export const EditHeroPage: React.FC = () => {
  const { user, signOut } = useAuth();
  const { heroId } = useParams<{ heroId: string }>();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [hero, setHero] = useState<Hero | null>(null);
  const [formData, setFormData] = useState<HeroForm>({
    name: '',
    gender: '',
    appearance: '',
    personalityTraits: '',
    interests: '',
    strengths: '',
    language: 'en'
  });

  useEffect(() => {
    if (heroId) {
      fetchHero(heroId);
    }
  }, [heroId]);

  const handleSignOut = async () => {
    try {
      await signOut();
      navigate('/login');
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  const fetchHero = async (id: string) => {
    try {
      setLoading(true);
      setError(null);
      
      // Fetch hero directly from Supabase
      const { data, error } = await supabase
        .from('heroes')
        .select('*')
        .eq('id', id)
//        .eq('user_id', user?.id)
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
      
      // Check if user owns this hero
      if (data.user_id !== user?.id) {
        throw new Error('You do not have permission to edit this hero');
      }
      
      setHero(data);
      
      // Populate form with hero data
      setFormData({
        name: data.name,
        gender: data.gender,
        appearance: data.appearance,
        personalityTraits: data.personality_traits.join(', '),
        interests: data.interests.join(', '),
        strengths: data.strengths.join(', '),
        language: data.language
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch hero';
      setError(message);
    } finally {
      setLoading(false);
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
    
    if (!user || !hero) {
      setError('You must be logged in to edit a hero');
      return;
    }

    try {
      setSaving(true);
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
        updated_at: new Date().toISOString()
      };

      // Update hero in database
      const { data, error } = await supabase
        .from('heroes')
        .update(heroData)
        .eq('id', hero.id)
        .eq('user_id', user.id) // Ensure user owns the hero
        .select();

      if (error) {
        throw new Error(error.message);
      }

      if (data && data.length > 0) {
        setSuccess('Hero updated successfully!');
        // Update local state
        setHero({ ...hero, ...data[0] });
        // Navigate back to hero detail after a short delay
        setTimeout(() => {
          navigate(`/heroes/${hero.id}`);
        }, 2000);
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to update hero';
      setError(message);
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="bg-light min-vh-100">
        <div className="container my-4">
          <div className="d-flex justify-content-center align-items-center" style={{ height: '300px' }}>
            <div className="spinner-border text-primary" role="status">
              <span className="visually-hidden">Loading...</span>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-light min-vh-100">
        <div className="container my-4">
          <Alert type="error" message={error} onClose={() => setError(null)} />
          <div className="d-grid mt-3">
            <Button onClick={() => navigate('/heroes')} variant="outline">
              Back to Heroes
            </Button>
          </div>
        </div>
      </div>
    );
  }

  if (!hero) {
    return (
      <div className="bg-light min-vh-100">
        <div className="container my-4">
          <Alert type="error" message="Hero not found" />
          <div className="d-grid mt-3">
            <Button onClick={() => navigate('/heroes')} variant="outline">
              Back to Heroes
            </Button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-light min-vh-100">
      <div className="container my-4">
        <div className="d-flex justify-content-between align-items-center mb-4">
          <h1 className="h3 mb-0">Edit Hero</h1>
          <Button onClick={() => navigate(`/heroes/${hero.id}`)} variant="outline">
            Back to Hero
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
                  onClick={() => navigate(`/heroes/${hero.id}`)}
                  disabled={saving}
                >
                  Cancel
                </Button>
                <Button
                  type="submit"
                  variant="primary"
                  loading={saving}
                  disabled={saving}
                >
                  Update Hero
                </Button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
};