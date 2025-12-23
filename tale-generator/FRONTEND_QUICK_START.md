# Quick Start - Frontend Registration

Get the Tale Generator frontend up and running in 5 minutes!

## Prerequisites

- Node.js 18+ installed
- Supabase project created
- Supabase credentials ready

## Step 1: Configure Environment

Create environment file:

```bash
cd frontend
cp .env.example .env
```

Edit `frontend/.env`:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key_here
```

Get these values from your Supabase Dashboard → Settings → API

## Step 2: Run Database Migration

1. Open Supabase Dashboard → SQL Editor
2. Copy content from `supabase/migrations/012_add_user_authentication.sql`
3. Execute the SQL

This creates the user authentication tables and security policies.

## Step 3: Configure Supabase Auth

In Supabase Dashboard → Authentication → URL Configuration:

**Site URL:**
```
http://localhost:5173
```

**Redirect URLs:**
```
http://localhost:5173/reset-password/confirm
```

## Step 4: Install & Run

```bash
cd frontend
npm install
npm run dev
```

Visit: http://localhost:5173

## Step 5: Test Registration

1. Click "Create one now" or visit `/register`
2. Fill in:
   - Name: Your Name
   - Email: test@example.com
   - Password: Test1234
   - Confirm password
   - Accept terms
3. Click "Create Account"
4. You should be redirected to the dashboard!

## What's Next?

- ✅ **Registration works!** Users can create accounts
- ✅ **Login works!** Users can sign in
- ✅ **Protected routes!** Dashboard requires authentication
- ✅ **Password reset!** Users can recover accounts

### Add Authentication to Backend

Update your FastAPI endpoints:

```python
from fastapi import Depends
from src.api.auth import get_current_user, AuthUser

@router.post("/children")
async def create_child(
    data: dict,
    user: AuthUser = Depends(get_current_user)
):
    data['user_id'] = user.user_id
    # Save to database
```

### Deploy to Production

Follow the detailed guide in `FRONTEND_DEPLOYMENT_GUIDE.md`

## Troubleshooting

**Frontend won't start?**
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
```

**Environment variables not working?**
- Restart dev server after changing `.env`
- Ensure variables start with `VITE_`

**Can't create account?**
- Check Supabase Dashboard → Authentication → Users
- Verify migration ran successfully
- Check browser console for errors

**Need help?**
- Read `frontend/README.md` for detailed docs
- Check `FRONTEND_IMPLEMENTATION_SUMMARY.md` for overview
- Review Supabase logs for server errors

## Success! 🎉

Your frontend registration system is now running. Users can:
- Register new accounts
- Log in securely
- Reset forgotten passwords  
- Access protected content

Ready to build the rest of your application!
