-- Basic check without referencing problematic columns

-- Check if comments exist
SELECT 'Total comments in database:' as info, count(*) as count FROM public.comments;

-- Check what views exist in public schema
SELECT 'Existing public views:' as info, viewname as name FROM pg_views WHERE schemaname = 'public';

-- Check reviews table
SELECT 'Total reviews:' as info, count(*) as count FROM public.reviews;

-- Manual comment count for all reviews
SELECT 
    'Comment counts per review:' as info,
    r.title,
    r.id,
    COUNT(c.id) as comment_count
FROM public.reviews r
LEFT JOIN public.comments c ON r.id = c.review_id
GROUP BY r.id, r.title
ORDER BY r.created_at DESC; 