-- Safe migration to update reviews table schema to match app expectations
-- This version handles the view dependency issue

-- Step 1: Drop the view that depends on the rating column
DROP VIEW IF EXISTS public.reviews_with_details;

-- Step 2: Add the new columns if they don't exist
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS content TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS image_urls TEXT[] DEFAULT '{}';

-- Step 3: Migrate existing data from old columns to new columns
UPDATE public.reviews 
SET 
    title = COALESCE(restaurant_name, 'Untitled Review'),
    content = COALESCE(review_text, 'No content'),
    category = 'restaurant',  -- Default all existing reviews to restaurant
    image_urls = CASE 
        WHEN image_url IS NOT NULL AND image_url != '' 
        THEN ARRAY[image_url] 
        ELSE '{}' 
    END
WHERE title IS NULL OR content IS NULL OR category IS NULL;

-- Step 4: Make the new columns NOT NULL after populating them
ALTER TABLE public.reviews ALTER COLUMN title SET NOT NULL;
ALTER TABLE public.reviews ALTER COLUMN content SET NOT NULL;
ALTER TABLE public.reviews ALTER COLUMN category SET NOT NULL;

-- Step 5: Add check constraint for category
ALTER TABLE public.reviews ADD CONSTRAINT reviews_category_check 
CHECK (category IN ('restaurant', 'movie', 'book', 'technology', 'travel', 'service', 'product'));

-- Step 6: Change rating column type (now that view is dropped)
ALTER TABLE public.reviews ALTER COLUMN rating TYPE DECIMAL(3,1) USING rating::DECIMAL(3,1);

-- Step 7: Add check constraint for rating
ALTER TABLE public.reviews ADD CONSTRAINT reviews_rating_check 
CHECK (rating >= 0 AND rating <= 5);

-- Step 8: Recreate the view with new schema
CREATE VIEW public.reviews_with_details AS
SELECT 
    r.id,
    r.user_id,
    r.title,
    r.content,
    r.rating,
    r.category,
    r.image_urls,
    r.created_at,
    r.updated_at,
    u.username,
    u.display_name,
    u.avatar_url
FROM public.reviews r
JOIN public.users u ON r.user_id = u.id;

-- Step 9: Grant permissions on the new view
GRANT SELECT ON public.reviews_with_details TO authenticated;

-- Step 10: Enable RLS on the view if needed
ALTER VIEW public.reviews_with_details OWNER TO postgres;

-- Step 11: Update RLS policies to work with new columns
DROP POLICY IF EXISTS "Users can view public reviews" ON public.reviews;
DROP POLICY IF EXISTS "Users can insert their own reviews" ON public.reviews;
DROP POLICY IF EXISTS "Users can update their own reviews" ON public.reviews;
DROP POLICY IF EXISTS "Users can delete their own reviews" ON public.reviews;

-- Recreate RLS policies with new schema
CREATE POLICY "Users can view public reviews" ON public.reviews
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own reviews" ON public.reviews
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reviews" ON public.reviews
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reviews" ON public.reviews
    FOR DELETE USING (auth.uid() = user_id);

-- Step 12: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON public.reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_category ON public.reviews(category);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON public.reviews(rating);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON public.reviews(created_at DESC);

-- Optional: After confirming everything works, you can drop the old columns
-- Uncomment these lines after testing:
-- ALTER TABLE public.reviews DROP COLUMN IF EXISTS restaurant_name;
-- ALTER TABLE public.reviews DROP COLUMN IF EXISTS review_text;
-- ALTER TABLE public.reviews DROP COLUMN IF EXISTS image_url;

COMMIT; 