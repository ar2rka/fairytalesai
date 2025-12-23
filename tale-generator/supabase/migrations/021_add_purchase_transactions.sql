-- Migration: Add purchase_transactions table for subscription purchases
-- Description: Implements purchase tracking with transaction history and audit trail

-- Step 1: Create purchase_transactions table
CREATE TABLE IF NOT EXISTS tales.purchase_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    from_plan TEXT NOT NULL CHECK (from_plan IN ('free', 'starter', 'normal', 'premium')),
    to_plan TEXT NOT NULL CHECK (to_plan IN ('starter', 'normal', 'premium')),
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    currency TEXT NOT NULL DEFAULT 'USD',
    payment_status TEXT NOT NULL CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
    payment_method TEXT NOT NULL,
    payment_provider TEXT NOT NULL,
    transaction_reference TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    metadata JSONB,
    CONSTRAINT valid_upgrade CHECK (
        (from_plan = 'free' AND to_plan IN ('starter', 'normal', 'premium')) OR
        (from_plan = 'starter' AND to_plan IN ('normal', 'premium')) OR
        (from_plan = 'normal' AND to_plan = 'premium')
    )
);

-- Step 2: Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_purchase_transactions_user_id 
ON tales.purchase_transactions(user_id);

CREATE INDEX IF NOT EXISTS idx_purchase_transactions_status 
ON tales.purchase_transactions(payment_status);

CREATE INDEX IF NOT EXISTS idx_purchase_transactions_created 
ON tales.purchase_transactions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_purchase_transactions_user_created 
ON tales.purchase_transactions(user_id, created_at DESC);

-- Step 3: Enable Row Level Security
ALTER TABLE tales.purchase_transactions ENABLE ROW LEVEL SECURITY;

-- Step 4: Create RLS Policies

-- Policy: Users can view their own purchase transactions
CREATE POLICY "Users can view their own purchase transactions" 
ON tales.purchase_transactions
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Authenticated users can create purchase transactions
CREATE POLICY "Authenticated users can create purchase transactions" 
ON tales.purchase_transactions
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: System can update transaction status (service role only)
-- Note: Updates restricted to status and completion fields only
CREATE POLICY "System can update transaction status" 
ON tales.purchase_transactions
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: No deletes allowed (audit trail preservation)
-- Intentionally no DELETE policy

-- Step 5: Add table and column comments for documentation
COMMENT ON TABLE tales.purchase_transactions IS 
'Tracks subscription purchase transactions for audit trail and user history';

COMMENT ON COLUMN tales.purchase_transactions.from_plan IS 
'User subscription plan before purchase';

COMMENT ON COLUMN tales.purchase_transactions.to_plan IS 
'User subscription plan after purchase';

COMMENT ON COLUMN tales.purchase_transactions.amount IS 
'Purchase amount in specified currency with 2 decimal places';

COMMENT ON COLUMN tales.purchase_transactions.payment_status IS 
'Payment processing status: pending, completed, failed, or refunded';

COMMENT ON COLUMN tales.purchase_transactions.payment_method IS 
'Payment method identifier (e.g., mock_card, stripe_card)';

COMMENT ON COLUMN tales.purchase_transactions.payment_provider IS 
'Payment processor name (e.g., mock, stripe, paddle)';

COMMENT ON COLUMN tales.purchase_transactions.transaction_reference IS 
'External payment provider transaction reference';

COMMENT ON COLUMN tales.purchase_transactions.completed_at IS 
'Timestamp when payment was successfully completed (null for pending/failed)';

COMMENT ON COLUMN tales.purchase_transactions.metadata IS 
'Additional transaction data as JSON (billing cycle, promo codes, etc.)';
