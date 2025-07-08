-- Debug Comment Counts and Reviews View
-- This script helps diagnose why comment counts are showing as 0

-- First, let's check if comments exist
SELECT 'Comments in database:' as check_type, count(*) as count FROM public.comments;

-- Check comments for a specific review (replace with actual review ID)
SELECT 
    'Comments for specific review:' as check_type,
    r.title,
    r.id as review_id,
    count(c.id) as comment_count
FROM public.reviews r
LEFT JOIN public.comments c ON r.id = c.review_id
WHERE r.title LIKE '%Decode%'
GROUP BY r.id, r.title;

-- Check the reviews_with_details view
SELECT 
    'Reviews with details view:' as check_type,
    title,
    comments_count,
    likes_count,
    bookmarks_count
FROM public.reviews_with_details
WHERE title LIKE '%Decode%';

-- Check if the view exists
SELECT 
    'View exists:' as check_type,
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE viewname = 'reviews_with_details';

-- Manual count to verify
SELECT 
    'Manual count verification:' as check_type,
    r.title,
    r.id,
    COUNT(DISTINCT l.id) as likes_count,
    COUNT(DISTINCT b.id) as bookmarks_count,
    COUNT(DISTINCT c.id) as comments_count
FROM public.reviews r
LEFT JOIN public.likes l ON r.id = l.review_id
LEFT JOIN public.bookmarks b ON r.id = b.review_id
LEFT JOIN public.comments c ON r.id = c.review_id
GROUP BY r.id, r.title
ORDER BY r.created_at DESC;

-- Check if there's an issue with the view definition
DROP VIEW IF EXISTS public.reviews_with_details;

CREATE OR REPLACE VIEW public.reviews_with_details AS
SELECT 
    r.*,
    u.username,
    u.display_name,
    u.avatar_url,
    COALESCE(likes.count, 0) as likes_count,
    COALESCE(bookmarks.count, 0) as bookmarks_count,
    COALESCE(comments.count, 0) as comments_count
FROM public.reviews r
JOIN public.users u ON r.user_id = u.id
LEFT JOIN (
    SELECT review_id, COUNT(*) as count
    FROM public.likes
    GROUP BY review_id
) likes ON r.id = likes.review_id
LEFT JOIN (
    SELECT review_id, COUNT(*) as count
    FROM public.bookmarks
    GROUP BY review_id
) bookmarks ON r.id = bookmarks.review_id
LEFT JOIN (
    SELECT review_id, COUNT(*) as count
    FROM public.comments
    GROUP BY review_id
) comments ON r.id = comments.review_id;

-- Grant permissions
GRANT SELECT ON public.reviews_with_details TO anon, authenticated;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';

-- Test the updated view
SELECT 
    'Updated view test:' as check_type,
    title,
    comments_count,
    likes_count,
    bookmarks_count
FROM public.reviews_with_details
ORDER BY created_at DESC;

-- Success message
DO $$ 
BEGIN 
    RAISE NOTICE 'Comment counts debug complete! Check the results above. 🔍';
END $$; 