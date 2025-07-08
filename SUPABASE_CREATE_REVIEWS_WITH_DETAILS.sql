-- Create the proper reviews_with_details view with aggregated counts

-- Drop the existing view if it exists
DROP VIEW IF EXISTS public.reviews_with_details;

-- Create the new view with proper aggregated counts
CREATE VIEW public.reviews_with_details AS
SELECT 
    r.*,
    u.username,
    u.display_name,
    u.avatar_url,
    COALESCE(like_counts.likes_count, 0) as likes_count,
    COALESCE(bookmark_counts.bookmarks_count, 0) as bookmarks_count,
    COALESCE(comment_counts.comments_count, 0) as comments_count
FROM public.reviews r
JOIN public.users u ON r.user_id = u.id
LEFT JOIN (
    SELECT 
        review_id, 
        COUNT(*) as likes_count
    FROM public.likes
    GROUP BY review_id
) like_counts ON r.id = like_counts.review_id
LEFT JOIN (
    SELECT 
        review_id, 
        COUNT(*) as bookmarks_count
    FROM public.bookmarks
    GROUP BY review_id
) bookmark_counts ON r.id = bookmark_counts.review_id
LEFT JOIN (
    SELECT 
        review_id, 
        COUNT(*) as comments_count
    FROM public.comments
    GROUP BY review_id
) comment_counts ON r.id = comment_counts.review_id;

-- Grant permissions on the view
GRANT SELECT ON public.reviews_with_details TO anon, authenticated;

-- Refresh the PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Test the new view
SELECT 
    'Testing new view:' as test,
    title,
    comments_count,
    likes_count,
    bookmarks_count
FROM public.reviews_with_details
ORDER BY created_at DESC;

-- Success message
DO $$ 
BEGIN 
    RAISE NOTICE 'reviews_with_details view created successfully with comment counts! 🎉';
END $$; 