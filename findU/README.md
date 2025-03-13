# findU - Fashion Design & Marketplace App

findU is an iOS application that combines social fashion design with a marketplace, allowing users to create, share, and sell their fashion designs while integrating with Instagram for enhanced social features.

<!-- ## Features

### Design Creation
- Create custom outfit designs using the built-in design tool
- Support for both avatar-based and collage-based designs
- Save and organize designs in collections

### Marketplace
- List and sell your fashion designs
- Browse and purchase designs from other creators
- Advanced filtering and search capabilities
- Secure payment processing with Stripe

### Social Integration
- Instagram authentication and sharing
- View Instagram feed within the app
- Share designs directly to Instagram
- Follow other designers and interact with their content

### Creator Profiles
- Verified creator status
- Portfolio showcase
- Reviews and ratings
- Sales tracking and analytics -->

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- CocoaPods or Swift Package Manager

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/findU.git
cd findU
```

2. Set up environment variables:
```bash
cp .env.template .env
```
Then edit `.env` with your actual values. This file contains all necessary API keys and configuration values. Never commit this file to version control.

Example `.env` structure:
```
# Firebase
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id
FIREBASE_APP_ID=your_firebase_app_id

# Stripe
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
STRIPE_SECRET_KEY=your_stripe_secret_key

# Instagram
INSTAGRAM_CLIENT_ID=your_instagram_client_id
INSTAGRAM_CLIENT_SECRET=your_instagram_client_secret
INSTAGRAM_REDIRECT_URI=your_instagram_redirect_uri

# API
API_BASE_URL=your_api_base_url
API_VERSION=v1
```

3. Install dependencies using Swift Package Manager:
```bash
swift package resolve
```

4. Open `findU.xcodeproj` and run the project.

## Configuration and Security

### Environment Variables
The application uses environment variables for all sensitive configuration. These are managed through:
- `.env.template`: Template file showing required variables (committed to repo)
- `.env`: Your actual configuration file (never commit this)

To access these values in code, use the `ConfigurationManager`:
```swift
do {
    let stripeKey = try ConfigurationManager.shared.stripePublishableKey
    // Use the key...
} catch {
    print("Configuration error: \(error)")
}
```

### Security Best Practices
1. Never commit `.env` file to version control
2. Use different environment variables for development/staging/production
3. Rotate API keys regularly
4. Monitor API usage for suspicious activity
5. Implement proper key management in CI/CD pipeline
6. Use secure storage for production keys

## Service Setup

### Firebase Setup
1. Create a new Firebase project
2. Add your iOS app to the project
3. Get your Firebase configuration values
4. Add them to your `.env` file

### Instagram Setup
1. Create a Meta Developer account
2. Create a new app
3. Configure OAuth redirect URIs
4. Add Instagram Basic Display API
5. Add credentials to your `.env` file

### Stripe Setup
1. Create a Stripe account
2. Get your publishable and secret keys
3. Add them to your `.env` file

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture pattern and uses SwiftUI for the UI layer. Key components include:

- **Models**: Data structures and business logic
- **Views**: SwiftUI views for the user interface
- **ViewModels**: Business logic and state management
- **Services**: API integration and data persistence
- **Utilities**: Helper functions and extensions
- **Config**: Environment and configuration management

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Copy `.env.template` to `.env` and configure your environment
4. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
5. Push to the branch (`git push origin feature/AmazingFeature`)
6. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Firebase](https://firebase.google.com)
- [Stripe](https://stripe.com)
- [Instagram Basic Display API](https://developers.facebook.com/docs/instagram-basic-display-api)
- [SDWebImageSwiftUI](https://github.com/SDWebImage/SDWebImageSwiftUI)

## Contact

Your Name - [@yourtwitter](https://twitter.com/yourtwitter) - email@example.com

Project Link: [https://github.com/yourusername/findU](https://github.com/yourusername/findU) 