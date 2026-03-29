# BeforeYouGo - iOS Health Companion

<div align="center">

**Turn raw health data into actionable insights and show up to appointments prepared**

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-brightgreen.svg)](https://developer.apple.com/xcode/swiftui/)
[![HealthKit](https://img.shields.io/badge/HealthKit-Integrated-red.svg)](https://developer.apple.com/healthkit/)

</div>

---

## Overview

Most patients walk into and out of appointments confused.

Health data exists (Apple Health, wearables), but there's little real interpretation.

Finding providers that accept your insurance is also unnecessarily difficult.

**BeforeYouGo** solves this by turning fragmented health data into:

- clear insights
- meaningful trends
- actionable appointment prep

---

## Key Features

- **Health tracking** (HealthKit: heart rate, sleep, steps, BP)
- **Daily check-ins** (for non-wearable users)
- **Health summaries + trend analysis**
- **Personalized workout & nutrition plans**
- **Appointment prep**: what changed, what matters, what to ask
- **Provider lookup** based on insurance

---

## Tech Stack

### iOS

- Swift 5.9 + SwiftUI
- MVVM + Combine
- Async/Await
- URLSession networking

### Backend

- Laravel (REST API)
- SQLite
- Real-time sync

### Integrations

- HealthKit (health data)
- CoreLocation (provider search)
- Google Maps (lookup)

---

## Setup

### Prerequisites
- iOS 17.0 or later
- Xcode 15.0 or later
- Apple Developer Account (for HealthKit entitlements)
- Backend server running (Laravel API)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/jangel19/beforeyougo.git
cd beforeyougo
```

2. **Open in Xcode**
```bash
open ios/beforeyougo.xcodeproj
```

3. **Configure Backend URL**
Update `BackendAPIService.swift`:
```swift
private let baseURL = "http://YOUR_SERVER_IP:8000"
```

4. **Add HealthKit Capability**
- Select your target in Xcode
- Go to "Signing & Capabilities"
- Click "+ Capability"
- Add "HealthKit"

5. **Build and Run**
- Connect your iPhone (HealthKit requires a physical device)
- Select your device in the Xcode toolbar
- Press Command+R

### Backend Setup
```bash
cd backend/
composer install
cp .env.example .env
# Add your OpenAI API key to .env: OPENAI_API_KEY=your_key
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```
---

## Project Structure
```
beforeyougo/
├── backend/            (Laravel REST API)
│   ├── app/
│   │   ├── Http/Controllers/
│   │   ├── Models/
│   │   └── Services/
│   ├── database/
│   └── routes/
└── ios/                (Swift/SwiftUI app)
    └── beforeyougo/
        ├── Views/
        ├── ViewModels/
        ├── Models/
        └── Services/
```

## Data Flow

### Apple Health Data Collection
```
Apple Health → HealthKitManager → BackendAPIService → Laravel API → Database
                    ↓
             Local Display (SwiftUI Views)
```

### Appointment Prep Workflow (RAG)
```
User Request → BackendAPIService
    ↓
Fetch Apple Health Data + Journal Entries + Medications + Conditions
    ↓
GPT-4o Generates Comprehensive Analysis
    ↓
Display in Health Summary View
```
### Apple Health Data Collection
```
User Creates Appointment
    ↓
Appointment Saved to Backend
    ↓
User Taps "Prepare for Visit"
    ↓
Backend Retrieves: Health data (14 days) + Journal entries (5 recent)
                   + Medications + Conditions + User profile
    ↓
LLM Generates Personalized Prep
    ↓
Returns: "What to Mention" + "Questions to Ask" + Summary
    ↓
User Reviews & Shares Before Visit
    ↓
Post-Visit: User Inputs Notes Manually
    ↓
LLM Processes Notes + Translates Medical Jargon
    ↓
Displays: "What Doctor Found" + "What This Means" + "What to Do"
```

---

## Demo Video

https://www.youtube.com/watch?v=UqvuFMXZHvA&feature=youtu.be

---

## License

Copyright © 2026 BeforeYouGo. All rights reserved.

---

<div align="center">

**Built by the BeforeYouGo Team at ViTAL Hacks 2026**
