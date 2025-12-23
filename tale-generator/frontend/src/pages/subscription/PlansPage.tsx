import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { Alert } from '../../components/common/Alert';

interface PlanLimits {
  monthly_stories: number | null;
  child_profiles: number | null;
  max_story_length: number;
  audio_enabled: boolean;
  hero_stories_enabled: boolean;
  combined_stories_enabled: boolean;
  priority_support: boolean;
}

interface Plan {
  tier: string;
  display_name: string;
  description: string;
  monthly_price: number;
  annual_price: number;
  features: string[];
  limits: PlanLimits;
  is_purchasable: boolean;
  is_current: boolean;
}

interface PlansResponse {
  plans: Plan[];
  current_plan: string;
}

export const PlansPage: React.FC = () => {
  const { user, session, signOut } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [plans, setPlans] = useState<Plan[]>([]);
  const [currentPlan, setCurrentPlan] = useState<string>('');
  const [billingCycle, setBillingCycle] = useState<'monthly' | 'annual'>('monthly');

  useEffect(() => {
    if (!session) {
      navigate('/login');
      return;
    }

    fetchPlans();
  }, [session, navigate]);

  const fetchPlans = async () => {
    try {
      setLoading(true);
      setError(null);

      const response = await fetch('http://localhost:8000/api/v1/subscription/plans', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${session?.access_token}`,
        },
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Failed to load subscription plans');
      }

      const plansData = await response.json() as PlansResponse;
      setPlans(plansData.plans);
      setCurrentPlan(plansData.current_plan);
    } catch (err: any) {
      console.error('Error fetching plans:', err);
      setError(err.message || 'Failed to load subscription plans');
    } finally {
      setLoading(false);
    }
  };

  const handleSelectPlan = (plan: Plan) => {
    if (!plan.is_purchasable) {
      return;
    }

    if (plan.is_current) {
      setError('You already have this plan');
      return;
    }

    // Navigate to checkout page with selected plan
    navigate('/subscription/checkout', {
      state: {
        plan: plan,
        billingCycle: billingCycle,
      },
    });
  };

  const getPlanColor = (tier: string) => {
    switch (tier) {
      case 'free':
        return 'gray';
      case 'starter':
        return 'green';
      case 'normal':
        return 'blue';
      case 'premium':
        return 'purple';
      default:
        return 'gray';
    }
  };

  const formatPrice = (plan: Plan) => {
    const price = billingCycle === 'monthly' ? plan.monthly_price : plan.annual_price;
    if (billingCycle === 'annual') {
      const monthlyEquivalent = (plan.annual_price / 12).toFixed(2);
      return (
        <div>
          <div className="text-3xl font-bold">${price.toFixed(2)}/year</div>
          <div className="text-sm text-gray-600">${monthlyEquivalent}/month equivalent</div>
        </div>
      );
    }
    return <div className="text-3xl font-bold">${price.toFixed(2)}/month</div>;
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50">
        <div className="flex items-center justify-center h-screen">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
            <p className="mt-4 text-gray-600">Loading plans...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">Choose Your Plan</h1>
          <p className="text-xl text-gray-600">
            Select the perfect plan for your family's storytelling needs
          </p>
        </div>

        {/* Billing Cycle Toggle */}
        <div className="flex justify-center mb-8">
          <div className="bg-white rounded-lg p-1 shadow-sm border border-gray-200">
            <button
              onClick={() => setBillingCycle('monthly')}
              className={`px-6 py-2 rounded-md font-medium transition-colors ${
                billingCycle === 'monthly'
                  ? 'bg-purple-600 text-white'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              Monthly
            </button>
            <button
              onClick={() => setBillingCycle('annual')}
              className={`px-6 py-2 rounded-md font-medium transition-colors ${
                billingCycle === 'annual'
                  ? 'bg-purple-600 text-white'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              Annual
              <span className="ml-2 text-sm bg-green-100 text-green-800 px-2 py-1 rounded">
                Save 17%
              </span>
            </button>
          </div>
        </div>

        {error && (
          <div className="mb-6">
            <Alert
              type="error"
              message={error}
              onClose={() => setError(null)}
            />
          </div>
        )}

        {/* Plans Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {plans.map((plan) => {
            const color = getPlanColor(plan.tier);
            const isRecommended = plan.tier === 'normal';

            return (
              <div
                key={plan.tier}
                className={`relative bg-white rounded-lg shadow-lg border-2 ${
                  plan.is_current
                    ? 'border-green-500'
                    : isRecommended
                    ? 'border-purple-500'
                    : 'border-gray-200'
                } p-6 flex flex-col`}
              >
                {/* Current Plan Badge */}
                {plan.is_current && (
                  <div className="absolute top-0 right-0 bg-green-500 text-white text-xs font-semibold px-3 py-1 rounded-bl-lg rounded-tr-lg">
                    Current Plan
                  </div>
                )}

                {/* Recommended Badge */}
                {isRecommended && !plan.is_current && (
                  <div className="absolute top-0 right-0 bg-purple-500 text-white text-xs font-semibold px-3 py-1 rounded-bl-lg rounded-tr-lg">
                    Recommended
                  </div>
                )}

                {/* Plan Header */}
                <div className="mb-6">
                  <h3 className="text-2xl font-bold text-gray-900 mb-2">{plan.display_name}</h3>
                  <p className="text-gray-600 text-sm mb-4">{plan.description}</p>
                  {formatPrice(plan)}
                </div>

                {/* Features List */}
                <div className="flex-1 mb-6">
                  <ul className="space-y-3">
                    {plan.features.map((feature, index) => (
                      <li key={index} className="flex items-start">
                        <svg
                          className="w-5 h-5 text-green-500 mr-2 mt-0.5 flex-shrink-0"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth={2}
                            d="M5 13l4 4L19 7"
                          />
                        </svg>
                        <span className="text-gray-700 text-sm">{feature}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                {/* Action Button */}
                <button
                  onClick={() => handleSelectPlan(plan)}
                  disabled={!plan.is_purchasable || plan.is_current}
                  className={`w-full py-3 px-4 rounded-lg font-semibold transition-colors ${
                    plan.is_current
                      ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                      : !plan.is_purchasable
                      ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                      : plan.tier === 'free'
                      ? 'bg-gray-600 hover:bg-gray-700 text-white'
                      : plan.tier === 'starter'
                      ? 'bg-green-600 hover:bg-green-700 text-white'
                      : plan.tier === 'normal'
                      ? 'bg-blue-600 hover:bg-blue-700 text-white'
                      : plan.tier === 'premium'
                      ? 'bg-purple-600 hover:bg-purple-700 text-white'
                      : 'bg-indigo-600 hover:bg-indigo-700 text-white'
                  }`}
                >
                  {plan.is_current
                    ? 'Current Plan'
                    : !plan.is_purchasable
                    ? 'Not Available'
                    : 'Select Plan'}
                </button>
              </div>
            );
          })}
        </div>

        {/* Back Button */}
        <div className="text-center">
          <button
            onClick={() => navigate('/subscription')}
            className="text-purple-600 hover:text-purple-700 font-medium"
          >
            ← Back to Subscription
          </button>
        </div>
      </div>
    </div>
  );
};
