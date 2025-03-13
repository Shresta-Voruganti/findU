# Authentication Feature

This directory contains all authentication-related functionality for the findU app.

## Structure

```
Authentication/
├── Models/          # Data models for authentication
├── ViewModels/      # View models for authentication logic
└── Views/           # UI components for authentication
```

## Components

- `AuthenticationView.swift`: Main authentication view with sign in/sign up
- `OnboardingView.swift`: Onboarding flow for new users
- `AuthenticationModels.swift`: Data models for authentication
- `AuthenticationViewModel.swift`: Business logic for authentication

## Usage

The authentication feature handles:
- User sign in
- User sign up
- Password reset
- OAuth authentication
- Session management
- User profile data 