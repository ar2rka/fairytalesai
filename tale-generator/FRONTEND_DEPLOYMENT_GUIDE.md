# Frontend Registration Implementation - Deployment Guide

This guide provides step-by-step instructions for deploying the Tale Generator frontend with authentication.

## Prerequisites

- Supabase project created and configured
- Node.js 18+ installed
- Backend API running with authentication middleware
- Environment variables configured

## Deployment Steps

### Step 1: Database Migration

Run the authentication migration on your Supabase database:

1. Open your Supabase project dashboard
2. Navigate to SQL Editor
3. Open the migration file: `supabase/migrations/012_add_user_authentication.sql`
4. Copy and execute the SQL

This will create:
- `user_profiles` table
- RLS policies for authentication
- User ID columns on `children` and `stories` tables
- Proper indexes for performance

### Step 2: Configure Supabase Authentication

1. In Supabase Dashboard, go to Authentication → Settings
2. Configure the following:

**Site URL:**
```
http://localhost:5173 (development)
https://yourdomain.com (production)
```

**Redirect URLs:**
```
http://localhost:5173/reset-password/confirm
https://yourdomain.com/reset-password/confirm
```

**Email Templates:**
- Customize the password reset email template if desired
- Ensure the reset link points to `/reset-password/confirm`

**JWT Settings:**
- JWT expiry: 3600 seconds (1 hour) - default is fine
- Note the JWT Secret for backend configuration

### Step 3: Environment Configuration

#### Frontend (.env in frontend/)

```bash
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key_here
```

#### Backend (.env in root)

```bash
# Existing variables
OPENROUTER_API_KEY=your_key
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_anon_key

# New for authentication
SUPABASE_JWT_SECRET=your_jwt_secret_here
```

Get your JWT secret from: Supabase Dashboard → Settings → API → JWT Secret

### Step 4: Install Dependencies

#### Frontend
```bash
cd frontend
npm install
```

#### Backend (if using JWT verification)
```bash
pip install pyjwt[crypto]
# or
uv add pyjwt[crypto]
```

### Step 5: Build Frontend

```bash
cd frontend
npm run build
```

This creates optimized files in `frontend/dist/`

### Step 6: Deploy Frontend

#### Option A: Vercel

1. Install Vercel CLI:
```bash
npm install -g vercel
```

2. Deploy:
```bash
cd frontend
vercel
```

3. Set environment variables in Vercel dashboard:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

4. Redeploy after setting env vars

#### Option B: Netlify

1. Create `frontend/netlify.toml`:
```toml
[build]
  command = "npm run build"
  publish = "dist"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

2. Deploy via Netlify CLI or connect GitHub repo

3. Set environment variables in Netlify dashboard

#### Option C: Static Hosting (S3, CloudFlare, etc.)

1. Upload contents of `frontend/dist/` to your hosting
2. Configure SPA routing (all routes → index.html)
3. Set up environment variables via hosting provider

### Step 7: Update Backend API

If you want to protect existing endpoints with authentication:

```python
from fastapi import Depends
from src.api.auth import get_current_user, AuthUser

@router.post("/children")
async def create_child(
    child_data: ChildCreate,
    user: AuthUser = Depends(get_current_user)
):
    # Add user_id to the child data
    child_dict = child_data.dict()
    child_dict['user_id'] = user.user_id
    
    # Save to database
    saved_child = supabase_client.save_child(child_dict)
    return saved_child
```

### Step 8: Test the Deployment

1. **Registration Flow:**
   - Visit `/register`
   - Create a new account
   - Verify user profile is created in Supabase
   - Confirm automatic login and redirect

2. **Login Flow:**
   - Visit `/login`
   - Log in with created credentials
   - Verify redirect to dashboard
   - Check user session persists on reload

3. **Password Reset:**
   - Visit `/reset-password`
   - Request password reset
   - Check email for reset link
   - Complete password reset
   - Log in with new password

4. **Protected Routes:**
   - Access dashboard while logged in (should work)
   - Log out
   - Try to access dashboard (should redirect to login)

5. **RLS Verification:**
   - Create test data for User A
   - Log in as User B
   - Verify User B cannot see User A's data

## Production Checklist

- [ ] Database migration executed successfully
- [ ] Supabase Auth settings configured
- [ ] Environment variables set in all environments
- [ ] Frontend built and deployed
- [ ] Backend authentication middleware integrated
- [ ] SSL/HTTPS enabled on all domains
- [ ] CORS configured correctly
- [ ] Error monitoring set up
- [ ] Analytics tracking implemented
- [ ] Email templates customized
- [ ] Terms of Service and Privacy Policy pages created
- [ ] Password reset emails tested
- [ ] RLS policies verified
- [ ] Performance testing completed
- [ ] Security audit performed

## Monitoring & Maintenance

### Supabase Dashboard

Monitor the following:
- Authentication logs (failed logins, suspicious activity)
- Database performance
- RLS policy execution times
- Storage usage

### Frontend Monitoring

Recommended tools:
- Sentry for error tracking
- Google Analytics or Plausible for usage analytics
- Vercel/Netlify analytics for deployment metrics

### Security Best Practices

1. **Rotate Secrets Regularly:**
   - Change JWT secret periodically
   - Update Supabase API keys if compromised

2. **Monitor Failed Login Attempts:**
   - Set up alerts for unusual patterns
   - Consider rate limiting at CDN level

3. **Keep Dependencies Updated:**
   ```bash
   npm audit
   npm update
   ```

4. **Enable Email Verification (Optional):**
   - In Supabase → Auth → Email Auth
   - Toggle "Enable email confirmations"

5. **Set Up MFA (Future):**
   - Supabase supports TOTP-based MFA
   - Can be enabled for high-security accounts

## Rollback Plan

If issues arise after deployment:

1. **Frontend Rollback:**
   - Revert to previous deployment in hosting dashboard
   - Or deploy previous Git commit

2. **Database Rollback:**
   ```sql
   -- Revert user_profiles table
   DROP TABLE IF EXISTS user_profiles;
   
   -- Revert RLS policies
   ALTER TABLE children DISABLE ROW LEVEL SECURITY;
   ALTER TABLE stories DISABLE ROW LEVEL SECURITY;
   
   -- Remove user_id columns
   ALTER TABLE children DROP COLUMN IF EXISTS user_id;
   ALTER TABLE stories DROP COLUMN IF EXISTS user_id;
   ```

3. **Backend Rollback:**
   - Remove authentication middleware from routes
   - Revert to previous API version

## Support & Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [React Router Documentation](https://reactrouter.com/)
- [Vite Deployment Guide](https://vitejs.dev/guide/static-deploy.html)
- [Tailwind CSS Production Build](https://tailwindcss.com/docs/optimizing-for-production)

## Troubleshooting

### "User profile not created"
- Check Supabase logs for insert errors
- Verify RLS policies allow insert for authenticated users
- Ensure `auth.uid()` matches user ID

### "CORS errors in production"
- Update FastAPI CORS settings to include frontend URL
- Check Supabase allowed origins in dashboard

### "Session not persisting"
- Verify `persistSession: true` in Supabase client config
- Check browser localStorage/cookies aren't blocked
- Ensure same-site cookie settings are correct

### "Email not sending"
- Check Supabase email settings
- Verify email templates are configured
- Check spam folder for test emails
- Consider using custom SMTP provider
