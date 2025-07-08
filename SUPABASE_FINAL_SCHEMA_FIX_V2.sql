-- SUPABASE_FINAL_SCHEMA_FIX_V2.sql
-- Final fix for reviews table schema mismatch (handles view dependencies)

-- Step 1: Check current table structure
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'reviews' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 2: Drop dependent views that prevent column alterations
DROP VIEW IF EXISTS public.reviews_with_details CASCADE;
DROP VIEW IF EXISTS public.reviews_with_users CASCADE;

-- Step 3: Drop the NOT NULL constraint on restaurant_name (if it exists)
ALTER TABLE public.reviews ALTER COLUMN restaurant_name DROP NOT NULL;

-- Step 4: Add new columns if they don't exist
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS content TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS image_urls TEXT[];

-- Step 5: Migrate data from old columns to new columns
UPDATE public.reviews 
SET 
  title = COALESCE(restaurant_name, 'Untitled Review'),
  content = COALESCE(review_text, 'No content provided'),
  category = 'restaurant',
  image_urls = CASE 
    WHEN image_url IS NOT NULL THEN ARRAY[image_url]
    ELSE ARRAY[]::TEXT[]
  END
WHERE title IS NULL OR content IS NULL;

-- Step 6: Make new columns NOT NULL after data migration
ALTER TABLE public.reviews ALTER COLUMN title SET NOT NULL;
ALTER TABLE public.reviews ALTER COLUMN content SET NOT NULL;
ALTER TABLE public.reviews ALTER COLUMN category SET NOT NULL;
ALTER TABLE public.reviews ALTER COLUMN image_urls SET NOT NULL;

-- Step 7: Update rating column to DECIMAL (now that views are dropped)
ALTER TABLE public.reviews ALTER COLUMN rating TYPE DECIMAL(3,1);

-- Step 8: Recreate the reviews_with_details view with new schema
CREATE OR REPLACE VIEW public.reviews_with_details AS
SELECT 
  r.id,
  r.title,
  r.content,
  r.rating,
  r.category,
  r.image_urls,
  r.user_id,
  r.created_at,
  r.updated_at,
  u.username,
  u.display_name,
  u.avatar_url,
  -- Count aggregations
  COALESCE(l.like_count, 0) as like_count,
  COALESCE(c.comment_count, 0) as comment_count,
  COALESCE(b.bookmark_count, 0) as bookmark_count
FROM public.reviews r
LEFT JOIN public.users u ON r.user_id = u.id
LEFT JOIN (
  SELECT review_id, COUNT(*) as like_count 
  FROM public.likes 
  GROUP BY review_id
) l ON r.id = l.review_id
LEFT JOIN (
  SELECT review_id, COUNT(*) as comment_count 
  FROM public.comments 
  GROUP BY review_id
) c ON r.id = c.review_id
LEFT JOIN (
  SELECT review_id, COUNT(*) as bookmark_count 
  FROM public.bookmarks 
  GROUP BY review_id
) b ON r.id = b.review_id;

-- Step 9: Enable RLS on the view
ALTER VIEW public.reviews_with_details OWNER TO postgres;

-- Step 10: Create RLS policies for the view
CREATE POLICY "Allow all operations on reviews_with_details" ON public.reviews_with_details
  FOR ALL USING (true);

-- Step 11: Drop old columns (optional - uncomment if you want to remove them)
-- ALTER TABLE public.reviews DROP COLUMN IF EXISTS restaurant_name;
-- ALTER TABLE public.reviews DROP COLUMN IF EXISTS review_text;
-- ALTER TABLE public.reviews DROP COLUMN IF EXISTS image_url;

-- Step 12: Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Step 13: Verify final schema
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'reviews' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 14: Test the view
SELECT COUNT(*) as total_reviews FROM public.reviews_with_details; 