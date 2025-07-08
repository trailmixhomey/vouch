-- Migration to update reviews table schema to match app expectations
-- Run this AFTER the initial setup to update the schema

-- First, add the new columns
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS content TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS image_urls TEXT[] DEFAULT '{}';

-- Migrate existing data from old columns to new columns
UPDATE public.reviews 
SET 
    title = restaurant_name,
    content = review_text,
    category = 'restaurant',  -- Default all existing reviews to restaurant
    image_urls = CASE 
        WHEN image_url IS NOT NULL AND image_url != '' 
        THEN ARRAY[image_url] 
        ELSE '{}' 
    END
WHERE title IS NULL OR content IS NULL;

-- Make the new columns NOT NULL after data migration
ALTER TABLE public.reviews ALTER COLUMN title SET NOT NULL;
ALTER TABLE public.reviews ALTER COLUMN content SET NOT NULL;
ALTER TABLE public.reviews ALTER COLUMN category SET NOT NULL;

-- Add check constraint for category
ALTER TABLE public.reviews ADD CONSTRAINT reviews_category_check 
    CHECK (category IN ('restaurant', 'movie', 'book', 'technology', 'travel', 'service', 'product'));

-- Change rating from INTEGER to DECIMAL to support decimal ratings
ALTER TABLE public.reviews ALTER COLUMN rating TYPE DECIMAL(3,1);
ALTER TABLE public.reviews ALTER COLUMN rating SET DEFAULT 0;
ALTER TABLE public.reviews DROP CONSTRAINT IF EXISTS reviews_rating_check;
ALTER TABLE public.reviews ADD CONSTRAINT reviews_rating_check 
    CHECK (rating >= 0 AND rating <= 5);

-- Drop old columns (commented out for safety - uncomment after verifying migration)
-- ALTER TABLE public.reviews DROP COLUMN IF EXISTS restaurant_name;
-- ALTER TABLE public.reviews DROP COLUMN IF EXISTS review_text;
-- ALTER TABLE public.reviews DROP COLUMN IF EXISTS image_url; 