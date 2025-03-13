# Marketplace Feature

This directory contains the marketplace functionality for the findU app.

## Structure

```
Marketplace/
├── Models/          # Data models for marketplace
├── ViewModels/      # View models for marketplace logic
└── Views/           # UI components for marketplace
    ├── MarketplaceView.swift
    ├── CreateListingView.swift
    ├── ListingDetailView.swift
    └── CreatorProfileView.swift
```

## Components

- `MarketplaceView.swift`: Main marketplace view with listings grid
- `CreateListingView.swift`: Form for creating new listings
- `ListingDetailView.swift`: Detailed view of a single listing
- `CreatorProfileView.swift`: Profile view for creators/sellers
- `MarketplaceViewModel.swift`: Business logic for marketplace
- `MarketplaceModels.swift`: Data models for listings and transactions

## Features

The marketplace feature handles:
- Browsing listings
- Creating new listings
- Managing listings
- Purchase process
- Creator profiles
- Reviews and ratings
- Transaction history
- Search and filtering 