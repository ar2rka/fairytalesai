# iOS App File Structure

## ✅ Necessary Files

### Project Files
- `FairyTalesAI.xcodeproj/` - Xcode project file (required)
  - `project.pbxproj` - Project configuration
  - `project.xcworkspace/` - Workspace files (auto-generated)

### Source Code (in `FairyTalesAI/` folder)
- `App.swift` - App entry point
- `ContentView.swift` - Main content view
- `FairyTalesAI.entitlements` - App entitlements
- `Assets.xcassets/` - App icons and colors
- `Preview Content/` - Preview assets for SwiftUI previews

### Source Code Folders
- `Models/` - Data models
  - `Child.swift`
  - `Story.swift`
- `ViewModels/` - State management
  - `ChildrenStore.swift`
  - `StoriesStore.swift`
- `Views/` - SwiftUI views
  - `MainTabView.swift`
  - `HomeView.swift`
  - `ChildrenListView.swift`
  - `AddChildView.swift`
  - `GenerateStoryView.swift`
  - `LibraryView.swift`
  - `SettingsView.swift`
- `Theme/` - App theming
  - `AppTheme.swift`

### Documentation
- `HOW_TO_RUN.md` - Setup instructions
- `QUICK_START.md` - Quick reference guide

## ❌ Files to Remove (if present)

These are duplicates that shouldn't be at the root:
- `App.swift` (duplicate - exists in FairyTalesAI/)
- `ContentView.swift` (duplicate - exists in FairyTalesAI/)
- `FairyTalesAI.entitlements` (duplicate - exists in FairyTalesAI/)
- `Assets.xcassets/` (duplicate - exists in FairyTalesAI/)
- `Preview Content/` (duplicate - exists in FairyTalesAI/)

## 📁 Correct Structure

```
ios-app/
├── FairyTalesAI.xcodeproj/     # Xcode project
├── FairyTalesAI/               # Source code folder
│   ├── App.swift
│   ├── ContentView.swift
│   ├── FairyTalesAI.entitlements
│   ├── Assets.xcassets/
│   ├── Preview Content/
│   ├── Models/
│   ├── ViewModels/
│   ├── Views/
│   └── Theme/
├── HOW_TO_RUN.md
└── QUICK_START.md
```

## 🧹 Cleanup

All duplicate files at the root level have been removed. The project should now have a clean structure.

