# Edge Function Error Fix

## Problem
Error "Failed to send a request to the Edge Function" appeared on the `/subscription/plans` page.

## Root Cause
The frontend was trying to call `supabase.functions.invoke()` to access the API endpoint, but the application uses FastAPI backend on `http://localhost:8000`, not Supabase Edge Functions.

## Solution
Changed the API call from Supabase Edge Function invocation to a standard `fetch()` request to the FastAPI backend.

## Changes Made

### File: `frontend/src/pages/subscription/PlansPage.tsx`

**Before:**
```typescript
import { supabase } from '../../services/supabase';

const fetchPlans = async () => {
  try {
    setLoading(true);
    setError(null);

    const { data, error: apiError } = await supabase.functions.invoke('api/v1/subscription/plans', {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${session?.access_token}`,
      },
    });

    if (apiError) throw apiError;

    const plansData = data as PlansResponse;
    setPlans(plansData.plans);
    setCurrentPlan(plansData.current_plan);
  } catch (err: any) {
    console.error('Error fetching plans:', err);
    setError(err.message || 'Failed to load subscription plans');
  } finally {
    setLoading(false);
  }
};
```

**After:**
```typescript
const fetchPlans = async () => {
  try {
    setLoading(true);
    setError(null);

    const response = await fetch('http://localhost:8000/api/v1/subscription/plans', {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${session?.access_token}`,
      },
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.detail || 'Failed to load subscription plans');
    }

    const plansData = await response.json() as PlansResponse;
    setPlans(plansData.plans);
    setCurrentPlan(plansData.current_plan);
  } catch (err: any) {
    console.error('Error fetching plans:', err);
    setError(err.message || 'Failed to load subscription plans');
  } finally {
    setLoading(false);
  }
};
```

**Also removed unused import:**
```typescript
// Removed
import { supabase } from '../../services/supabase';
```

## Backend Endpoint
The backend endpoint `/api/v1/subscription/plans` is correctly implemented in `src/api/routes.py` (line 918) and requires authentication.

## Testing
To verify the fix works:

1. Start the backend server:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

2. Start the frontend:
   ```bash
   cd frontend && npm run dev
   ```

3. Navigate to `/subscription/plans`
4. The page should load without "Edge Function" errors

## Related Files
- `frontend/src/pages/subscription/PlansPage.tsx` - Fixed page
- `src/api/routes.py` - Backend endpoint (line 918-974)
- `src/domain/services/plan_catalog.py` - Plan definitions

## Notes
- The application uses FastAPI for the backend, not Supabase Edge Functions
- All API calls should use `fetch()` with `http://localhost:8000/api/v1/...`
- Authentication is handled via Bearer token in the Authorization header
