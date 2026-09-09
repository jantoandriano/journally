# Play Store Launch — Your To-Do

Code-side prep is done (applicationId, release signing, manifest permission, splash-screen bug, build verified). Everything below needs you.

## 1. Back up the release keystore — do this first
- Files: `android/journally-release.jks` and `android/key.properties`
- Not in git (gitignored on purpose)
- Copy both to a password manager or private cloud storage
- **Lose these = can never update the app on this Play Store listing again**

## 2. Play Console developer account
- Sign up at console.play.google.com
- $25 one-time fee
- ID verification can take minutes to ~1 day

## 3. Privacy policy
- Required: app collects location (geolocator) and photos (camera)
- Needs a public URL (GitHub Pages, Notion public page, anything)
- Ask me to draft the text if you want a starting point

## 4. Store listing assets
- [ ] App icon 512×512 — confirm it's not still the Flutter default logo
- [ ] Feature graphic 1024×500
- [ ] At least 2 phone screenshots
- [ ] Short description (80 chars max)
- [ ] Full description

## 5. Test the build on a device
- Install `build/app/outputs/bundle/release/app-release.aab` (or build an APK) on a real device/emulator
- Verify camera picker still works (permission was just added)
- Verify location features still work

## 6. Play Console forms (fill during upload)
- [ ] Content rating questionnaire
- [ ] Data safety form (declare location + photo data collection)
- [ ] Target audience & content
- [ ] App content (ads declaration, etc.)

## 7. Upload
- Release → Testing → Internal testing → create release → upload the `.aab`
- Add yourself as internal tester, verify install works
- Promote to Production once store listing is complete
