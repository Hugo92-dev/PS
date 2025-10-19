# Getting Started with PhotoSweeper MVP

Congratulations! All files for the PhotoSweeper MVP have been generated. Here's how to validate and run the project.

## Prerequisites

### Windows (Current Environment)
- ✅ Python 3.8+ installed
- ✅ pip package manager

### macOS (Required for iOS Development)
- macOS 14 (Sonoma) or later
- Xcode 15+
- Apple ID (free account works)

## Step 1: Validate Python Prototype (Windows)

Test the algorithms before iOS compilation:

```bash
# Install dependencies
cd Scripts/proto/python
pip install -r requirements.txt

# Run on a folder of test images
python proto_sweeper.py --input "C:\Users\YourName\Pictures\TestPhotos" --output results.csv

# Open results.csv in Excel/LibreOffice to review detections
```

**Expected output**:
- CSV with columns: ID, Path, Group, Type, Reason, Size, Recommendation
- Duplicate groups (Hamming ≤8)
- Similar groups (Hamming 9-18)
- Useless photos (blur, flat, black, white, finger, burst)

## Step 2: Transfer to macOS

Copy the entire `PhotoSweeper` folder to your Mac:

```bash
# Option 1: USB drive
# Copy folder to USB → Transfer to Mac

# Option 2: Cloud sync (OneDrive, Google Drive, iCloud)
# Upload folder → Download on Mac

# Option 3: Git (recommended)
cd C:\Users\hugo\PhotoSweeper
git init
git add .
git commit -m "Initial PhotoSweeper MVP"
git remote add origin https://github.com/yourusername/PhotoSweeper.git
git push -u origin main

# On Mac:
# git clone https://github.com/yourusername/PhotoSweeper.git
```

## Step 3: Build PhotoSweeperCore Package (macOS)

Open Terminal on Mac:

```bash
cd PhotoSweeper/PhotoSweeperCore
swift build
swift test
```

**Expected output**:
```
Build complete! (XX.XXs)
Test Suite 'All tests' passed at 2025-01-19 XX:XX:XX.
     Executed 15 tests, with 0 failures (0 unexpected) in X.XXX seconds
```

If tests fail, check error messages. Common issues:
- Missing dependencies → `swift package resolve`
- Syntax errors → Fix indicated file/line

## Step 4: Create Xcode Project (macOS)

Follow detailed instructions in:
- `PhotoSweeperApp/XCODE_SETUP.md`

**Quick version**:

1. Open Xcode
2. File → New → Project → iOS App
3. Product Name: **PhotoSweeperApp**
4. Interface: **SwiftUI**
5. Save to `PhotoSweeper/PhotoSweeperApp/`
6. Add local package dependency:
   - Project settings → General → Frameworks
   - Add `../PhotoSweeperCore`
7. Copy Swift files from `PhotoSweeperApp/PhotoSweeperApp/` into project
8. Configure capabilities:
   - Photos library access
   - Background modes
   - Push notifications
9. Add StoreKit config (see `StoreKit/STOREKIT_SETUP.md`)

## Step 5: Run on iPhone (macOS)

1. Connect iPhone via USB (iOS 17+)
2. Select device in Xcode toolbar
3. Build & Run (⌘R)
4. On iPhone:
   - Settings → General → VPN & Device Management
   - Trust your developer profile
5. Enable Developer Mode (iOS 16+):
   - Settings → Privacy & Security → Developer Mode

**First launch**:
- Grant photo library access
- Complete onboarding
- Start scan → Wait for results
- Review duplicates/similars/useless photos
- Test paywall (free in simulator)
- Test deletion (moves to Recently Deleted)

## Troubleshooting

### Python Script Issues

**"No images found"**
→ Check folder path, ensure it contains .jpg/.png files

**"ModuleNotFoundError: No module named 'cv2'"**
→ Run: `pip install opencv-python pillow numpy imagehash`

**"Permission denied"**
→ Run CMD/PowerShell as Administrator

### Swift Package Issues

**"Package.resolved is corrupted"**
→ Delete `Package.resolved`, run `swift package resolve`

**"error: failed to fetch"**
→ Check internet connection, retry

### Xcode Issues

**"Missing package product 'PhotoSweeperCore'"**
→ File → Packages → Reset Package Caches

**"Developer certificate not trusted"**
→ Install free profile via Xcode → Settings → Accounts

**"App installation failed"**
→ Delete old app from device, clean build (⌘⇧K), retry

### Runtime Issues

**"This app requires access to Photos"**
→ Settings → PhotoSweeper → Photos → Full Access

**"Background task not running"**
→ Background tasks are scheduled by iOS (not immediate)
→ Simulate: Debug → Simulate Background Fetch

**"Purchase failed"**
→ Ensure StoreKit config selected in scheme options

## Testing Checklist

Print this checklist and verify each item:

### Core Package
- [ ] `swift build` succeeds
- [ ] `swift test` passes (15 tests)
- [ ] pHash test: identical images → identical hashes
- [ ] Laplacian test: uniform image → low variance (blurry)
- [ ] Entropy test: uniform image → low entropy (flat)
- [ ] Clustering test: creates duplicate groups

### iOS App
- [ ] App launches without crash
- [ ] Onboarding: 2 screens display
- [ ] Permission: authorization dialog appears
- [ ] Scan: starts and shows progress %
- [ ] Scan: continues in background (lock device, unlock → still running)
- [ ] Results: Duplicates tab shows groups
- [ ] Results: Useless photos tab shows categorized lists
- [ ] Selection: toggle checkboxes works
- [ ] Savings: "Libérer X,XX Go" displays correctly
- [ ] Paywall: "Acheter maintenant" shows €12.99
- [ ] Purchase: StoreKit dialog appears (simulated)
- [ ] Deletion: moves to Recently Deleted (verify in Photos app)
- [ ] Success: "Ouvrir 'Supprimés récemment'" button works

### Python Prototype
- [ ] Runs without errors
- [ ] Detects duplicates (check CSV: Hamming ≤8)
- [ ] Detects similars (check CSV: Hamming 9-18)
- [ ] Detects blur (check CSV: BLUR label)
- [ ] Exports CSV with all columns

## Next Steps

### Immediate (Pre-Production)
1. Create professional app icon (1024x1024)
2. Capture App Store screenshots (6.7", 6.5", 5.5")
3. Test on multiple devices
4. Configure App Store Connect product

### Future Enhancements
1. Add iPad support
2. Implement ML-based duplicate detection (Core ML)
3. Add cloud backup reminder
4. Support video deduplication
5. Add statistics dashboard

## Support

If you encounter issues:

1. Check error message in Xcode console
2. Review `PROJECT_STRUCTURE.md` for file list
3. Consult Apple Developer Forums
4. Review `README.md` for algorithm details

## Success Criteria

You'll know the MVP is complete when:
- ✅ Python script detects duplicates in test folder
- ✅ Swift package builds and tests pass
- ✅ iOS app runs on physical iPhone
- ✅ Full flow works: Onboarding → Scan → Results → Paywall → Deletion
- ✅ Deleted photos appear in "Supprimés récemment"

---

**MVP Status**: ✅ Code Complete
**Next Milestone**: Xcode Compilation on macOS
**Target**: App Store Submission-Ready

Good luck! 🚀
