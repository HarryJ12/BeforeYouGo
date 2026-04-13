# BeforeYouGo - iOS MVP Setup Guide
## ViTAL Hacks 2026

### Quick Start (5 minutes to running app)

---

## Step 1: Create Xcode Project

1. Open Xcode → **File → New → Project**
2. Select **iOS → App**
3. Configure:
   - **Product Name**: `BeforeYouGo`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Minimum Deployments**: iOS 16.0
4. Click **Create**

## Step 2: Add Capabilities

1. Select the project in the navigator (blue icon at top)
2. Select your **target** → **Signing & Capabilities**
3. Click **+ Capability** → Add **HealthKit**

## Step 3: Configure Info.plist

Add these keys to your Info.plist (or Target → Info → Custom iOS Target Properties):

| Key | Value |
|-----|-------|
| `NSHealthShareUsageDescription` | BeforeYouGo needs access to your health data to provide personalized insights and appointment preparation. |
| `NSHealthUpdateUsageDescription` | BeforeYouGo may update your health data based on journal entries. |
| `NSCameraUsageDescription` | BeforeYouGo needs camera access to capture insurance cards and appointment summaries. |
| `NSPhotoLibraryUsageDescription` | BeforeYouGo needs photo access to upload documents. |

## Step 4: Add Source Files

1. **Delete** the auto-generated `ContentView.swift` and `BeforeYouGoApp.swift`
2. In Xcode, right-click the `BeforeYouGo` folder → **Add Files to "BeforeYouGo"**
3. Navigate to the unzipped `BeforeYouGo/` folder
4. Select **all subfolders** (App, Models, Views, ViewModels, Services, Components)
5. Make sure **"Copy items if needed"** and **"Create groups"** are checked
6. Click **Add**

Alternatively, drag-and-drop the folders into the Xcode project navigator.

## Step 5: Set Your API Key

Open `Services/ClaudeAPIService.swift` and replace:
```swift
private let apiKey = "YOUR_CLAUDE_API_KEY_HERE"
```
with your actual Claude API key.

## Step 6: Set Backend URL (Optional)

If your Laravel backend is running, open `Services/BackendAPIService.swift` and update:
```swift
private let baseURL = "https://api.beforeyougo.app"
```
The app works with mock data even without the backend.

## Step 7: Run

- **Simulator**: Works for everything except HealthKit (mock data will display)
- **Physical Device**: Required for HealthKit + Camera features
  - Connect iPhone via USB
  - Select your device in the Xcode toolbar
  - Press **Cmd+R**

---

## Architecture Overview

```
BeforeYouGo/
├── App/
│   ├── BeforeYouGoApp.swift      # Entry point, AppState, routing
│   ├── DesignSystem.swift        # Colors, card styles, button styles
│   └── MainTabView.swift         # 5-tab navigation
├── Models/
│   └── Models.swift              # All data models
├── Services/
│   ├── ClaudeAPIService.swift    # Claude API integration
│   ├── BackendAPIService.swift   # Laravel API client
│   ├── HealthKitManager.swift    # HealthKit data fetching
│   └── OCRService.swift          # Vision framework OCR
├── ViewModels/
│   ├── AppointmentViewModel.swift # Appointments + prep + OCR
│   ├── HealthViewModel.swift      # Health metrics + insights
│   └── JournalViewModel.swift     # AI journal chat
├── Components/
│   └── Components.swift          # Reusable UI components
└── Views/
    ├── Onboarding/               # Welcome + path selection + profile
    ├── Home/                     # Dashboard
    ├── Health/                   # HealthKit metrics + Journal chat
    ├── Appointments/             # List + prep + post-visit OCR
    ├── Care/                     # Provider search
    └── Profile/                  # Settings + medications
```

## Key Features by Priority

### 1. Appointment Prep (Tab 3 - "Visits")
- Add appointments with doctor, date, time, reason
- **"Prepare for Visit"** button on upcoming appointments (within 7 days)
- Claude AI generates:
  - What to mention (based on health data + journal entries)
  - Questions to ask
  - Summary paragraph
- Share/export prep text

### 2. Post-Visit OCR Translation (Tab 3 - "Visits")
- Camera capture of visit summary paperwork
- Vision framework OCR extracts text
- Claude AI translates medical jargon into:
  - "What the Doctor Found"
  - "What This Means"
  - "What to Do"
- Manual text entry fallback

### 3. AI Journal Chat (Tab 2 - "Health" in Journal mode)
- "Start Daily Check-In" opens conversational AI chat
- Claude asks about mood, symptoms, activities
- Extracts structured data (mood, symptoms, activities)
- Saves to timeline with AI summary
- Quick log option with emoji + symptom tags

### 4. HealthKit Integration (Tab 2 - "Health" in HealthKit mode)
- Reads: steps, heart rate, sleep, weight
- 7-day history charts using Swift Charts
- Color-coded status (green/yellow/red)
- Metric detail view with AI explanation
- Falls back to mock data in simulator

## Demo Tips for Judges

1. **Show the onboarding flow** — path selection is visually clean
2. **Demo appointment prep** — the AI-generated prep is the killer feature
3. **Show post-visit translation** — type in medical jargon, watch it become plain language
4. **Journal chat** — natural conversation feel with structured data extraction
5. **Mock data is pre-loaded** — app looks great out of the box

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Build errors about HealthKit | Make sure HealthKit capability is added in Signing & Capabilities |
| Camera doesn't work in simulator | Expected — use photo library or manual text entry |
| Claude API returns errors | Check API key is set correctly in ClaudeAPIService.swift |
| Charts not rendering | Ensure minimum deployment target is iOS 16.0 |
| "No such module 'Charts'" | Charts is built-in for iOS 16+, clean build folder (Cmd+Shift+K) |
