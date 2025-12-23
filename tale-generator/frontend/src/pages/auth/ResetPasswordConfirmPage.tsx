import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { useAuth } from '../../contexts/AuthContext';
import { Button } from '../../components/common/Button';
import { Input } from '../../components/common/Input';
import { Alert } from '../../components/common/Alert';
import { PasswordStrength } from '../../components/auth/PasswordStrength';
import { validatePassword } from '../../utils/validation';

interface ResetPasswordConfirmFormData {
  password: string;
  confirmPassword: string;
}

export const ResetPasswordConfirmPage: React.FC = () => {
  const navigate = useNavigate();
  const { updatePassword } = useAuth();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const {
    register,
    handleSubmit,
    watch,
    formState: { errors },
  } = useForm<ResetPasswordConfirmFormData>();

  const password = watch('password', '');

  const onSubmit = async (data: ResetPasswordConfirmFormData) => {
    try {
      setError(null);
      setLoading(true);

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

      await updatePassword(data.password);
      setSuccess(true);

      // Redirect to login after 3 seconds
      setTimeout(() => {
        navigate('/login');
      }, 3000);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to reset password. Please try again.';
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
          Set new password
        </h2>
        <p className="mt-2 text-center text-sm text-gray-600">
          Choose a strong password for your account
        </p>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          {error && <Alert type="error" message={error} onClose={() => setError(null)} />}
          {success ? (
            <div>
              <Alert
                type="success"
                message="Password updated successfully! Redirecting to login..."
              />
              <div className="mt-6 text-center">
                <Link
                  to="/login"
                  className="font-medium text-blue-600 hover:text-blue-500"
                >
                  Go to sign in
                </Link>
              </div>
            </div>
          ) : (
            <form className="space-y-6 mt-6" onSubmit={handleSubmit(onSubmit)}>
              <div>
                <Input
                  label="New Password"
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
                label="Confirm New Password"
                type="password"
                autoComplete="new-password"
                required
                {...register('confirmPassword', {
                  required: 'Please confirm your password',
                  validate: (value) => value === password || 'Passwords do not match',
                })}
                error={errors.confirmPassword?.message}
              />

              <Button type="submit" fullWidth loading={loading} disabled={success}>
                Reset Password
              </Button>
            </form>
          )}
        </div>
      </div>
    </div>
  );
};
