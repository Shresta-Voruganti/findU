# Wishlist Feature

The Wishlist feature allows users to create and manage collections of items they want to save for later. Users can organize items into collections, track prices, set priorities, and manage their shopping preferences efficiently.

## Directory Structure

```
Wishlist/
├── Models/              # Data models and types
│   └── WishlistModels.swift
├── ViewModels/          # Business logic and state management
│   └── WishlistViewModel.swift
└── Views/              # UI components
    └── WishlistView.swift
```

## Components

### Models (`WishlistModels.swift`)
- `WishlistItem`: Represents individual wishlist items
  - Properties: id, userId, itemType, referenceId, note, priority, status, price, etc.
  - Supports price tracking and notifications
- `WishlistCollection`: Groups related items together
  - Properties: id, name, description, items, privacy settings, etc.
- `PriceAlert`: Manages price tracking and notifications
- `WishlistStats`: Tracks collection statistics and analytics

### ViewModel (`WishlistViewModel.swift`)
- State Management
  - Collections and items
  - Loading and error states
  - Filtering and sorting options
- Operations
  - CRUD operations for collections and items
  - Price alert management
  - Statistics tracking
  - Data persistence with Firebase

### Views (`WishlistView.swift`)
1. **Main View Components**
   - `WishlistView`: Root view with navigation and content organization
   - `CollectionPickerView`: Horizontal scrollable collection selector
   - `WishlistStatsBar`: Display of wishlist statistics
   - `WishlistItemsGrid`: Grid layout for wishlist items

2. **Item Display**
   - `WishlistItemCard`: Card view for individual items
   - `PriorityBadge`: Visual indicator for item priority
   - `StatusBadge`: Visual indicator for item status

3. **Modal Sheets**
   - `AddCollectionSheet`: Form for creating new collections
   - `AddWishlistItemSheet`: Form for adding new items
   - `FilterSheet`: Controls for filtering items

## Features

### Collection Management
- Create and manage multiple wishlist collections
- Private/public collection settings
- Collection statistics and item counts
- Collection sharing capabilities

### Item Management
- Add items with notes and prices
- Set item priorities (Low, Medium, High)
- Track item status (Active, Purchased, Unavailable, Archived)
- Support for item images and details

### Organization & Filtering
- Sort items by:
  - Date added
  - Priority
  - Price
  - Name
- Filter items by:
  - Status
  - Priority
  - Custom criteria

### Price Tracking
- Set target prices
- Enable price drop notifications
- Track price history
- Calculate total collection value

### User Interface
- Clean and intuitive design
- Responsive grid layout
- Empty state handling
- Loading state management
- Error handling and user feedback

### Data Persistence
- Firebase integration
- Real-time updates
- Offline support
- Data synchronization

## Usage

```swift
// Initialize the Wishlist view
WishlistView()

// Create a new collection
viewModel.createCollection(
    name: "Holiday Gifts",
    description: "Gift ideas for the holidays",
    isPrivate: true
)

// Add an item to a collection
viewModel.addToWishlist(
    note: "New iPhone",
    price: 999.99,
    priority: .high
)
```

## Best Practices
- Use meaningful collection names
- Set appropriate item priorities
- Enable price notifications for important items
- Regularly review and update item statuses
- Archive purchased or unavailable items

## Future Enhancements
- [ ] Share collections with friends
- [ ] Import items from external sources
- [ ] Advanced price tracking analytics
- [ ] Collaborative wishlists
- [ ] Integration with e-commerce platforms
- [ ] Enhanced notification system 