-- SUPABASE_BASIC_DIAGNOSTIC.sql
-- Simple diagnostic to check what tables actually exist

-- Step 1: Check if reviews table exists at all
SELECT 'CHECKING IF REVIEWS TABLE EXISTS:' as info;
SELECT 
  table_name,
  table_schema
FROM information_schema.tables 
WHERE table_name = 'reviews';

-- Step 2: List all tables in public schema
SELECT 'ALL TABLES IN PUBLIC SCHEMA:' as info;
SELECT 
  table_name,
  table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Step 3: Check current user and permissions
SELECT 'CURRENT USER AND ROLE:' as info;
SELECT 
  current_user,
  current_role,
  session_user; 