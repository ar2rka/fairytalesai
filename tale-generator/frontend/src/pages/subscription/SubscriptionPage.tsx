import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';
import { SubscriptionBadge } from '../../components/subscription/SubscriptionBadge';
import { UsageLimitCard } from '../../components/subscription/UsageLimitCard';
import { Alert } from '../../components/common/Alert';

interface SubscriptionInfo {
  subscription: {
    plan: 'free' | 'starter' | 'normal' | 'premium';
    status: string;
    start_date: string | null;
    end_date: string | null;
  };
  limits: {
    monthly_stories: number | null;
    stories_used: number;
    stories_remaining: number | null;
    reset_date: string;
    child_profiles_limit: number | null;
    child_profiles_count: number;
    audio_enabled: boolean;
    hero_stories_enabled: boolean;
    max_story_length: number;
  };
  features: {
    audio_generation: boolean;
    hero_stories: boolean;
    combined_stories: boolean;
    priority_support: boolean;
  };
}

interface PurchaseTransaction {
  id: string;
  from_plan: string;
  to_plan: string;
  amount: number;
  currency: string;
  payment_status: string;
  created_at: string;
  completed_at: string | null;
}

export const SubscriptionPage: React.FC = () => {
  const { session } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [subscriptionInfo, setSubscriptionInfo] = useState<SubscriptionInfo | null>(null);
  const [purchaseHistory, setPurchaseHistory] = useState<PurchaseTransaction[]>([]);
  const [showHistory, setShowHistory] = useState(false);

  useEffect(() => {
    const fetchSubscriptionInfo = async () => {
      if (!session) return;

      try {
        setLoading(true);
        setError(null);

        const response = await fetch('http://localhost:8000/api/v1/users/subscription', {
          headers: {
            'Authorization': `Bearer ${session.access_token}`,
            'Content-Type': 'application/json'
          }
        });

        if (!response.ok) {
          throw new Error('Failed to fetch subscription information');
        }

        const data = await response.json();
        setSubscriptionInfo(data);
      } catch (err) {
        console.error('Error fetching subscription:', err);
        setError(err instanceof Error ? err.message : 'Failed to load subscription information');
      } finally {
        setLoading(false);
      }
    };

    fetchSubscriptionInfo();
  }, [session]);

  const fetchPurchaseHistory = async () => {
    if (!session) return;

    try {
      const response = await fetch('http://localhost:8000/api/v1/subscription/purchases?limit=10', {
        headers: {
          'Authorization': `Bearer ${session.access_token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error('Failed to fetch purchase history');
      }

      const data = await response.json();
      setPurchaseHistory(data.transactions || []);
      setShowHistory(true);
    } catch (err) {
      console.error('Error fetching purchase history:', err);
    }
  };

  const getResetDate = () => {
    if (!subscriptionInfo) return '';
    const date = new Date(subscriptionInfo.limits.reset_date);
    return date.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
  };

  const getStatusBadge = (status: string) => {
    const colors = {
      completed: 'bg-green-100 text-green-800',
      pending: 'bg-yellow-100 text-yellow-800',
      failed: 'bg-red-100 text-red-800',
      refunded: 'bg-gray-100 text-gray-800',
    };
    return colors[status as keyof typeof colors] || 'bg-gray-100 text-gray-800';
  };

  const getPlanFeatures = () => {
    const features = [
      {
        name: 'Audio Generation',
        enabled: subscriptionInfo?.features.audio_generation,
      },
      {
        name: 'Hero Stories',
        enabled: subscriptionInfo?.features.hero_stories,
      },
      {
        name: 'Combined Stories',
        enabled: subscriptionInfo?.features.combined_stories,
      },
      {
        name: 'Priority Support',
        enabled: subscriptionInfo?.features.priority_support,
      }
    ];

    return features;
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-[#F5F5F5]">
        <div className="max-w-7xl mx-auto px-8 py-8">
          <div className="flex justify-center items-center h-64">
            <div className="text-neutral-600">Loading subscription information...</div>
          </div>
        </div>
      </div>
    );
  }

  if (error || !subscriptionInfo) {
    return (
      <div className="min-h-screen bg-[#F5F5F5]">
        <div className="max-w-7xl mx-auto px-8 py-8">
          <Alert type="error" message={error || 'Subscription information not available'} />
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F5F5F5]">
      <div className="max-w-7xl mx-auto px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-neutral-900">Subscription</h1>
              <p className="mt-2 text-neutral-600">Manage your plan and usage</p>
            </div>
            <SubscriptionBadge plan={subscriptionInfo.subscription.plan} />
          </div>
        </div>

        {/* Usage Stats */}
        <div className="mb-8">
          <h2 className="text-xl font-semibold text-neutral-900 mb-4">Current Usage</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <UsageLimitCard
              title="Monthly Stories"
              used={subscriptionInfo.limits.stories_used}
              limit={subscriptionInfo.limits.monthly_stories}
              unit="stories"
              icon=""
            />
            <UsageLimitCard
              title="Child Profiles"
              used={subscriptionInfo.limits.child_profiles_count}
              limit={subscriptionInfo.limits.child_profiles_limit}
              unit="profiles"
              icon=""
            />
          </div>
          
          {subscriptionInfo.limits.monthly_stories && (
            <div className="mt-4 text-sm text-gray-600">
              Usage resets on <span className="font-medium">{getResetDate()}</span>
            </div>
          )}
        </div>

        {/* Plan Features */}
        <div className="mb-8">
          <h2 className="text-xl font-semibold text-neutral-900 mb-4">Plan Features</h2>
          <div className="bg-white rounded-lg shadow border border-neutral-200 p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {getPlanFeatures().map((feature) => (
                <div key={feature.name} className="flex items-center justify-between">
                  <span className="text-neutral-900 font-medium">{feature.name}</span>
                  {feature.enabled ? (
                    <span className="text-green-600 text-sm font-medium">Enabled</span>
                  ) : (
                    <span className="text-neutral-400 text-sm font-medium">Not Available</span>
                  )}
                </div>
              ))}
            </div>

            <div className="mt-6 pt-6 border-t border-gray-200">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-neutral-900">Maximum Story Length</p>
                  <p className="text-sm text-neutral-600">{subscriptionInfo.limits.max_story_length} minutes</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Upgrade CTA (for non-premium users) */}
        {subscriptionInfo.subscription.plan !== 'premium' && (
          <div className="bg-gradient-to-r from-purple-600 to-pink-600 rounded-lg shadow-lg p-8 text-white mb-8">
            <h2 className="text-2xl font-bold mb-2">Upgrade Your Plan</h2>
            <p className="mb-6 opacity-90">
              Get more stories, unlock premium features, and create unlimited adventures for your children.
            </p>
            <button
              onClick={() => navigate('/subscription/plans')}
              className="bg-white text-purple-600 px-6 py-3 rounded-lg font-semibold hover:bg-gray-100 transition-colors"
            >
              View Plans
            </button>
          </div>
        )}

        {/* Purchase History */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold text-neutral-900">Purchase History</h2>
            {!showHistory && (
              <button
                onClick={fetchPurchaseHistory}
                className="text-purple-600 hover:text-purple-700 font-medium text-sm"
              >
                View History
              </button>
            )}
          </div>

          {showHistory && (
            <div className="bg-white rounded-lg shadow border border-gray-200">
              {purchaseHistory.length === 0 ? (
                <div className="p-6 text-center text-gray-600">
                  <p>No purchase history yet</p>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Date
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Upgrade
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Amount
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Status
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {purchaseHistory.map((transaction) => (
                        <tr key={transaction.id}>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                            {new Date(transaction.created_at).toLocaleDateString()}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                            <span className="capitalize">{transaction.from_plan}</span>
                            <span className="mx-2">→</span>
                            <span className="capitalize font-semibold">{transaction.to_plan}</span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                            ${transaction.amount.toFixed(2)} {transaction.currency}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className={`px-2 py-1 text-xs font-semibold rounded-full ${getStatusBadge(transaction.payment_status)}`}>
                              {transaction.payment_status}
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Back Button */}
        <div className="mt-8">
          <button
            onClick={() => navigate('/dashboard')}
            className="text-indigo-600 hover:text-indigo-700 font-medium"
          >
            ← Back to Dashboard
          </button>
        </div>
      </div>
    </div>
  );
};
