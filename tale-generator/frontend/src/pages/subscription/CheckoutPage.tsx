import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';
import { Alert } from '../../components/common/Alert';

interface Plan {
  tier: string;
  display_name: string;
  description: string;
  monthly_price: number;
  annual_price: number;
  features: string[];
}

interface LocationState {
  plan: Plan;
  billingCycle: 'monthly' | 'annual';
}

export const CheckoutPage: React.FC = () => {
  const { user, session, signOut } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const state = location.state as LocationState;

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paymentMethod, setPaymentMethod] = useState('mock_card');
  const [termsAccepted, setTermsAccepted] = useState(false);

  useEffect(() => {
    if (!session) {
      navigate('/login');
      return;
    }

    if (!state || !state.plan) {
      navigate('/subscription/plans');
      return;
    }
  }, [session, state, navigate]);

  if (!state || !state.plan) {
    return null;
  }

  const { plan, billingCycle } = state;
  const price = billingCycle === 'monthly' ? plan.monthly_price : plan.annual_price;

  const handlePurchase = async () => {
    if (!termsAccepted) {
      setError('Please accept the terms and conditions');
      return;
    }

    try {
      setLoading(true);
      setError(null);

      // Call purchase API
      const { data, error: apiError } = await supabase.functions.invoke('api/v1/subscription/purchase', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${session?.access_token}`,
          'Content-Type': 'application/json',
        },
        body: {
          plan_tier: plan.tier,
          billing_cycle: billingCycle,
          payment_method: paymentMethod,
        },
      });

      if (apiError) {
        throw apiError;
      }

      // Success - redirect to subscription page
      navigate('/subscription', {
        state: {
          message: data.message || 'Subscription upgraded successfully!',
        },
      });
    } catch (err: any) {
      console.error('Purchase error:', err);
      setError(err.message || 'Failed to process purchase. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Complete Your Purchase</h1>
          <p className="text-gray-600">Review your order and confirm subscription upgrade</p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Order Summary */}
          <div className="lg:col-span-2">
            <div className="bg-white rounded-lg shadow border border-gray-200 p-6 mb-6">
              <h2 className="text-xl font-semibold text-gray-900 mb-4">Order Summary</h2>

              <div className="space-y-4">
                <div className="flex justify-between items-start pb-4 border-b border-gray-200">
                  <div>
                    <h3 className="font-semibold text-gray-900">{plan.display_name}</h3>
                    <p className="text-sm text-gray-600">{plan.description}</p>
                    <p className="text-sm text-gray-500 mt-1">
                      Billed {billingCycle === 'monthly' ? 'monthly' : 'annually'}
                    </p>
                  </div>
                  <div className="text-right">
                    <div className="text-2xl font-bold text-gray-900">${price.toFixed(2)}</div>
                    {billingCycle === 'annual' && (
                      <div className="text-sm text-green-600">Save 17%</div>
                    )}
                  </div>
                </div>

                <div className="space-y-2">
                  <h4 className="font-medium text-gray-900">Included Features:</h4>
                  <ul className="space-y-2">
                    {plan.features.slice(0, 5).map((feature, index) => (
                      <li key={index} className="flex items-start text-sm text-gray-700">
                        <svg
                          className="w-5 h-5 text-green-500 mr-2 flex-shrink-0"
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
                        {feature}
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            </div>

            {/* Payment Method */}
            <div className="bg-white rounded-lg shadow border border-gray-200 p-6 mb-6">
              <h2 className="text-xl font-semibold text-gray-900 mb-4">Payment Method</h2>

              <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-4">
                <div className="flex">
                  <svg
                    className="w-5 h-5 text-yellow-600 mr-2 flex-shrink-0"
                    fill="currentColor"
                    viewBox="0 0 20 20"
                  >
                    <path
                      fillRule="evenodd"
                      d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                      clipRule="evenodd"
                    />
                  </svg>
                  <div className="text-sm text-yellow-800">
                    <strong>Development Mode:</strong> This is a mock payment system. No real charges will be made.
                  </div>
                </div>
              </div>

              <div className="space-y-3">
                <label className="flex items-center p-4 border border-gray-200 rounded-lg cursor-pointer hover:bg-gray-50">
                  <input
                    type="radio"
                    name="payment-method"
                    value="mock_card"
                    checked={paymentMethod === 'mock_card'}
                    onChange={(e) => setPaymentMethod(e.target.value)}
                    className="mr-3"
                  />
                  <div className="flex-1">
                    <div className="font-medium text-gray-900">Mock Credit Card (Success)</div>
                    <div className="text-sm text-gray-600">Simulates successful payment</div>
                  </div>
                </label>

                <label className="flex items-center p-4 border border-gray-200 rounded-lg cursor-pointer hover:bg-gray-50">
                  <input
                    type="radio"
                    name="payment-method"
                    value="mock_card_declined"
                    checked={paymentMethod === 'mock_card_declined'}
                    onChange={(e) => setPaymentMethod(e.target.value)}
                    className="mr-3"
                  />
                  <div className="flex-1">
                    <div className="font-medium text-gray-900">Mock Declined Card (Failure)</div>
                    <div className="text-sm text-gray-600">Simulates payment failure</div>
                  </div>
                </label>
              </div>
            </div>

            {/* Terms and Conditions */}
            <div className="bg-white rounded-lg shadow border border-gray-200 p-6">
              <label className="flex items-start cursor-pointer">
                <input
                  type="checkbox"
                  checked={termsAccepted}
                  onChange={(e) => setTermsAccepted(e.target.checked)}
                  className="mt-1 mr-3"
                />
                <span className="text-sm text-gray-700">
                  I agree to the terms and conditions, including automatic renewal of my subscription
                  at the end of each billing period.
                </span>
              </label>
            </div>
          </div>

          {/* Purchase Summary Card */}
          <div className="lg:col-span-1">
            <div className="bg-white rounded-lg shadow border border-gray-200 p-6 sticky top-6">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Total</h3>

              <div className="space-y-3 mb-6">
                <div className="flex justify-between text-gray-700">
                  <span>{plan.display_name}</span>
                  <span>${price.toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-gray-700 text-sm">
                  <span>Billing Cycle</span>
                  <span className="capitalize">{billingCycle}</span>
                </div>
                <div className="border-t border-gray-200 pt-3 flex justify-between font-bold text-lg">
                  <span>Total Due</span>
                  <span className="text-purple-600">${price.toFixed(2)}</span>
                </div>
              </div>

              {error && (
                <div className="mb-4">
                  <Alert type="error" message={error} onClose={() => setError(null)} />
                </div>
              )}

              <button
                onClick={handlePurchase}
                disabled={loading || !termsAccepted}
                className={`w-full py-3 px-4 rounded-lg font-semibold transition-colors ${
                  loading || !termsAccepted
                    ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                    : 'bg-purple-600 hover:bg-purple-700 text-white'
                }`}
              >
                {loading ? (
                  <span className="flex items-center justify-center">
                    <svg
                      className="animate-spin h-5 w-5 mr-2"
                      viewBox="0 0 24 24"
                      fill="none"
                    >
                      <circle
                        className="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        strokeWidth="4"
                      />
                      <path
                        className="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      />
                    </svg>
                    Processing...
                  </span>
                ) : (
                  'Complete Purchase'
                )}
              </button>

              <button
                onClick={() => navigate('/subscription/plans')}
                disabled={loading}
                className="w-full mt-3 py-2 px-4 text-gray-600 hover:text-gray-900 font-medium"
              >
                ← Back to Plans
              </button>

              <div className="mt-6 text-xs text-gray-500 text-center">
                <p>Your subscription will start immediately after purchase.</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
