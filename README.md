# SmartSlot - Smart Parking Application

A modern Flutter-based parking slot booking application with real-time location tracking, Firebase backend, and seamless payment integration.

## Features

✨ **Core Features:**
- 🔐 Secure user authentication (Email/Password)
- 📍 Real-time location tracking
- 🗺️ Interactive map with parking spot markers
- 🚗 Support for Car and Bike parking
- 💳 Integrated payment system (Razorpay/Stripe)
- 👤 User profile management
- ⭐ Favorite parking spots
- 📱 Responsive UI design

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                  # UI screens
│   ├── auth_wrapper.dart
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── home_screen.dart
│   ├── map_screen.dart
│   ├── booking_screen.dart
│   ├── payment_screen.dart
│   └── ...
├── providers/                # State management
│   ├── booking_provider.dart
│   └── theme_provider.dart
├── services/                 # Business logic
│   ├── auth_service.dart
│   ├── parking_service.dart
│   ├── location_service.dart
│   └── ...
├── models/                   # Data models
│   ├── user_model.dart
│   ├── parking_spot.dart
│   └── ...
└── firebase_options.dart     # Firebase configuration
```

## Technologies Used

- **Frontend:** Flutter, Material Design
- **Backend:** Firebase (Auth, Firestore, Storage)
- **State Management:** Provider
- **Maps:** Flutter Map, OpenStreetMap
- **Location:** Geolocator
- **Payments:** Razorpay/Stripe
- **Time:** Intl package

## Installation

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / Xcode
- Firebase project setup

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/anandu112-ai/Smartslot.git
   cd smart_parking_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Download your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the respective platform folders
   - Run: `flutterfire configure`

4. **Run the app**
   ```bash
   flutter run
   ```

## Configuration

### Firebase Setup
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication, Firestore, and Storage
3. Configure security rules for Firestore
4. Set up payment gateway credentials

### Environment Variables
Create a `.env` file in the project root (if needed for sensitive data)

## API Integration

### Parking Service
- Get nearby parking spots
- Get parking details
- Update parking availability

### Payment Service
- Razorpay/Stripe integration
- Secure transaction handling

## User Roles

### Driver
- Search and book parking spots
- View booking history
- Add/remove favorites
- Manage profile

### Manager
- Add parking locations
- Edit parking details
- Move parking spots on map
- View booking statistics

## Screenshots

(Add screenshots of your app here)

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

- GitHub: [@anandu112-ai](https://github.com/anandu112-ai)
- Email: your-email@example.com

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- OpenStreetMap for map data

---

**Made with ❤️ by Anandu**
