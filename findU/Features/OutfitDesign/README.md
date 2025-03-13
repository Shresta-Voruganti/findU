# OutfitDesign Feature

The OutfitDesign feature allows users to create and customize outfit designs by combining different clothing items, accessories, and backgrounds. Users can manipulate items on a canvas, save their designs, and share them with others.

## Architecture

The feature follows the MVVM (Model-View-ViewModel) architecture pattern and is organized into the following components:

### Views
- `OutfitDesignView`: Main view for the design canvas and tools
- `DesignCanvasView`: Canvas where items can be arranged and manipulated
- `ItemPickerView`: View for selecting items to add to the design
- `BackgroundPickerView`: View for selecting and customizing canvas backgrounds

### ViewModels
- `DesignViewModel`: Manages the design canvas state and operations
- `ItemPickerViewModel`: Handles item selection and filtering
- `BackgroundPickerViewModel`: Manages background selection and customization

### Models
- `DesignCanvas`: Represents the design canvas and its contents
- `DesignItem`: Represents an item placed on the canvas
- `CanvasBackground`: Represents the canvas background (solid color, gradient, or image)
- `Gradient`: Represents a gradient background
- `DesignHistory`: Manages undo/redo operations

### Services
- `DesignService`: Handles design-related operations and persistence

## Features

### Canvas Manipulation
- Add, remove, and manipulate items on the canvas
- Resize, rotate, and adjust opacity of items
- Lock items to prevent accidental changes
- Arrange items in layers (z-index)

### Background Customization
- Solid color backgrounds with color picker
- Gradient backgrounds with customizable colors and angle
- Image backgrounds from photo library
- Recent backgrounds history

### Item Management
- Browse and search items by category
- Recent items history
- Favorite items
- Item suggestions based on selected items

### Design Management
- Save designs locally and to the server
- Load saved designs
- Share designs as images
- Undo/redo support

### Offline Support
- Core Data persistence for offline access
- Background syncing with server
- Cached product catalog

## Dependencies

The feature relies on the following core services:
- `StorageService`: For local data persistence
- `NetworkService`: For server communication
- `CoreDataStack`: For offline storage

## Usage Example

```swift
// Create a new design
let designView = OutfitDesignView()

// Load an existing design
let designView = OutfitDesignView(designId: UUID())

// The view will automatically handle loading the design and its items
```

## Data Flow

1. User interacts with the canvas or tools
2. ViewModel processes the interaction
3. Changes are recorded in the history
4. Design is automatically saved
5. Changes are synced with the server in the background

## Error Handling

The feature includes comprehensive error handling for:
- Failed design loading/saving
- Network connectivity issues
- Invalid design data
- Permission issues (e.g., photo library access)

## Future Improvements

- Advanced image filters and effects
- AI-powered outfit suggestions
- Collaborative design features
- Design templates
- Export to different formats
- Social sharing integration 