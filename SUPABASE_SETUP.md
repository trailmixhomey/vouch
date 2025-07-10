# ReviewSocial Supabase Setup Guide

## 🚀 Your project is now connected to Supabase!

Your ReviewSocial iOS app has been configured to work with your Supabase project: `mqiqknpxfloxuxscpjhr`

## 📋 Next Steps

### 1. Add Supabase Package to Xcode

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies**
3. Enter this URL: `https://github.com/supabase/supabase-swift.git`
4. Choose version **2.0.0** or later
5. Click **Add Package**

### 2. Get Your Supabase Keys

1. Go to your [Supabase Dashboard](https://app.supabase.com/project/mqiqknpxfloxuxscpjhr)
2. Navigate to **Settings → API**
3. Copy your **anon public** key
4. Update `ReviewSocial/Services/Config.swift`:
   ```swift
   static let supabaseAnonKey = "your_actual_anon_key_here"
   ```

### 3. Set Up Your Database

Execute the following SQL in your Supabase SQL Editor:

```sql
-- Create users table (extends auth.users)
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    display_name TEXT,
    email TEXT,
    bio TEXT DEFAULT '',
    avatar_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    is_private BOOLEAN DEFAULT TRUE,
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    reviews_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create reviews table
CREATE TABLE public.reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    rating DECIMAL(2,1) NOT NULL CHECK (rating >= 1.0 AND rating <= 5.0),
    category TEXT NOT NULL,
    image_urls TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create likes table
CREATE TABLE public.likes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    review_id UUID REFERENCES public.reviews(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, review_id)
);

-- Create bookmarks table
CREATE TABLE public.bookmarks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    review_id UUID REFERENCES public.reviews(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, review_id)
);

-- Create comments table
CREATE TABLE public.comments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    review_id UUID REFERENCES public.reviews(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create follows table
CREATE TABLE public.follows (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    follower_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    following_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(follower_id, following_id)
);

-- Create follow_requests table
CREATE TABLE public.follow_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    requester_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    requested_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(requester_id, requested_id)
);

-- Create storage bucket for profile images
INSERT INTO storage.buckets (id, name, public) VALUES ('profile-images', 'profile-images', true);

-- Create storage policies for profile images
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects FOR SELECT USING (bucket_id = 'profile-images');
CREATE POLICY "Users can upload their own avatar" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'profile-images' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users can update their own avatar" ON storage.objects FOR UPDATE USING (bucket_id = 'profile-images' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users can delete their own avatar" ON storage.objects FOR DELETE USING (bucket_id = 'profile-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Create trigger function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, username, display_name, email, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', NEW.email),
        COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on auth.users
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### 4. Create Database Views

```sql
-- Drop existing views if they exist (to avoid "already exists" errors)
DROP VIEW IF EXISTS public.reviews_with_details;
DROP VIEW IF EXISTS public.comments_with_users;

-- Create reviews_with_details view for feed
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
    u.avatar_url,
    COALESCE(l.likes_count, 0) as likes_count,
    COALESCE(c.comments_count, 0) as comments_count
FROM public.reviews r
LEFT JOIN public.users u ON r.user_id = u.id
LEFT JOIN (
    SELECT review_id, COUNT(*) as likes_count
    FROM public.likes
    GROUP BY review_id
) l ON r.id = l.review_id
LEFT JOIN (
    SELECT review_id, COUNT(*) as comments_count
    FROM public.comments
    GROUP BY review_id
) c ON r.id = c.review_id;

-- Create comments_with_users view for comment display
CREATE VIEW public.comments_with_users AS
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
LEFT JOIN public.users u ON c.user_id = u.id;
```

### 5. Enable Row Level Security

```sql
-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follow_requests ENABLE ROW LEVEL SECURITY;
```

### 6. Create Security Policies

```sql
-- User policies
CREATE POLICY "Users can view all profiles" ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

-- Review policies
CREATE POLICY "Reviews are viewable by everyone" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Users can create reviews" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own reviews" ON public.reviews FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own reviews" ON public.reviews FOR DELETE USING (auth.uid() = user_id);

-- Like policies
CREATE POLICY "Users can manage their own likes" ON public.likes FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Likes are viewable by everyone" ON public.likes FOR SELECT USING (true);

-- Bookmark policies
CREATE POLICY "Users can manage their own bookmarks" ON public.bookmarks FOR ALL USING (auth.uid() = user_id);

-- Comment policies
CREATE POLICY "Users can manage their own comments" ON public.comments FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Comments are viewable by everyone" ON public.comments FOR SELECT USING (true);

-- Follow policies
CREATE POLICY "Users can manage their own follows" ON public.follows FOR ALL USING (auth.uid() = follower_id);
CREATE POLICY "Follows are viewable by everyone" ON public.follows FOR SELECT USING (true);

-- Follow request policies
CREATE POLICY "Users can view their own follow requests" ON public.follow_requests FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = requested_id);
CREATE POLICY "Users can create follow requests" ON public.follow_requests FOR INSERT WITH CHECK (auth.uid() = requester_id);
CREATE POLICY "Users can update their own follow requests" ON public.follow_requests FOR UPDATE USING (auth.uid() = requester_id OR auth.uid() = requested_id);
CREATE POLICY "Users can delete their own follow requests" ON public.follow_requests FOR DELETE USING (auth.uid() = requester_id OR auth.uid() = requested_id);
```

### 7. Create Database Function for User Profile

```sql
-- Function to automatically create user profile after signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, username, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function when a new user signs up
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

## 🔧 Configuration Files Created

- `ReviewSocial/Services/SupabaseService.swift` - Main service class for all Supabase operations
- `ReviewSocial/Services/Config.swift` - Configuration file with your project URL
- Updated `AuthenticationView.swift` - Now uses Supabase for authentication
- Updated `ContentView.swift` - Now checks authentication state

## 🎯 Features Implemented

✅ **Authentication**: Sign up, sign in, sign out
✅ **User Profiles**: Profile creation and updates
✅ **Reviews**: Create, read, update, delete reviews
✅ **Likes**: Like and unlike reviews
✅ **Bookmarks**: Bookmark and unbookmark reviews
✅ **Comments**: Create and read comments
✅ **File Upload**: Avatar image upload
✅ **Real-time**: Ready for real-time features

## 🚨 Important Notes

1. **Update your anon key** in `Config.swift` - this is crucial!
2. **Run the SQL scripts** in your Supabase dashboard
3. **Test authentication** before using other features
4. **Enable email confirmation** in Supabase Auth settings if desired

## 🛠 Development Tips

- Use the Supabase dashboard to monitor your database
- Check the Auth section for user management
- Use the Storage section for file uploads
- Monitor API usage in the Dashboard

## 📱 Testing

1. Build and run your app
2. Try signing up with a new account
3. Test all the authentication flows
4. Create a test review
5. Test likes and bookmarks

Your ReviewSocial app is now ready to use with Supabase! 🎉 