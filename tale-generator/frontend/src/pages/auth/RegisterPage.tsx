import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { useAuth } from '../../contexts/AuthContext';
import { Button } from '../../components/common/Button';
import { Input } from '../../components/common/Input';
import { Alert } from '../../components/common/Alert';
import { PasswordStrength } from '../../components/auth/PasswordStrength';
import { validateEmail, validatePassword, validateName } from '../../utils/validation';

interface RegisterFormData {
  name: string;
  email: string;
  password: string;
  confirmPassword: string;
  acceptTerms: boolean;
}

export const RegisterPage: React.FC = () => {
  const navigate = useNavigate();
  const { signUp } = useAuth();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const {
    register,
    handleSubmit,
    watch,
    formState: { errors },
  } = useForm<RegisterFormData>();

  const password = watch('password', '');

  const onSubmit = async (data: RegisterFormData) => {
    try {
      setError(null);
      setLoading(true);

      // Validate email
      if (!validateEmail(data.email)) {
        setError('Please enter a valid email address');
        return;
      }

      // Validate name
      const nameValidation = validateName(data.name);
      if (!nameValidation.isValid) {
        setError(nameValidation.error || 'Invalid name');
        return;
      }

      // Validate password
      const passwordValidation = validatePassword(data.password);
      if (!passwordValidation.isValid) {
        setError(passwordValidation.errors[0]);
        return;
      }

      // Validate password confirmation
      if (data.password !== data.confirmPassword) {
        setError('Passwords do not match');
        return;
      }

      // Validate terms acceptance
      if (!data.acceptTerms) {
        setError('You must accept the Terms of Service to continue');
        return;
      }

      await signUp(data.email, data.password, data.name);
      setSuccess(true);

      // Redirect after successful registration
      setTimeout(() => {
        navigate('/');
      }, 2000);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Registration failed. Please try again.';
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
            Start Your
            <br />
            Storytelling Journey
          </h2>
          <p className="text-lg text-primary-100">
            Join thousands of parents creating magical memories through personalized stories.
          </p>
          <div className="space-y-3 pt-4">
            <div className="text-white flex items-center">
              <span className="mr-2">✓</span>
              <span>Unlimited personalized stories</span>
            </div>
            <div className="text-white flex items-center">
              <span className="mr-2">✓</span>
              <span>Multiple child profiles</span>
            </div>
            <div className="text-white flex items-center">
              <span className="mr-2">✓</span>
              <span>Age-appropriate content</span>
            </div>
          </div>
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
              Create your account
            </h2>
            <p className="text-neutral-600 mb-8">
              Already have an account?{' '}
              <Link to="/login" className="font-medium text-primary-600 hover:text-primary-700 transition-colors">
                Sign in
              </Link>
            </p>

            {error && (
              <div className="mb-6">
                <Alert type="error" message={error} onClose={() => setError(null)} />
              </div>
            )}
            {success && (
              <div className="mb-6">
                <Alert
                  type="success"
                  message="Account created successfully! Redirecting to dashboard..."
                />
              </div>
            )}

            <form className="space-y-5" onSubmit={handleSubmit(onSubmit)}>
              <Input
                label="Full Name"
                type="text"
                autoComplete="name"
                required
                {...register('name', {
                  required: 'Name is required',
                  minLength: {
                    value: 2,
                    message: 'Name must be at least 2 characters',
                  },
                  maxLength: {
                    value: 100,
                    message: 'Name must not exceed 100 characters',
                  },
                  pattern: {
                    value: /^[a-zA-Z\s\-]+$/,
                    message: 'Name can only contain letters, spaces, and hyphens',
                  },
                })}
                error={errors.name?.message}
              />

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
                  autoComplete="new-password"
                  required
                  {...register('password', {
                    required: 'Password is required',
                    minLength: {
                      value: 8,
                      message: 'Password must be at least 8 characters',
                    },
                  })}
                  error={errors.password?.message}
                />
                <PasswordStrength password={password} />
              </div>

              <Input
                label="Confirm Password"
                type="password"
                autoComplete="new-password"
                required
                {...register('confirmPassword', {
                  required: 'Please confirm your password',
                  validate: (value) => value === password || 'Passwords do not match',
                })}
                error={errors.confirmPassword?.message}
              />

              <div className="flex items-start">
                <input
                  type="checkbox"
                  {...register('acceptTerms', {
                    required: 'You must accept the Terms of Service',
                  })}
                  className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-neutral-300 rounded mt-1 transition-colors"
                />
                <label className="ml-2 block text-sm text-neutral-700">
                  I accept the{' '}
                  <a href="#" className="text-primary-600 hover:text-primary-700 transition-colors">
                    Terms of Service
                  </a>{' '}
                  and{' '}
                  <a href="#" className="text-primary-600 hover:text-primary-700 transition-colors">
                    Privacy Policy
                  </a>
                </label>
              </div>
              {errors.acceptTerms && (
                <p className="text-sm text-red-600">
                  {errors.acceptTerms.message}
                </p>
              )}

              <Button type="submit" fullWidth loading={loading} disabled={success} size="lg" variant="primary">
                Create Account
              </Button>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
};
