-- SUPABASE_STEP_BY_STEP.sql
-- Run these queries ONE AT A TIME to isolate issues

-- Query 1: Check if reviews table exists
SELECT 
  table_name,
  table_schema
FROM information_schema.tables 
WHERE table_name = 'reviews';

-- Query 2: List all tables (run this separately)
-- SELECT 
--   table_name,
--   table_type
-- FROM information_schema.tables 
-- WHERE table_schema = 'public'
-- ORDER BY table_name;

-- Query 3: If reviews table exists, check its structure (run this separately)
-- SELECT 
--   column_name, 
--   data_type, 
--   is_nullable
-- FROM information_schema.columns 
-- WHERE table_name = 'reviews' AND table_schema = 'public'
-- ORDER BY ordinal_position; 