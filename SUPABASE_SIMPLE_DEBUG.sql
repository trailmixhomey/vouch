-- Simple diagnostic to check what exists

-- Check if comments exist
SELECT 'Total comments:' as info, count(*) as count FROM public.comments;

-- Check what views exist
SELECT 'Existing views:' as info, viewname as name FROM pg_views WHERE schemaname = 'public';

-- Check if reviews_with_details view exists and what columns it has
SELECT 
    'reviews_with_details columns:' as info,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'reviews_with_details' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Manual count for "Decode" review
SELECT 
    'Manual count for Decode review:' as info,
    r.title,
    COUNT(c.id) as actual_comment_count
FROM public.reviews r
LEFT JOIN public.comments c ON r.id = c.review_id
WHERE r.title ILIKE '%decode%'
GROUP BY r.id, r.title; 