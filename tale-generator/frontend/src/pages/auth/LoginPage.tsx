import React, { useState } from 'react';
import { useNavigate, Link, useLocation } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { useAuth } from '../../contexts/AuthContext';
import { Button } from '../../components/common/Button';
import { Input } from '../../components/common/Input';
import { Alert } from '../../components/common/Alert';
import { validateEmail } from '../../utils/validation';

interface LoginFormData {
  email: string;
  password: string;
  rememberMe: boolean;
}

export const LoginPage: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { signIn } = useAuth();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormData>();

  const onSubmit = async (data: LoginFormData) => {
    try {
      setError(null);
      setLoading(true);

      // Validate email
      if (!validateEmail(data.email)) {
        setError('Please enter a valid email address');
        return;
      }

      await signIn(data.email, data.password);

      // Redirect to intended page or dashboard
      const from = (location.state as { from?: { pathname: string } })?.from?.pathname || '/';
      navigate(from, { replace: true });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Login failed. Please try again.';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-white flex">
      {/* Left side - Decorative (hidden on mobile) */}
      <div className="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-primary-300 to-secondary-200 p-12 flex-col justify-between relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-primary-400/90 to-secondary-300/90"></div>
        <div className="absolute inset-0 opacity-10">
          <div className="absolute top-20 left-20 w-72 h-72 bg-white rounded-full blur-3xl"></div>
          <div className="absolute bottom-20 right-20 w-96 h-96 bg-white rounded-full blur-3xl"></div>
        </div>
        
        <div className="relative z-10">
          <div className="text-white">
            <h1 className="text-2xl font-semibold">Tale Generator</h1>
          </div>
        </div>
        
        <div className="relative z-10 space-y-6">
          <h2 className="text-4xl font-semibold text-white leading-tight">
            Create Magical Stories
            <br />
            for Your Children
          </h2>
          <p className="text-lg text-primary-100">
            Personalized tales that spark imagination and teach valuable lessons.
          </p>
        </div>
        
        <div className="relative z-10 text-primary-100 text-sm">
          © 2024 Tale Generator. All rights reserved.
        </div>
      </div>

      {/* Right side - Form */}
      <div className="flex-1 flex flex-col justify-center py-12 px-4 sm:px-6 lg:px-20 xl:px-24">
        <div className="mx-auto w-full max-w-md">
          <div className="lg:hidden mb-8 flex items-center justify-center">
            <h1 className="text-2xl font-semibold text-primary-600">Tale Generator</h1>
          </div>
          
          <div className="animate-fade-in">
            <h2 className="text-3xl font-semibold text-neutral-900 mb-2">
              Welcome back
            </h2>
            <p className="text-neutral-600 mb-8">
              Don't have an account?{' '}
              <Link to="/register" className="font-medium text-primary-600 hover:text-primary-700 transition-colors">
                Sign up for free
              </Link>
            </p>

            {error && (
              <div className="mb-6">
                <Alert type="error" message={error} onClose={() => setError(null)} />
              </div>
            )}

            <form className="space-y-5" onSubmit={handleSubmit(onSubmit)}>
              <Input
                label="Email Address"
                type="email"
                autoComplete="email"
                required
                {...register('email', {
                  required: 'Email is required',
                  validate: (value) => validateEmail(value) || 'Invalid email address',
                })}
                error={errors.email?.message}
              />

              <div>
                <Input
                  label="Password"
                  type="password"
                  autoComplete="current-password"
                  required
                  {...register('password', {
                    required: 'Password is required',
                  })}
                  error={errors.password?.message}
                />
                <div className="mt-3 flex items-center justify-between">
                  <div className="flex items-center">
                    <input
                      type="checkbox"
                      {...register('rememberMe')}
                      className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-neutral-300 rounded transition-colors"
                    />
                    <label className="ml-2 block text-sm text-neutral-700">Remember me</label>
                  </div>
                  <Link
                    to="/reset-password"
                    className="text-sm font-medium text-primary-600 hover:text-primary-700 transition-colors"
                  >
                    Forgot password?
                  </Link>
                </div>
              </div>

              <Button type="submit" fullWidth loading={loading} size="lg" variant="primary">
                Sign In
              </Button>
            </form>

            <div className="mt-8">
              <div className="relative">
                <div className="absolute inset-0 flex items-center">
                  <div className="w-full border-t border-neutral-300" />
                </div>
                <div className="relative flex justify-center text-sm">
                  <span className="px-2 bg-white text-neutral-500">Or continue with</span>
                </div>
              </div>

              <div className="mt-6 grid grid-cols-2 gap-3">
                <button
                  type="button"
                  disabled
                  className="w-full inline-flex justify-center py-2.5 px-4 border border-neutral-300 rounded-lg shadow-soft bg-white text-sm font-medium text-neutral-500 hover:bg-neutral-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  Google
                </button>
                <button
                  type="button"
                  disabled
                  className="w-full inline-flex justify-center py-2.5 px-4 border border-neutral-300 rounded-lg shadow-soft bg-white text-sm font-medium text-neutral-500 hover:bg-neutral-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  Facebook
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
