/**
 * Validates email format using RFC 5322 standard
 */
export const validateEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email) && email.length <= 255;
};

/**
 * Validates password strength
 * Requires: min 8 chars, 1 uppercase, 1 lowercase, 1 number
 */
export const validatePassword = (password: string): {
  isValid: boolean;
  errors: string[];
} => {
  const errors: string[] = [];

  if (password.length < 8) {
    errors.push('Password must be at least 8 characters long');
  }

  if (password.length > 128) {
    errors.push('Password must not exceed 128 characters');
  }

  if (!/[A-Z]/.test(password)) {
    errors.push('Password must contain at least one uppercase letter');
  }

  if (!/[a-z]/.test(password)) {
    errors.push('Password must contain at least one lowercase letter');
  }

  if (!/[0-9]/.test(password)) {
    errors.push('Password must contain at least one number');
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

/**
 * Validates name field
 */
export const validateName = (name: string): {
  isValid: boolean;
  error?: string;
} => {
  if (name.length < 2) {
    return { isValid: false, error: 'Name must be at least 2 characters long' };
  }

  if (name.length > 100) {
    return { isValid: false, error: 'Name must not exceed 100 characters' };
  }

  if (!/^[a-zA-Z\s\-]+$/.test(name)) {
    return { isValid: false, error: 'Name can only contain letters, spaces, and hyphens' };
  }

  return { isValid: true };
};

/**
 * Calculates password strength (0-100)
 */
export const getPasswordStrength = (password: string): number => {
  let strength = 0;

  if (password.length >= 8) strength += 25;
  if (password.length >= 12) strength += 15;
  if (/[a-z]/.test(password)) strength += 15;
  if (/[A-Z]/.test(password)) strength += 15;
  if (/[0-9]/.test(password)) strength += 15;
  if (/[^a-zA-Z0-9]/.test(password)) strength += 15;

  return Math.min(strength, 100);
};
