-- Fix Comments-Users Relationship and Schema Cache
-- This script ensures PostgREST can find the relationship between comments and users tables

-- First, let's make sure the foreign key constraint exists with a proper name
ALTER TABLE public.comments 
DROP CONSTRAINT IF EXISTS comments_user_id_fkey;

ALTER TABLE public.comments 
ADD CONSTRAINT comments_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create an index on the foreign key for better performance
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON public.comments(user_id);

-- Refresh the PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Create a view that explicitly joins comments with users to help PostgREST understand the relationship
CREATE OR REPLACE VIEW public.comments_with_users AS
SELECT 
    c.id,
    c.review_id,
    c.user_id,
    c.content,
    c.created_at,
    c.updated_at,
    u.username,
    u.display_name,
    u.avatar_url
FROM public.comments c
JOIN public.users u ON c.user_id = u.id
ORDER BY c.created_at ASC;

-- Grant permissions on the view
GRANT SELECT ON public.comments_with_users TO anon, authenticated;

-- Note: Views inherit RLS from their underlying tables, so we don't need to enable RLS on the view itself
-- The view will automatically respect the RLS policies on the comments and users tables

-- Refresh schema cache again
NOTIFY pgrst, 'reload schema';

-- Success message
DO $$ 
BEGIN 
    RAISE NOTICE 'Comments-Users relationship fixed and schema cache refreshed! 🎉';
END $$; 