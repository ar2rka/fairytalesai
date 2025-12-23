# Subscription Purchase System - Quick Start Guide

## Overview

The subscription purchase system enables users to upgrade their plans through a complete purchase workflow with mock payment processing. This guide helps you get started with the new purchase functionality.

## What's New

- **Plan Selection Page**: Browse and compare all available subscription tiers
- **Checkout Flow**: Complete purchase workflow with payment confirmation
- **Purchase History**: View transaction history for transparency
- **Mock Payments**: Simulated payment processing for development

## Quick Setup

### 1. Apply Database Migration

Run the purchase transactions migration:

```bash
# Using Supabase CLI
cd /Users/igorkram/projects/tale-generator
supabase db push

# Or apply directly to your database
psql -f supabase/migrations/021_add_purchase_transactions.sql
```

### 2. Start Backend Server

```bash
uvicorn main:create_app --reload
```

### 3. Start Frontend Development Server

```bash
cd frontend
npm run dev
```

## User Workflow

### Viewing Available Plans

1. Navigate to `/subscription` page
2. Click "View Plans" button
3. Toggle between Monthly and Annual billing
4. Compare features across all tiers

### Purchasing an Upgrade

1. Select desired plan from Plans page
2. Click "Select Plan" button
3. Review order summary on Checkout page
4. Choose payment method (mock options available)
5. Accept terms and conditions
6. Click "Complete Purchase"

### Viewing Purchase History

1. Go to `/subscription` page
2. Click "View History" button
3. See all transaction records with status

## API Endpoints

### Get Available Plans

```bash
GET /api/v1/subscription/plans
Authorization: Bearer <token>
```

Response:
```json
{
  "plans": [
    {
      "tier": "starter",
      "display_name": "Starter Plan",
      "monthly_price": 9.99,
      "annual_price": 99.99,
      "features": [...],
      "is_purchasable": true,
      "is_current": false
    }
  ],
  "current_plan": "free"
}
```

### Purchase Subscription

```bash
POST /api/v1/subscription/purchase
Authorization: Bearer <token>
Content-Type: application/json

{
  "plan_tier": "starter",
  "billing_cycle": "monthly",
  "payment_method": "mock_card"
}
```

Success Response:
```json
{
  "success": true,
  "transaction_id": "uuid",
  "subscription": {
    "plan": "starter",
    "status": "active",
    "start_date": "2025-12-07T18:00:00Z",
    "end_date": "2026-01-06T18:00:00Z"
  },
  "message": "Successfully upgraded to starter plan"
}
```

### Get Purchase History

```bash
GET /api/v1/subscription/purchases?limit=10
Authorization: Bearer <token>
```

Response:
```json
{
  "transactions": [
    {
      "id": "uuid",
      "from_plan": "free",
      "to_plan": "starter",
      "amount": 9.99,
      "currency": "USD",
      "payment_status": "completed",
      "created_at": "2025-12-07T18:00:00Z"
    }
  ],
  "total": 1,
  "has_more": false
}
```

## Mock Payment Methods

For testing different payment scenarios:

| Payment Method | Result |
|---------------|--------|
| `mock_card` | ✅ Success - Payment completes successfully |
| `mock_card_declined` | ❌ Failure - Insufficient funds |
| `mock_card_expired` | ❌ Failure - Expired payment method |
| `mock_network_error` | ❌ Failure - Network timeout |
| `mock_fraud_detected` | ❌ Failure - Fraud prevention |

## Plan Pricing

### Monthly Billing

- **Starter**: $9.99/month
- **Normal**: $19.99/month
- **Premium**: $39.99/month

### Annual Billing (17% discount)

- **Starter**: $99.99/year ($8.33/month)
- **Normal**: $199.99/year ($16.67/month)
- **Premium**: $399.99/year ($33.33/month)

## Valid Upgrade Paths

- Free → Starter, Normal, or Premium
- Starter → Normal or Premium
- Normal → Premium
- Premium → (no upgrades available)

## Testing

Run the test suite to verify functionality:

```bash
python3 test_purchase_system.py
```

Expected output:
```
✅ ALL TESTS PASSED!

The subscription purchase system is working correctly:
  • Plan catalog and pricing configured
  • Upgrade validation logic functional
  • Mock payment provider operational
  • Purchase workflow complete
  • Billing cycles and discounts verified
```

## Database Schema

### purchase_transactions Table

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Transaction identifier |
| user_id | UUID | User who made purchase |
| from_plan | TEXT | Plan before upgrade |
| to_plan | TEXT | Plan after upgrade |
| amount | DECIMAL | Purchase amount |
| currency | TEXT | Currency (USD) |
| payment_status | TEXT | completed/failed/pending |
| payment_method | TEXT | Payment method used |
| payment_provider | TEXT | Provider (mock) |
| transaction_reference | TEXT | Payment reference |
| created_at | TIMESTAMPTZ | Creation timestamp |
| completed_at | TIMESTAMPTZ | Completion timestamp |
| metadata | JSONB | Additional data |

## Development Notes

### Mock Payment Provider

The `MockPaymentProvider` simulates real payment processing:

- Configurable success rate
- Simulated processing delay (1.5 seconds default)
- Generates unique transaction references
- Supports failure scenario testing

### Migration to Real Payments

The system is designed for easy migration to real payment providers:

1. Implement new provider class (e.g., `StripePaymentProvider`)
2. Extend `PaymentProvider` interface
3. Update configuration to use production provider
4. All purchase logic remains unchanged

Example:
```python
# Switch from mock to Stripe
from src.domain.services.payment_provider import StripePaymentProvider

payment_provider = StripePaymentProvider(api_key=STRIPE_API_KEY)
purchase_service = PurchaseService(payment_provider)
```

## Frontend Components

### PlansPage
- **Route**: `/subscription/plans`
- **Features**: Plan comparison, billing toggle, current plan indicator

### CheckoutPage
- **Route**: `/subscription/checkout`
- **Features**: Order summary, payment method selection, terms acceptance

### SubscriptionPage (Enhanced)
- **Route**: `/subscription`
- **New Features**: Purchase history table, upgrade CTA with link to plans

## Troubleshooting

### Purchase Fails with "Subscription not found"

Ensure user has completed registration and has a user_profile record with subscription fields.

### Frontend Cannot Load Plans

Check that backend API is running on `http://localhost:8000` and CORS is configured.

### Transaction Not Appearing in History

Verify database migration was applied and RLS policies allow user to read their own transactions.

### Test Failures

Ensure all dependencies are installed:
```bash
pip install -r requirements.txt
```

## Security Considerations

- All endpoints require JWT authentication
- Row-level security prevents users from viewing others' transactions
- Payment method validation before processing
- Transaction audit trail cannot be deleted

## Next Steps

1. Apply the database migration
2. Test the purchase flow with mock payments
3. Review purchase history functionality
4. Plan integration with real payment provider (Stripe/Paddle)
5. Add email notifications for successful purchases

## Support

For issues or questions:
- Review test file: `test_purchase_system.py`
- Check design document: `.qoder/quests/subscription-creation.md`
- Examine implementation files in `src/domain/services/`

## Files Modified/Created

### Backend
- ✅ `supabase/migrations/021_add_purchase_transactions.sql` (NEW)
- ✅ `src/domain/services/payment_provider.py` (NEW)
- ✅ `src/domain/services/plan_catalog.py` (NEW)
- ✅ `src/domain/services/purchase_service.py` (NEW)
- ✅ `src/supabase_client.py` (MODIFIED)
- ✅ `src/supabase_client_async.py` (MODIFIED)
- ✅ `src/api/routes.py` (MODIFIED)
- ✅ `test_purchase_system.py` (NEW)

### Frontend
- ✅ `frontend/src/pages/subscription/PlansPage.tsx` (NEW)
- ✅ `frontend/src/pages/subscription/CheckoutPage.tsx` (NEW)
- ✅ `frontend/src/pages/subscription/SubscriptionPage.tsx` (MODIFIED)
- ✅ `frontend/src/App.tsx` (MODIFIED)

## Success Metrics

- ✅ Users can view all available plans
- ✅ Users can select and purchase plan upgrades
- ✅ Payment processing simulated successfully
- ✅ Transactions recorded in database
- ✅ Subscriptions updated immediately upon success
- ✅ Purchase history accessible to users
- ✅ All tests passing
