-- Fix for "invalid input syntax for type uuid" error
-- Run this in Supabase SQL Editor

-- Option 1: If your transactions table has 'id' as UUID without a default
-- Add a default UUID generator:
ALTER TABLE transactions 
ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- Option 2: If your transactions table has 'id' as TEXT (like budgets)
-- Then the code should work, but verify the column type:
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'transactions' AND column_name = 'id';

-- Option 3: If you want to keep id as UUID but allow inserts without it
-- Make sure the default is set (run Option 1)

-- Verify the fix:
-- After running, try inserting a transaction from the app
-- The 'id' should be auto-generated

















