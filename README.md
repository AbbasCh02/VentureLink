# VentureLink

<div align="center">
  <img src="assets/VentureLink%20LogoAlone%202.0.png" alt="VentureLink Logo" width="200"/>
  
  ### Connecting Startups with Investors
  
  A comprehensive Flutter application that bridges the gap between innovative startups and forward-thinking investors, enabling meaningful connections and investment opportunities.

  [![Flutter](https://img.shields.io/badge/Flutter-v3.27.0-blue.svg)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-v3.7.2-blue.svg)](https://dart.dev/)
  [![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com/)
  [![License](https://img.shields.io/badge/License-Private-red.svg)](#)
</div>

## 📱 About VentureLink

VentureLink is a cross-platform mobile application built with Flutter that serves as a comprehensive platform for startup-investor connections. The app provides tailored experiences for both entrepreneurs seeking funding and investors looking for promising opportunities.

## ✨ Key Features

### 🎯 For Startups
- **Profile Management**: Comprehensive startup profiles with company details, team information, and pitch decks
- **Business Model Canvas**: Interactive business model planning with 9 essential sections
- **File Management**: Upload and manage pitch deck files (PDF, videos) with cloud storage
- **Team Management**: Add and manage team members with roles and responsibilities
- **Avatar Upload**: Professional profile image management with validation

### 💼 For Investors
- **Investment Portfolio**: Track and manage investment preferences and portfolio size
- **Company Discovery**: Browse and evaluate startup opportunities
- **Profile Customization**: Detailed investor profiles with bio and investment criteria
- **Due Diligence**: Access startup pitch decks and business models

### 🔐 Unified Authentication
- **Dual User Types**: Seamless onboarding for both startups and investors
- **Secure Login**: Email/password authentication with Supabase integration
- **User Type Detection**: Automatic routing based on user role
- **Password Recovery**: Built-in password reset functionality

## 🏗️ Technical Architecture

### **State Management**
- Provider pattern for scalable state management
- Real-time data synchronization
- Auto-save functionality with debouncing
- Dirty field tracking for UI updates

### **Backend Integration**
- **Supabase** for authentication and database
- Real-time data updates
- Secure file storage with bucket organization
- Row-level security (RLS) policies

### **File Management**
- Multi-format support (PDF, MP4, AVI, MOV, MKV, WMV)
- Image validation and compression
- Cloud storage with CDN delivery
- Thumbnail generation for videos

## 🔧 Dependencies

### **Core Dependencies**
```yaml
flutter: sdk
supabase_flutter: ^2.9.1      # Backend integration
provider: ^6.1.5              # State management
flutter_dotenv: ^5.2.1        # Environment configuration
```

### **UI & Media**
```yaml
file_picker: ^10.1.2          # File selection
image_picker: ^1.1.2          # Image capture/selection
pdfx: ^2.9.1                  # PDF viewing
video_thumbnail: ^0.5.6       # Video thumbnail generation
```

### **Utilities**
```yaml
logger: ^2.5.0                # Logging
url_launcher: ^6.3.1          # External URL handling
shared_preferences: ^2.5.3    # Local storage
path: ^1.9.1                  # Path manipulation
```

### **Development Tools**
```yaml
flutter_launcher_icons: ^0.14.3     # App icon generation
flutter_native_splash: ^2.4.6       # Splash screen
flutter_lints: ^5.0.0               # Code quality
```

## 📂 Project Structure

```
lib/
├── auth/                          # Authentication system
│   ├── unified_authentication_provider.dart
│   ├── unified_login.dart
│   └── unified_signup.dart
├── services/                      # Business logic services
│   ├── storage_service.dart       # File upload/management
│   └── user_type_service.dart     # User type detection
├── Startup/                       # Startup user features
│   ├── Providers/                 # State management
│   │   ├── startup_profile_provider.dart
│   │   ├── startup_profile_overview_provider.dart
│   │   ├── team_members_provider.dart
│   │   └── business_model_canvas_provider.dart
│   ├── Startup_Dashboard/         # Main startup interface
│   │   ├── startup_dashboard.dart
│   │   ├── startup_profile_page.dart
│   │   ├── team_members_page.dart
│   │   └── Business_Model_Canvas/ # BMC components
│   └── widgets/                   # Reusable UI components
│       └── avatar_upload_widget.dart
├── Investor/                      # Investor user features
│   ├── Providers/                 # State management
│   │   ├── investor_profile_provider.dart
│   │   └── investor_company_provider.dart
│   └── Investor_Dashboard/        # Main investor interface
│       ├── investor_dashboard.dart
│       ├── investor_profile_page.dart
│       ├── investor_bio.dart
│       ├── company_list_page.dart
│       └── investor_preference_page.dart
├── homepage.dart                  # Landing page
└── main.dart                      # Application entry point
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.27.0 or higher)
- Dart SDK (3.7.2 or higher)
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/venturelink.git
   cd venturelink
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment setup**
   ```bash
   # Create .env file in project root
   cp .env.example .env
   # Add your Supabase credentials
   ```

4. **Generate app icons and splash screen**
   ```bash
   flutter pub run flutter_launcher_icons:main
   flutter pub run flutter_native_splash:create
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

## 🔌 Backend Configuration

### Supabase Setup
1. Create a new Supabase project
2. Configure authentication settings
3. Set up database tables:
   - `startups`
   - `investors`
   - `startup_profiles`
   - `investor_profiles`
   - `business_model_canvas`
   - `pitch_decks`
   - `team_members`
   - `investor_companies`

### Storage Buckets
- `avatars`: User profile images
- `pitch-deck-files`: Startup documents and videos

## 🎨 Design System

### **Color Palette**
- Primary: `#FFa500` (Orange), `#65c6f4` (Blue)
- Background: `#000000` (Black)
- Cards: `#1a1a1a` (Dark Gray)
- Text: `#FFFFFF` (White), `#000000` (Black)
- Secondary Text: `#999999` (Light Gray)

### **Typography**
- Clean, modern font family
- Hierarchical text sizing
- Consistent spacing and alignment

### **UI Components**
- Gradient cards with rounded corners
- Interactive buttons with hover effects
- Professional form styling
- Responsive layout design

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Integration tests
flutter drive --target=test_driver/app.dart
```

## 📱 Platform Support

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 12+)
- ✅ **Web** (PWA Support)
- ✅ **macOS**
- ✅ **Windows**
- ✅ **Linux**

## 🔒 Security Features

- End-to-end encryption for sensitive data
- Row-level security policies
- File upload validation and sanitization
- Secure authentication with JWT tokens
- Input validation and XSS protection

## 🚀 Performance Optimizations

- Lazy loading of images and content
- Efficient state management with Provider
- Image compression and caching
- Background isolates for heavy computations
- Optimized build configurations

## 📖 Documentation

### Key Components

#### **StorageService**
Centralized file management service handling:
- Avatar image uploads with validation
- Pitch deck file management
- Cloud storage integration
- File metadata handling

#### **Business Model Canvas Provider**
Interactive business planning tool featuring:
- 9 essential business model sections
- Real-time progress tracking
- Auto-save functionality
- Completion percentage calculation

#### **Authentication System**
Unified authentication supporting:
- Dual user type registration
- Secure login/logout
- Password recovery
- Session management

## 🤝 Contributing

We welcome contributions!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is private and proprietary. All rights reserved.

## 📞 Support

For support, email [support@venturelink.com](mailto:support@venturelink.com) or join our Slack community.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for backend infrastructure
- Open source community for inspiration
- Contributors and beta testers

---

<div align="center">
  <p>Made with ❤️ by the VentureLink Team</p>
  <p>🚀 Connecting Innovation with Investment 🚀</p>
</div>
