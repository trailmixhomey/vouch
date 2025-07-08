-- SUPABASE_FINAL_SCHEMA_FIX.sql
-- Final fix for reviews table schema mismatch

-- Step 1: Check current table structure
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'reviews' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 2: Drop the NOT NULL constraint on restaurant_name (if it exists)
ALTER TABLE public.reviews ALTER COLUMN restaurant_name DROP NOT NULL;

-- Step 3: Add new columns if they don't exist
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS content TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS image_urls TEXT[];

-- Step 4: Migrate data from old columns to new columns
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

-- Step 5: Make new columns NOT NULL after data migration
ALTER TABLE public.reviews ALTER COLUMN title SET NOT NULL;
ALTER TABLE public.reviews ALTER COLUMN content SET NOT NULL;
ALTER TABLE public.reviews ALTER COLUMN category SET NOT NULL;
ALTER TABLE public.reviews ALTER COLUMN image_urls SET NOT NULL;

-- Step 6: Update rating column to DECIMAL if it's still INTEGER
ALTER TABLE public.reviews ALTER COLUMN rating TYPE DECIMAL(3,1);

-- Step 7: Drop old columns (optional - comment out if you want to keep them)
-- ALTER TABLE public.reviews DROP COLUMN IF EXISTS restaurant_name;
-- ALTER TABLE public.reviews DROP COLUMN IF EXISTS review_text;
-- ALTER TABLE public.reviews DROP COLUMN IF EXISTS image_url;

-- Step 8: Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Step 9: Verify final schema
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'reviews' AND table_schema = 'public'
ORDER BY ordinal_position; 