# Quick Start Guide - Testing Authorization Fix

## Prerequisites
- Backend and frontend environment variables configured
- Supabase project with authentication enabled
- User account created in the system

## Testing Steps

### 1. Verify Implementation
```bash
# Run the implementation test
cd /Users/igorkram/projects/tale-generator
uv run python test_auth_implementation.py
```

Expected output: All checks should pass with ✓

### 2. Start the Backend Server
```bash
# Terminal 1 - Start backend
cd /Users/igorkram/projects/tale-generator
uv run python main.py
```

Expected output:
```
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### 3. Start the Frontend
```bash
# Terminal 2 - Start frontend
cd /Users/igorkram/projects/tale-generator/frontend
npm run dev
```

Expected output:
```
VITE v5.x.x  ready in xxx ms
➜  Local:   http://localhost:5173/
```

### 4. Test Authentication Flow

#### A. Login
1. Navigate to http://localhost:5173/login
2. Enter your credentials
3. Click "Sign In"
4. Should redirect to dashboard

#### B. Create/View Children
1. Navigate to "Children" section
2. Try to view existing children
3. Try to add a new child
4. Verify only your children are visible

#### C. Generate Story (Main Test)
1. Navigate to "Generate Story" page
2. Select a child from dropdown
3. Choose language (English or Russian)
4. Set story length
5. Click "Generate Story"
6. **Expected**: Story generates successfully without 401 errors
7. **Expected**: Story is saved and associated with your user account

#### D. View Stories
1. Navigate to stories list
2. Verify only your stories are displayed
3. Try to view a story detail
4. Try to rate a story
5. All operations should work without 401 errors

### 5. Test Data Isolation

To verify users can't access each other's data:

1. Create account A and generate some stories
2. Log out
3. Create account B
4. Try to access stories list
5. **Expected**: Account B sees no stories (only their own)

### 6. Test API Directly (Optional)

Using curl to test authentication:

```bash
# Get your JWT token from browser DevTools
# In browser console: localStorage.getItem('supabase.auth.token')
TOKEN="your-jwt-token-here"

# Test authenticated endpoint
curl -X GET "http://localhost:8000/api/v1/stories" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"

# Should return your stories

# Test without token (should fail)
curl -X GET "http://localhost:8000/api/v1/stories" \
  -H "Content-Type: application/json"

# Should return 401 Unauthorized
```

## Common Issues and Solutions

### Issue: 401 Unauthorized after login
**Solution**: 
- Check that frontend is sending Authorization header
- Verify token is valid in browser DevTools
- Check SUPABASE_URL and SUPABASE_KEY are correct

### Issue: Can see other users' data
**Solution**:
- Verify user_id is being passed to database queries
- Check that database has user_id column
- Ensure Row Level Security is enabled in Supabase

### Issue: Token validation fails
**Solution**:
- Check SUPABASE_JWT_SECRET is set (optional)
- Verify SUPABASE_URL is correct
- System will fall back to JWKS if JWT_SECRET not set

### Issue: 403 Forbidden when accessing own resources
**Solution**:
- Verify user_id in database matches token user_id
- Check that resources were created with correct user_id
- Review server logs for detailed error messages

## Verification Checklist

- [ ] Test script passes all checks
- [ ] Backend starts without errors
- [ ] Frontend starts without errors
- [ ] Login works successfully
- [ ] Can create child profiles
- [ ] Can view only own children
- [ ] Can generate stories without 401 errors
- [ ] Can view only own stories
- [ ] Can rate stories
- [ ] Can delete own stories
- [ ] Cannot access other users' data
- [ ] Logout works correctly

## Success Indicators

✅ Story generation completes without 401 errors
✅ Only user-specific data is visible
✅ All CRUD operations work correctly
✅ JWT token validation works (with or without JWT_SECRET)
✅ Frontend handles authentication state properly

## Logging and Debugging

Enable detailed logging:

```bash
# Backend logs
tail -f logs/tale_generator.log

# Or use verbose mode
LOG_LEVEL=DEBUG uv run python main.py
```

Check browser console for:
- JWT token presence
- API request headers
- Response status codes

## Next Steps After Testing

Once all tests pass:
1. Commit changes to version control
2. Deploy to staging environment
3. Run full regression test suite
4. Monitor authentication metrics
5. Deploy to production

## Support

If you encounter issues:
1. Check test output for specific failures
2. Review AUTHORIZATION_FIX_SUMMARY.md for details
3. Check server logs for authentication errors
4. Verify environment variables are set correctly
