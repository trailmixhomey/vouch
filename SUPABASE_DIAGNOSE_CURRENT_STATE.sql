-- SUPABASE_DIAGNOSE_CURRENT_STATE.sql
-- Diagnostic script to understand the current database state

-- Step 1: Check current reviews table structure
SELECT 'CURRENT REVIEWS TABLE STRUCTURE:' as info;
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default,
  character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'reviews' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 2: Check if views exist
SELECT 'EXISTING VIEWS:' as info;
SELECT 
  schemaname,
  viewname,
  definition
FROM pg_views 
WHERE schemaname = 'public' 
  AND viewname LIKE '%review%';

-- Step 3: Check constraints on reviews table
SELECT 'CONSTRAINTS ON REVIEWS TABLE:' as info;
SELECT 
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.reviews'::regclass;

-- Step 4: Check if we have any actual review data
SELECT 'SAMPLE REVIEW DATA:' as info;
SELECT 
  id,
  CASE WHEN restaurant_name IS NOT NULL THEN 'restaurant_name: ' || restaurant_name ELSE 'restaurant_name: NULL' END,
  CASE WHEN title IS NOT NULL THEN 'title: ' || title ELSE 'title: NULL' END,
  CASE WHEN review_text IS NOT NULL THEN 'review_text: ' || LEFT(review_text, 50) || '...' ELSE 'review_text: NULL' END,
  CASE WHEN content IS NOT NULL THEN 'content: ' || LEFT(content, 50) || '...' ELSE 'content: NULL' END,
  rating,
  created_at
FROM public.reviews 
LIMIT 3;

-- Step 5: Check RLS policies
SELECT 'RLS POLICIES ON REVIEWS:' as info;
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'reviews';

-- Step 6: Test if PostgREST can see the table
SELECT 'POSTGREST SCHEMA CACHE STATUS:' as info;
SELECT 'Run this in PostgREST: GET /reviews?limit=1' as test_instruction; 