-- SUPABASE_FORCE_SCHEMA_REFRESH.sql
-- This script forces PostgREST to refresh its schema cache to recognize the reviews/users relationship

-- Force PostgREST to refresh its schema cache
NOTIFY pgrst, 'reload schema';

-- Ensure the foreign key relationship exists and is properly named
ALTER TABLE public.reviews 
DROP CONSTRAINT IF EXISTS reviews_user_id_fkey;

ALTER TABLE public.reviews 
ADD CONSTRAINT reviews_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES public.users(id) 
ON DELETE CASCADE;

-- Also ensure we have the proper indexes for performance
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON public.reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON public.reviews(created_at);

-- Refresh the schema cache again after all changes
NOTIFY pgrst, 'reload schema';

-- Verify the relationship exists
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name='reviews'
    AND tc.table_schema='public'; 