# Frontend Registration & Authentication

This document describes the frontend registration and authentication system for the Tale Generator application.

## Overview

The frontend is built as a Single Page Application (SPA) using:
- **React 18** with TypeScript for type safety
- **Vite** for fast development and optimized builds
- **Tailwind CSS** for responsive styling
- **React Router** for client-side navigation
- **Supabase Auth** for authentication
- **React Hook Form** for form validation

## Architecture

### Component Structure

```
frontend/src/
├── components/
│   ├── auth/
│   │   ├── PasswordStrength.tsx    # Password strength indicator
│   │   └── ProtectedRoute.tsx      # Route guard component
│   └── common/
│       ├── Alert.tsx                # Alert/notification component
│       ├── Button.tsx               # Reusable button component
│       └── Input.tsx                # Form input component
├── contexts/
│   └── AuthContext.tsx              # Authentication state management
├── pages/
│   ├── auth/
│   │   ├── LoginPage.tsx            # User login page
│   │   ├── RegisterPage.tsx         # User registration page
│   │   ├── ResetPasswordPage.tsx    # Password reset request
│   │   └── ResetPasswordConfirmPage.tsx # Password reset confirmation
│   └── dashboard/
│       └── DashboardPage.tsx        # Main dashboard
├── services/
│   └── supabase.ts                  # Supabase client configuration
├── types/
│   └── auth.ts                      # Authentication type definitions
├── utils/
│   └── validation.ts                # Form validation utilities
└── App.tsx                          # Main app with routing
```

## Setup Instructions

### 1. Environment Configuration

Create a `.env` file in the `frontend/` directory:

```bash
cd frontend
cp .env.example .env
```

Edit `.env` and add your Supabase credentials:

```env
VITE_SUPABASE_URL=your_supabase_project_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 2. Install Dependencies

```bash
cd frontend
npm install
```

### 3. Run Development Server

```bash
npm run dev
```

The application will be available at `http://localhost:5173`

### 4. Build for Production

```bash
npm run build
```

The production-ready files will be in the `dist/` directory.

## Features

### Authentication Flow

#### Registration
- Users can create an account with email and password
- Password strength indicator provides real-time feedback
- Client-side validation ensures data quality
- User profile is automatically created in the database
- Users are automatically logged in after registration

#### Login
- Email and password authentication
- "Remember me" functionality
- Redirect to intended page after login
- Clear error messages for invalid credentials

#### Password Reset
- Request password reset via email
- Secure token-based reset flow
- Password strength validation for new password
- Automatic redirect to login after successful reset

### Protected Routes

Routes that require authentication:
- `/` - Dashboard (home page)
- Future: Children management pages
- Future: Story generation pages
- Future: User profile pages

Public routes (no authentication required):
- `/login` - Login page
- `/register` - Registration page
- `/reset-password` - Password reset request
- `/reset-password/confirm` - Password reset confirmation

### Form Validation

All forms include comprehensive validation:

**Email Validation:**
- Valid email format (RFC 5322)
- Maximum 255 characters

**Password Validation:**
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- Maximum 128 characters

**Name Validation:**
- Minimum 2 characters
- Maximum 100 characters
- Letters, spaces, and hyphens only

## Authentication Context

The `AuthContext` provides centralized authentication state management:

```typescript
const { user, session, loading, signUp, signIn, signOut, resetPassword } = useAuth();
```

**State:**
- `user`: Current user object or null
- `session`: Current session object or null
- `loading`: Boolean indicating auth check in progress
- `error`: Authentication error message or null

**Methods:**
- `signUp(email, password, name)`: Register new user
- `signIn(email, password)`: Authenticate user
- `signOut()`: Log out user
- `resetPassword(email)`: Initiate password reset
- `updatePassword(newPassword)`: Update user password

## Component Usage

### Using Protected Routes

```typescript
import { ProtectedRoute } from './components/auth/ProtectedRoute';

<Route
  path="/dashboard"
  element={
    <ProtectedRoute>
      <DashboardPage />
    </ProtectedRoute>
  }
/>
```

### Accessing Current User

```typescript
import { useAuth } from './contexts/AuthContext';

function MyComponent() {
  const { user } = useAuth();
  
  return <div>Welcome, {user?.email}</div>;
}
```

### Using Form Components

```typescript
import { Input } from './components/common/Input';
import { Button } from './components/common/Button';

<Input
  label="Email"
  type="email"
  required
  error={errors.email?.message}
  {...register('email')}
/>

<Button type="submit" loading={isLoading} fullWidth>
  Sign In
</Button>
```

## Security Considerations

### Token Storage
- Access tokens are stored in memory only
- Refresh tokens are managed by Supabase (httpOnly cookies when possible)
- All tokens are cleared on logout

### Password Security
- Passwords are never logged or exposed
- Password fields are masked during input
- Strong password requirements enforced
- Passwords are hashed by Supabase before storage

### XSS Prevention
- React's built-in XSS protection
- All user inputs are sanitized
- Content Security Policy headers should be set

### CSRF Prevention
- Supabase provides built-in CSRF protection
- State parameters used for OAuth flows

## Database Schema

The frontend expects the following Supabase schema:

### user_profiles table
```sql
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Row Level Security
RLS policies ensure users can only access their own data:
- Users can view/update their own profile
- Users can view/create/update/delete their own children
- Users can view/create/update/delete their own stories

## Troubleshooting

### Common Issues

**"Missing Supabase environment variables"**
- Ensure `.env` file exists in `frontend/` directory
- Verify `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` are set
- Restart the development server after changing `.env`

**"Invalid authentication token"**
- Check that Supabase JWT secret is correctly configured
- Verify token hasn't expired (1 hour default)
- Try logging out and logging in again

**TypeScript errors about imports**
- Run `npm install` to ensure all dependencies are installed
- Check that `tsconfig.json` is properly configured
- Restart the TypeScript server in your IDE

**Tailwind styles not applied**
- Ensure `tailwind.config.js` content paths include all source files
- Verify `@tailwind` directives are in `index.css`
- Check that PostCSS is configured correctly

## Testing

### Manual Testing Checklist

- [ ] Register new user with valid credentials
- [ ] Register with invalid email shows error
- [ ] Register with weak password shows validation errors
- [ ] Login with correct credentials works
- [ ] Login with incorrect credentials shows error
- [ ] Password reset email is sent
- [ ] Password can be reset with valid token
- [ ] Protected routes redirect to login when not authenticated
- [ ] User can access protected routes when authenticated
- [ ] Logout works and redirects to login
- [ ] Session persists across page reloads
- [ ] Form validation errors are displayed inline

## Future Enhancements

- [ ] Email verification requirement
- [ ] OAuth social login (Google, Facebook)
- [ ] Multi-factor authentication
- [ ] Account deletion workflow
- [ ] User profile editing
- [ ] Avatar upload
- [ ] Account settings page
- [ ] Session management (view/revoke active sessions)

## Related Documentation

- [Design Document](./.qoder/quests/frontend-registration.md)
- [Database Migration](../supabase/migrations/012_add_user_authentication.sql)
- [Backend Auth Middleware](../src/api/auth.py)
- [Supabase Documentation](https://supabase.com/docs/guides/auth)
- [React Hook Form](https://react-hook-form.com/)
- [Tailwind CSS](https://tailwindcss.com/)
