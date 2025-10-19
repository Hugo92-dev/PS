# Xcode Project Setup Guide

Since Xcode projects cannot be created programmatically from Windows, follow these steps to create the project on macOS:

## 1. Create New Xcode Project

1. Open Xcode
2. File → New → Project
3. Select **iOS → App**
4. Configure:
   - **Product Name**: PhotoSweeperApp
   - **Team**: Select your Apple ID (Personal Team)
   - **Organization Identifier**: com.photosweeper (or your own)
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: None (we use custom Storage)
5. Save to `/PhotoSweeperApp` directory

## 2. Add PhotoSweeperCore Package Dependency

1. Select project in navigator
2. Select target "PhotoSweeperApp"
3. Go to **General** tab → **Frameworks, Libraries, and Embedded Content**
4. Click **+** → **Add Package Dependency**
5. Choose **Add Local...** → Select `/PhotoSweeperCore` directory
6. Add `PhotoSweeperCore` library to target

## 3. Configure Capabilities

### 3.1 Photos Library Access

1. Select target → **Info** tab
2. Add keys:
   - `NSPhotoLibraryUsageDescription`: "PhotoSweeper analyse vos photos pour détecter les doublons et photos inutiles. Vos données restent privées sur votre appareil."
   - `NSPhotoLibraryAddUsageDescription`: "PhotoSweeper a besoin d'accéder à votre photothèque pour identifier les photos à supprimer."

### 3.2 Background Modes

1. Select target → **Signing & Capabilities**
2. Click **+ Capability** → **Background Modes**
3. Enable:
   - ☑ Background fetch
   - ☑ Background processing

### 3.3 Push Notifications (for local notifications)

1. Click **+ Capability** → **Push Notifications**
2. This enables local notifications (no remote push needed)

## 4. Copy Source Files

Copy all Swift files from `/PhotoSweeperApp/PhotoSweeperApp/` into the Xcode project:

```
PhotoSweeperApp/
├── PhotoSweeperApp.swift              # Main app entry
├── Models/
│   ├── AppState.swift                 # App-level state
│   └── PhotoLibraryManager.swift      # PhotoKit wrapper
├── Views/
│   ├── Onboarding/
│   │   ├── OnboardingView.swift
│   │   └── PermissionView.swift
│   ├── Scan/
│   │   └── ScanView.swift
│   ├── Results/
│   │   ├── ResultsView.swift
│   │   ├── DuplicatesTab.swift
│   │   └── UselessPhotosTab.swift
│   ├── Paywall/
│   │   └── PaywallView.swift
│   └── Common/
│       ├── AssetThumbnail.swift
│       └── ProgressBar.swift
├── Services/
│   ├── ScanService.swift              # Orchestrates sweeper
│   ├── BackgroundTaskService.swift    # BGTaskScheduler
│   ├── NotificationService.swift      # Local notifications
│   ├── StoreKitService.swift          # In-app purchase
│   └── DeletionService.swift          # PHPhotoLibrary deletion
└── Info.plist
```

## 5. Add StoreKit Configuration File

1. File → New → File → StoreKit Configuration File
2. Name: `PhotoSweeper.storekit`
3. Save to `/PhotoSweeperApp/StoreKit/`
4. Edit (see STOREKIT_SETUP.md)

## 6. Configure Scheme for StoreKit Testing

1. Product → Scheme → Edit Scheme
2. Select **Run** → **Options** tab
3. **StoreKit Configuration**: Select `PhotoSweeper.storekit`

## 7. Build & Run

1. Select iPhone simulator or connect physical device
2. **Important**: Physical device required for Photos library access (simulator has limited photos)
3. Product → Run (⌘R)
4. On device: Settings → General → VPN & Device Management → Trust your developer profile

## Troubleshooting

### "Developer Mode Required" (iOS 16+)

On device: Settings → Privacy & Security → Developer Mode → Enable

### Missing Package Dependency

If PhotoSweeperCore doesn't build:
1. File → Packages → Reset Package Caches
2. Clean Build Folder (⌘⇧K)
3. Rebuild (⌘B)

### Code Signing Issues

Use automatic signing with your Apple ID (free). No paid developer account needed for testing.
