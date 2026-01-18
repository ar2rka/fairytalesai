# How to Run the iOS App in Xcode

## Step-by-Step Instructions

### 1. Open the Project

1. **Open Xcode** (version 15.0 or later)
2. **Open the project file:**
   - Go to `File` → `Open...` (or press `Cmd+O`)
   - Navigate to: `/Users/arturburlaka/Downloads/fairytalesai/ios-app/`
   - Select `FairyTalesAI.xcodeproj`
   - Click `Open`

### 2. Add Missing Files to Project

The project file needs to include all Swift files. Here's how to add them:

#### Option A: Add Files Individually (Recommended)

1. **In Xcode's Project Navigator** (left sidebar), right-click on the `FairyTalesAI` folder (blue icon)
2. Select **"Add Files to 'FairyTalesAI'..."**
3. Navigate to the `FairyTalesAI` folder in the file browser
4. **Select these folders and files:**
   - `Models/` folder (contains Child.swift, Story.swift)
   - `ViewModels/` folder (contains ChildrenStore.swift, StoriesStore.swift)
   - `Views/` folder (contains all view files)
   - `Theme/` folder (contains AppTheme.swift)
5. **Important settings:**
   - ✅ Check "Create groups" (not "Create folder references")
   - ❌ Uncheck "Copy items if needed" (files are already in the right place)
   - ✅ Make sure "Add to targets: FairyTalesAI" is checked
6. Click **"Add"**

#### Option B: Let Xcode Auto-Discover (Easier)

1. In Xcode, go to **File** → **Add Package Dependencies...** (this won't add packages, but helps refresh)
2. Or simply try to build - Xcode may auto-discover the files
3. If files show up in red in the navigator, select them and check "Target Membership" in the File Inspector (right panel)

### 3. Verify Files Are Added

After adding files, you should see this structure in Xcode's Project Navigator:

```
FairyTalesAI
├── App.swift
├── ContentView.swift
├── Models/
│   ├── Child.swift
│   └── Story.swift
├── ViewModels/
│   ├── ChildrenStore.swift
│   └── StoriesStore.swift
├── Views/
│   ├── MainTabView.swift
│   ├── HomeView.swift
│   ├── ChildrenListView.swift
│   ├── AddChildView.swift
│   ├── GenerateStoryView.swift
│   ├── LibraryView.swift
│   └── SettingsView.swift
├── Theme/
│   └── AppTheme.swift
├── Assets.xcassets
└── Preview Content
```

### 4. Configure Signing

1. **Select the project** in the Project Navigator (top item, blue icon)
2. **Select the "FairyTalesAI" target** in the main editor
3. Go to the **"Signing & Capabilities"** tab
4. **Check "Automatically manage signing"**
5. **Select your Team** from the dropdown (your Apple Developer account)
   - If you don't have one, you can use your Apple ID for development
   - Xcode will create a development certificate automatically

### 5. Select a Simulator or Device

1. **At the top of Xcode**, next to the play button, click the device selector
2. **Choose a simulator:**
   - iPhone 15 Pro (recommended)
   - iPhone 15
   - Any iOS 17.0+ simulator
3. Or connect a physical iPhone/iPad and select it

### 6. Build and Run

1. **Press `Cmd+R`** (or click the Play button ▶️ in the top-left)
2. **Wait for the build to complete** (first build may take 1-2 minutes)
3. **The app will launch** in the simulator or on your device

### 7. Troubleshooting

#### If you see build errors about missing files:

1. Make sure all Swift files are added to the target:
   - Select a file in Project Navigator
   - Open the File Inspector (right panel, first tab)
   - Under "Target Membership", make sure "FairyTalesAI" is checked

#### If you see signing errors:

1. Go to Signing & Capabilities
2. Change the Bundle Identifier to something unique (e.g., `com.yourname.fairytalesai`)
3. Select your team again

#### If files show in red:

1. The file path might be broken
2. Right-click the red file → "Delete" (Remove Reference only)
3. Re-add the file using Option A above

#### If you see "No such module" errors:

1. Clean the build folder: `Product` → `Clean Build Folder` (or `Cmd+Shift+K`)
2. Build again: `Product` → `Build` (or `Cmd+B`)

### 8. Quick Test

Once the app runs, you should see:
- ✅ Dark purple background
- ✅ Tab bar at the bottom with 5 tabs
- ✅ Home screen with "Good Evening, Storyteller" greeting
- ✅ Ability to add a child profile
- ✅ Story generation screen

## Alternative: Create New Project and Copy Files

If the above doesn't work, you can create a fresh project:

1. **Create a new Xcode project:**
   - File → New → Project
   - Choose "iOS" → "App"
   - Name: "FairyTalesAI"
   - Interface: SwiftUI
   - Language: Swift
   - Save it

2. **Copy all Swift files** from the existing `FairyTalesAI/` folder to the new project
3. **Add them to the project** using Option A above
4. **Copy Assets.xcassets** and other resources

## Requirements

- **Xcode 15.0+** (download from Mac App Store)
- **macOS 13.0+** (Ventura or later)
- **iOS 17.0+** simulator or device

## Need Help?

If you encounter issues:
1. Check that all files are in the project (not showing red)
2. Verify Target Membership for all Swift files
3. Clean build folder and rebuild
4. Check Xcode's Issue Navigator (left sidebar, warning icon) for specific errors

