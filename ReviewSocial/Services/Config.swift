import Foundation

struct Config {
    static let supabaseURL = "https://mqiqknpxfloxuxscpjhr.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xaXFrbnB4ZmxveHV4c2NwamhyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcyODg0MTgsImV4cCI6MjA2Mjg2NDQxOH0.ZZ1CZ8Obh9yP5LbFqIHLEdx5f-MjLr4kN1C1U7QMzYc"
    

}

// MARK: - Database Schema Information
/*
 Create these tables in your Supabase database:
 
 1. users (extends auth.users)
 CREATE TABLE public.users (
     id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
     username TEXT UNIQUE NOT NULL,
     display_name TEXT,
     bio TEXT,
     avatar_url TEXT,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
 2. reviews
 CREATE TABLE public.reviews (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
     restaurant_name TEXT NOT NULL,
     rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
     review_text TEXT NOT NULL,
     image_url TEXT,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
 3. likes
 CREATE TABLE public.likes (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
     review_id UUID REFERENCES public.reviews(id) ON DELETE CASCADE NOT NULL,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     UNIQUE(user_id, review_id)
 );
 
 4. bookmarks
 CREATE TABLE public.bookmarks (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
     review_id UUID REFERENCES public.reviews(id) ON DELETE CASCADE NOT NULL,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     UNIQUE(user_id, review_id)
 );
 
 5. comments
 CREATE TABLE public.comments (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     review_id UUID REFERENCES public.reviews(id) ON DELETE CASCADE NOT NULL,
     user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
     content TEXT NOT NULL,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
 6. follows
 CREATE TABLE public.follows (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     follower_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
     following_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     UNIQUE(follower_id, following_id)
 );
 
 -- Enable Row Level Security
 ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
 ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
 ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
 ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
 ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
 ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
 
 -- Create policies (basic examples)
 CREATE POLICY "Users can view all profiles" ON public.users FOR SELECT USING (true);
 CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
 
 CREATE POLICY "Reviews are viewable by everyone" ON public.reviews FOR SELECT USING (true);
 CREATE POLICY "Users can create reviews" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
 CREATE POLICY "Users can update own reviews" ON public.reviews FOR UPDATE USING (auth.uid() = user_id);
 CREATE POLICY "Users can delete own reviews" ON public.reviews FOR DELETE USING (auth.uid() = user_id);
 
 CREATE POLICY "Users can manage their own likes" ON public.likes FOR ALL USING (auth.uid() = user_id);
 CREATE POLICY "Users can manage their own bookmarks" ON public.bookmarks FOR ALL USING (auth.uid() = user_id);
 CREATE POLICY "Users can manage their own comments" ON public.comments FOR ALL USING (auth.uid() = user_id);
 CREATE POLICY "Comments are viewable by everyone" ON public.comments FOR SELECT USING (true);
 
 CREATE POLICY "Users can manage their own follows" ON public.follows FOR ALL USING (auth.uid() = follower_id);
 CREATE POLICY "Follows are viewable by everyone" ON public.follows FOR SELECT USING (true);
 
 -- Create storage bucket for avatars
 INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
 
 -- Create storage policy for avatars
 CREATE POLICY "Avatar images are publicly accessible" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
 CREATE POLICY "Users can upload their own avatar" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
 CREATE POLICY "Users can update their own avatar" ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
 CREATE POLICY "Users can delete their own avatar" ON storage.objects FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
 */ 