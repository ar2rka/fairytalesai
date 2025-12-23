import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { useAuth } from '../../contexts/AuthContext';
import { Button } from '../../components/common/Button';
import { Input } from '../../components/common/Input';
import { Alert } from '../../components/common/Alert';
import { validateEmail } from '../../utils/validation';

interface ResetPasswordFormData {
  email: string;
}

export const ResetPasswordPage: React.FC = () => {
  const { resetPassword } = useAuth();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ResetPasswordFormData>();

  const onSubmit = async (data: ResetPasswordFormData) => {
    try {
      setError(null);
      setLoading(true);

      // Validate email
      if (!validateEmail(data.email)) {
        setError('Please enter a valid email address');
        return;
      }

      await resetPassword(data.email);
      setSuccess(true);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to send reset email. Please try again.';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
          Reset your password
        </h2>
        <p className="mt-2 text-center text-sm text-gray-600">
          Remember your password?{' '}
          <Link to="/login" className="font-medium text-blue-600 hover:text-blue-500">
            Sign in
          </Link>
        </p>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          {error && <Alert type="error" message={error} onClose={() => setError(null)} />}
          {success ? (
            <div>
              <Alert
                type="success"
                message="If an account exists with this email, you will receive a password reset link shortly."
              />
              <div className="mt-6 text-center">
                <Link
                  to="/login"
                  className="font-medium text-blue-600 hover:text-blue-500"
                >
                  Return to sign in
                </Link>
              </div>
            </div>
          ) : (
            <form className="space-y-6 mt-6" onSubmit={handleSubmit(onSubmit)}>
              <div>
                <p className="text-sm text-gray-600 mb-4">
                  Enter your email address and we'll send you a link to reset your password.
                </p>
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
              </div>

              <Button type="submit" fullWidth loading={loading}>
                Send Reset Link
              </Button>
            </form>
          )}
        </div>
      </div>
    </div>
  );
};
