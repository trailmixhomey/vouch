# ReviewSocial 📝✨

A Twitter-inspired iOS app built with SwiftUI, focused entirely on reviews instead of tweets. Share your experiences, discover new places, and connect with fellow reviewers!

## 🚀 Features

### Core Functionality
- **📱 Twitter-like Feed**: Scroll through reviews in a familiar social media format
- **⭐ Star Ratings**: 5-star rating system with half-star precision
- **📝 Rich Reviews**: Title, content, business info, location, and tags
- **💬 Comments**: Threaded commenting system with like functionality
- **🔍 Advanced Search**: Search reviews, users, and businesses with filters
- **🔔 Notifications**: Real-time updates for likes, comments, and follows
- **👤 User Profiles**: Complete profile pages with stats and review history

### Review Categories
- 🍽️ Restaurants
- 🎬 Movies
- 📚 Books
- 📦 Products
- 🛠️ Services
- ✈️ Travel
- 🎭 Entertainment
- 💻 Technology
- 🏥 Health
- 📝 Other

### User Interface
- **Modern SwiftUI Design**: Clean, intuitive interface following iOS design principles
- **Tab Navigation**: Easy access to Feed, Search, Create, Notifications, and Profile
- **Pull-to-Refresh**: Stay updated with the latest reviews
- **Responsive Design**: Works seamlessly on iPhone and iPad

## 📂 Project Structure

```
ReviewSocial/
├── Models/
│   ├── User.swift          # User data model
│   ├── Review.swift        # Review data model with categories
│   └── Comment.swift       # Comment threading system
├── Views/
│   ├── Feed/
│   │   └── FeedView.swift  # Main Twitter-like feed
│   ├── Components/
│   │   ├── ReviewCard.swift      # Individual review cards
│   │   ├── SearchView.swift      # Search functionality
│   │   └── NotificationsView.swift # Notification center
│   ├── Review/
│   │   ├── CreateReviewView.swift # Review composition
│   │   └── ReviewDetailView.swift # Detailed review view
│   ├── Profile/
│   │   └── ProfileView.swift     # User profiles
│   └── Authentication/
│       └── AuthenticationView.swift # Login/signup
├── Services/
├── Utilities/
└── Assets/
```

## 🎯 Key Components

### ReviewCard
The heart of the app - displays reviews in a Twitter-like card format with:
- User profile information
- Category badges with emojis
- Star ratings
- Business/location info
- Hashtag support
- Like/dislike/comment/share buttons

### FeedView
Main timeline showing:
- Infinite scroll of reviews
- Pull-to-refresh functionality
- Sample data with diverse review types

### CreateReviewView
Comprehensive review creation with:
- Category selection
- Star rating input
- Rich text editor
- Business/location fields
- Tag support
- Photo attachment (coming soon)

### SearchView
Advanced search functionality:
- Real-time search with filters
- Recent searches
- Trending categories
- Results by type (reviews, users, businesses)

## 🛠️ Technical Details

- **Framework**: SwiftUI (iOS 17+)
- **Architecture**: MVVM pattern with observable objects
- **Navigation**: TabView with 5 main sections
- **State Management**: @State and @ObservableObject
- **Data**: Sample data for demonstration (ready for backend integration)

## 📱 Screenshots & Usage

### Main Feed
- Scroll through reviews like Twitter posts
- Tap hearts to like/dislike
- Tap comments to view detailed thread
- Pull down to refresh

### Creating Reviews
1. Tap the "+" tab
2. Select category
3. Add title and detailed review
4. Rate with stars (1-5)
5. Add business info and tags
6. Post your review

### Search & Discovery
- Search for specific reviews or topics
- Browse trending categories
- Filter by reviews, users, or places
- View recent search history

### Profile Management
- View your review statistics
- See all your posted reviews
- Edit profile information
- Track followers/following

## 🚀 Getting Started

1. Open the project in Xcode 15 or later
2. Build and run on iOS Simulator or device (iOS 17+)
3. Create an account or sign in to start using the app
4. Begin creating your first reviews!

## 🔮 Future Enhancements

- [ ] Real backend integration
- [ ] Photo/video attachments
- [ ] Push notifications
- [ ] Social features (follow users)
- [ ] Location services integration
- [ ] Review moderation tools
- [ ] Business verification system
- [ ] Advanced analytics
- [ ] Dark mode theming
- [ ] Accessibility improvements

## 🤝 Contributing

This is a clean, functional iOS app built with SwiftUI and Supabase. Feel free to extend and customize for your needs!

## 📧 Contact

Built with ❤️ using SwiftUI

---

**Note**: This app uses Supabase for authentication and data persistence. Make sure to configure your Supabase project and update the configuration in `Config.swift`. 