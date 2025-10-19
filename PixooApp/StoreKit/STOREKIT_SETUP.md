# StoreKit Configuration Setup

The `Pixoo.storekit` file is a JSON configuration for local StoreKit testing. Since it's a binary/proprietary format in Xcode, follow these steps to create it:

## Create in Xcode

1. Open Xcode project
2. File → New → File
3. Select **StoreKit Configuration File**
4. Name: `Pixoo.storekit`
5. Save to `/PixooApp/StoreKit/`

## Configure Product

1. Open `Pixoo.storekit` in Xcode
2. Click **+** → **Add Non-Consumable In-App Purchase**
3. Configure:
   - **Reference Name**: Pixoo Pro Lifetime
   - **Product ID**: `com.pixoo.app.pro.lifetime`
   - **Price**: €12.99 (or local equivalent)
   - **Localization**:
     - **Display Name**: Pixoo Pro
     - **Description**: Débloquez la suppression illimitée pour libérer de l'espace

## Settings

- **Family Sharing**: ❌ Disabled (business decision: lifetime purchase is individual)
- **Content Hosting**: ❌ No
- **Review Information**: (optional for App Store submission)

## Test in Simulator/Device

1. Product → Scheme → Edit Scheme
2. Run → Options
3. **StoreKit Configuration**: Select `Pixoo.storekit`
4. Build & Run
5. Purchases are **free** and **simulated** (no real transaction)

## Production Setup (App Store)

For production release:

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps → Select your app → Features → In-App Purchases
3. Create new Non-Consumable:
   - **Product ID**: `com.pixoo.app.pro.lifetime` (must match code)
   - **Price**: €12.99
   - **Family Sharing**: Disabled
4. Add metadata, screenshots
5. Submit for review with app

## Manual JSON (if needed)

If you need to manually edit the JSON structure:

```json
{
  "identifier" : "Pixoo",
  "nonRenewingSubscriptions" : [],
  "products" : [
    {
      "displayPrice" : "12.99",
      "familyShareable" : false,
      "internalID" : "6670001234",
      "localizations" : [
        {
          "description" : "Débloquez la suppression illimitée",
          "displayName" : "Pixoo Pro",
          "locale" : "fr_FR"
        },
        {
          "description" : "Unlock unlimited deletion",
          "displayName" : "Pixoo Pro",
          "locale" : "en_US"
        }
      ],
      "productID" : "com.pixoo.app.pro.lifetime",
      "referenceName" : "Pixoo Pro Lifetime",
      "type" : "NonConsumable"
    }
  ],
  "settings" : {
    "_applicationInternalID" : "6670000000",
    "_developerTeamID" : "YOUR_TEAM_ID",
    "_lastSynchronizedDate" : 123456789.0
  },
  "subscriptionGroups" : [],
  "version" : {
    "major" : 3,
    "minor" : 0
  }
}
```

**Note**: Xcode manages this file automatically. Manual editing is rarely needed.

## Testing Scenarios

Test these scenarios before release:

- ✅ Purchase flow (tap "Buy" → system dialog → success)
- ✅ Cancel purchase (tap "Buy" → tap "Cancel" in dialog)
- ✅ Restore purchases (if user reinstalls app)
- ✅ Receipt validation (stub implemented in code)
- ✅ Family Sharing disabled (product not shared)

## Family Sharing Decision

**Why disabled?**
- Lifetime purchase model (€12.99 once)
- Individual license (not household)
- Prevents abuse (1 purchase → 6 family members)
- Standard practice for "lifetime" IAPs

Document this clearly in App Store description.
