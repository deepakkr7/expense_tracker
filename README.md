# 💰 SpendWise - Expense Tracker

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10.0-02569B?style=for-the-badge&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

A powerful, feature-rich, AI-assisted expense tracking and budget management application built with Flutter, Firebase, and DeepSeek AI.

[Documentation & Architecture](PROJECT_DOCUMENTATION.md) • [Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Contributing](#-contributing)

</div>

---

## 📋 Overview

**SpendWise** is a comprehensive personal finance management application designed to help users track expenses, manage budgets, split bills with friends, set savings goals, and gain insights into their spending habits. Featuring on-device receipt OCR, UPI QR scanning, DeepSeek AI financial coaching, background location movement reminders, and real-time Firebase sync, SpendWise makes managing your finances effortless.

> 📖 **Looking for in-depth architecture and design docs?** Check out [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md) for full architectural diagrams, Firestore schemas, state management breakdown, and technical deep-dives.

## ✨ Features

### 🤖 AI-Powered Intelligence (DeepSeek LLM)
- **AI Budget Planner**: Automatically formulates a category-wise monthly budget optimized for debt strategies (Aggressive, Balanced, Light) and upcoming bills.
- **AI Expense Auto-Categorization**: Natural language classification of expense descriptions into budget categories with fuzzy fallback.
- **AI Savings Goal Coach**: Interactive conversational coach within savings goals that advises and motivates users towards their targets.

### 💸 Core Expense Management
- **Add & Edit Expenses**: Track your daily expenses with detailed categorization and income/expense toggles
- **Receipt OCR**: Scan receipts using Google ML Kit text recognition on-device to extract amounts, dates, and merchants without uploading images to cloud storage
- **QR Code Scanner**: Scan UPI payment QR codes (Paytm, PhonePe, Google Pay, BHIM) and launch external payment apps directly
- **Contact Integration**: Link expenses to friends directly from your phone's address book
- **Category Management**: Organize expenses by predefined, color-coded categories

### 📊 Smart Budgeting & Alerts
- **Monthly Budgets**: Set category-wise budget limits or use the 50/30/20 guideline
- **Budget Tracking**: Monitor real-time spending against allocated budgets via Firestore streams
- **Threshold Warnings**: In-app banners and push notifications at 80% and 90% budget limits
- **Zero-Budget Protection**: Alerts users when spending against a category with ₹0 allocation
- **Monthly Review**: Automatic end-of-month review bottom sheet evaluating savings performance

### ⏰ Proactive Reminders & Smart Background Services
- **Daily 10:00 PM Check-In**: Scheduled local notification prompting users to log daily expenses
- **Background Location Reminder**: Geolocation movement tracker (100m displacement) prompting to log purchases when leaving stores
- **Bill Reminders**: Scheduled notifications for recurring and upcoming bills with automatic expense logging upon payment

### 👥 Social Features & Bill Splitting
- **Split Expenses**: Share bills with friends and track who owes what
- **Group Management**: Create groups (Roommates, Trip, Office) with custom emojis
- **Friend Contacts**: Import friends from your contact list
- **Equal & Custom Splits**: Divide expenses equally or configure custom amounts per friend
- **Settlement Tracking**: Per-member settlement status tracking

### 💳 Debt & Savings Management
- **Borrowed Money**: Track money lent or borrowed with automated repayment expense tracking
- **Savings Goals**: Visual progress rings, milestone dates, deposit history, and suggested monthly savings rates

### 📈 Analytics & Insights
- **Category Pie Charts**: Interactive breakdown of spending by category via FL Chart
- **Spending Trends**: 6-month historical spending curve
- **Budget vs Actual**: Side-by-side bar chart comparison
- **Top Categories**: Ranked summary of highest expenditure sectors

### 🔐 Authentication & Security
- **Firebase Authentication**: Secure email/password and Google Sign-In
- **Private Data Scoping**: All data securely partitioned per user in Cloud Firestore subcollections
- **Privacy-First OCR**: On-device machine learning with no image storage or remote transmission
- **Offline Persistence**: Cloud Firestore offline caching supports full functionality without internet

### 🎨 User Experience
- **Material 3 Design**: Modern typography with Google Fonts (Inter)
- **Theme Modes**: Full Light and Dark mode support with smooth palette transitions
- **Responsive Design**: Clean layouts tailored for Android, iOS, macOS, Windows, and Web

## 🛠️ Tech Stack

### Frontend
- **Flutter** (v3.10.0+) - Cross-platform UI framework
- **Dart** - Programming language

### Backend & Services
- **Firebase Core** - Firebase integration
- **Firebase Auth** - User authentication
- **Cloud Firestore** - NoSQL cloud database
- **Firebase Messaging** - Push notifications

### State Management
- **Provider** - State management solution

### UI & Visualization
- **FL Chart** - Interactive charts and graphs
- **Google Fonts** - Premium typography
- **Material Design** - Design system

### Key Dependencies
- **image_picker** - Camera and gallery access for receipts
- **google_mlkit_text_recognition** - OCR for receipt scanning
- **mobile_scanner** - QR code scanning
- **flutter_contacts** - Contact integration
- **permission_handler** - Handle app permissions
- **intl** - Internationalization and formatting
- **shared_preferences** - Local data persistence
- **url_launcher** - Launch URLs and external apps

## 📱 Installation

### Prerequisites
- Flutter SDK (3.10.0 or higher)
- Dart SDK (3.10.0 or higher)
- Android Studio / VS Code
- Firebase account
- Git

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/deepakkr7/expense_tracker.git
   cd expense_tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Firebase Authentication (Email/Password and Google Sign-In)
   - Create a Cloud Firestore database
   - Download and add configuration files:
     - For Android: `google-services.json` → `android/app/`
     - For iOS: `GoogleService-Info.plist` → `ios/Runner/`
   
   - Run FlutterFire CLI to generate configuration:
     ```bash
     dart pub global activate flutterfire_cli
     flutterfire configure
     ```

4. **Configure permissions**
   
   **Android** (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-permission android:name="android.permission.READ_CONTACTS"/>
   <uses-permission android:name="android.permission.WRITE_CONTACTS"/>
   ```

   **iOS** (`ios/Runner/Info.plist`):
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>Camera access is required to scan receipts and QR codes</string>
   <key>NSContactsUsageDescription</key>
   <string>Contact access is required to link expenses with friends</string>
   ```

5. **Generate app icon** (optional)
   ```bash
   flutter pub run flutter_launcher_icons
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

## 🚀 Usage

### First Time Setup
1. **Sign Up/Login**: Create an account or sign in with Google
2. **Set Monthly Income**: Enter your monthly income for budget planning
3. **Create Categories**: Default categories are provided, customize as needed
4. **Set Budgets**: Allocate budget amounts to different expense categories

### Adding Expenses
- **Manual Entry**: Tap the '+' button to manually add an expense
- **Scan Receipt**: Use the camera to scan receipts and auto-fill details
- **QR Scan**: Scan UPI payment QR codes to quickly add transactions

### Managing Budgets
- Navigate to **Budget Planner** to set monthly budgets
- View real-time budget utilization
- Receive warnings when approaching or exceeding limits

### Split Expenses
1. Go to **Split Expenses** section
2. Create a new split expense
3. Select friends to split with
4. Choose split type (equal or custom)
5. Track settlements and payments

### Savings Goals
- Create goals with target amounts and dates
- Add contributions towards goals
- Monitor progress with visual indicators

### Analytics
- View spending by category with pie charts
- Analyze monthly trends
- Compare budget vs actual spending

## 📁 Project Structure

```
expense_tracker/
├── lib/
│   ├── core/
│   │   ├── constants/        # App constants
│   │   └── theme/           # Theme configuration
│   ├── data/
│   │   ├── models/          # Data models
│   │   ├── repositories/    # Data repositories
│   │   └── services/        # External services
│   ├── presentation/
│   │   ├── screens/         # App screens
│   │   │   ├── analytics/
│   │   │   ├── auth/
│   │   │   ├── bill_reminders/
│   │   │   ├── borrowed_money/
│   │   │   ├── budget/
│   │   │   ├── expense/
│   │   │   ├── friends/
│   │   │   ├── home/
│   │   │   ├── more/
│   │   │   ├── navigation/
│   │   │   ├── onboarding/
│   │   │   ├── profile/
│   │   │   ├── qr_scanner/
│   │   │   ├── savings_goals/
│   │   │   ├── splash/
│   │   │   └── split_expenses/
│   │   └── widgets/         # Reusable widgets
│   ├── providers/           # State management
│   ├── firebase_options.dart
│   └── main.dart
├── android/
├── ios/
├── web/
├── assets/
├── pubspec.yaml
└── README.md
```

## 🎨 Screenshots

<!-- > Add screenshots of your app here to showcase the UI and features -->

## 🔧 Configuration

### Firebase Rules

**Firestore Security Rules** (example):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /expenses/{expenseId} {
      allow read, write: if request.auth != null;
    }
    // Add more rules as needed
  }
}
```

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. **Commit your changes**
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```
4. **Push to the branch**
   ```bash
   git push origin feature/AmazingFeature
   ```
5. **Open a Pull Request**

### Development Guidelines
- Follow the existing code style and architecture
- Write meaningful commit messages
- Test your changes thoroughly
- Update documentation as needed
- Add comments for complex logic

## 🐛 Known Issues

- None at the moment. Please report issues on GitHub.

## 📝 Roadmap

- [ ] Export data to CSV/PDF
- [ ] Recurring expense automation
- [ ] Investment tracking
- [ ] Multi-currency support
- [ ] Custom categories with icons
- [ ] Data backup and restore
- [ ] Expense templates
- [ ] Advanced analytics with AI insights

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Deepak K R**
- GitHub: [@deepakkr7](https://github.com/deepakkr7)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- All open-source contributors whose packages made this project possible

## 📞 Support

If you encounter any issues or have questions:
- Open an issue on GitHub
- Check existing issues for solutions
- Contact: [imdeepakdeepu01@gmail.com]

---

<div align="center">

**Made with ❤️ using Flutter**

If you find this project helpful, please consider giving it a ⭐!

</div>
