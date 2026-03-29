# BeforeYouGo (BYG) - Your Health Companion

<div align="center">

**Understand your body, prepare for visits, take control.**

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-brightgreen.svg)](https://developer.apple.com/xcode/swiftui/)
[![HealthKit](https://img.shields.io/badge/HealthKit-Integrated-red.svg)](https://developer.apple.com/healthkit/)

</div>

---

## Overview

**BeforeYouGo** is an innovative iOS health companion app that empowers users to take control of their health journey. By combining real-time Apple Health tracking, AI-powered insights, and intelligent appointment preparation, BYG bridges the gap between patients and healthcare providers.

### Core Mission
- **Track** your health metrics automatically via Apple Health or through daily check-ins
- **Understand** your body with AI-powered analysis and insights
- **Prepare** for doctor appointments with personalized briefings
- **Control** your health journey with comprehensive data management

---

## Key Features

### Smart Health Tracking
- **HealthKit Integration**: Automatic tracking of heart rate, steps, sleep, weight, and blood pressure from Apple Health
- **Dual Path Support**: Works with or without Apple Watch/wearables
- **Daily Check-Ins**: AI-powered conversational health logging
- **Symptom Tracking**: Pattern recognition and frequency analysis
- **Journal Timeline**: Complete history of your health journey

### AI-Powered Insights
- **Comprehensive Health Summary**: Real-time analysis of your Apple Health data
  - Cardiovascular assessment with VO2 Max estimation
  - Sleep quality analysis and efficiency scoring
  - Activity level classification and calorie tracking
  - 7-day trend analysis
- **Personalized Recommendations**: 
  - Custom workout plans (beginner/intermediate/advanced)
  - Cardio training zones (fat burn, cardio, peak)
  - Nutrition targets based on activity level
  - Sleep optimization strategies
- **Conversational AI Assistant**: Ask health questions and get contextual answers

### Intelligent Appointment Management
- **Pre-Appointment Prep**: AI generates personalized briefings using your real health data
  - What to mention to your doctor
  - Questions you should ask
  - Summary of recent health trends
- **Post-Visit Processing**: Upload doctor notes or prescriptions
  - AI extracts key information
  - Organizes into "What doctor found," "What this means," "What to do"
- **Appointment Tracking**: Never miss a visit with smart reminders

### Medication & Health Management
- **Medication Tracker**: Schedule reminders with custom times
- **Condition Logging**: Track chronic conditions and symptoms
- **Insurance Card Scanner**: AI-powered extraction of insurance details
- **Provider Search**: Find doctors by specialty, distance, and insurance acceptance

### Privacy & Security
- **HealthKit Permissions**: Granular control over data access
- **Local-First Architecture**: Critical health data stored on-device
- **HIPAA-Conscious Design**: Built with healthcare privacy standards in mind
- **Optional Backend Sync**: Choose what data to share with our secure backend

---

## User Experience

### Onboarding Flow
1. **Login/Signup**: Email and password authentication
2. **Profile Picture**: Camera capture
3. **Path Selection**: Choose wearable or non-wearable tracking
4. **Profile Setup**: Name, date of birth
5. **Location**: Auto-detect via GPS or manual entry (used to find nearby providers)
6. **Body Metrics**: Height, weight, gender, activity level
7. **Insurance Card**: Camera scan with AI-powered OCR extraction

### Main Navigation
- **Home Tab**: Greeting with profile picture, health snapshot, quick stats (HealthKit users), medication reminders, upcoming appointments, AI insights
- **Health Tab**: Metrics dashboard, daily check-ins, health summary, journal timeline
- **Appointments Tab**: Appointment list, AI-powered prep tools, post-visit OCR upload and translation
- **Care Tab**: Provider search with specialty, distance, and insurance filters
- **Profile Tab**: Settings, medications, conditions, insurance info, account management

---

## Technical Stack

### iOS Development
- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with Combine
- **Concurrency**: Swift Async/Await
- **Data Persistence**: UserDefaults + backend sync
- **Networking**: URLSession with custom async API layer

### Apple Frameworks
- **HealthKit**: Real-time health data access (heart rate, steps, sleep, weight, blood pressure)
- **CoreLocation**: Location services and geocoding for provider search
- **Vision**: On-device OCR for document scanning
- **PhotosUI**: Camera integration for profile pictures and document capture
- **UserNotifications**: Medication and appointment reminders

### Backend Integration
- **API**: RESTful Laravel 13 backend with SQLite
- **AI Services**: OpenAI GPT-4o for health analysis, appointment prep, chat, and OCR
- **Image Processing**: GPT-4o Vision for insurance cards and medical documents
- **Provider Search**: Haversine distance calculation with 18 seeded providers near Lowell, MA
- **Data Sync**: Real-time health data synchronization

### Design System
- **Color Palette**: Bevel Health-inspired theme (primary blue, accent green, success, caution, urgent)
- **Typography**: SF Pro with Dynamic Type support
- **Components**: Reusable cards, buttons, chat bubbles, and form elements
- **Accessibility**: VoiceOver support, high contrast, 44pt minimum tap targets

---

## Health Data

### Metrics Tracked
| Metric | Source | Frequency |
|--------|--------|-----------|
| Heart Rate | Apple Health | Real-time |
| Steps | Apple Health | Daily |
| Sleep | Apple Health | Nightly |
| Weight | Apple Health | On-demand |
| Blood Pressure | Apple Health | Manual |
| Mood | User Input | Daily |
| Symptoms | User Input | As needed |

### AI Analysis Generated From Your Data
- **Cardiovascular Fitness**: VO2 Max, resting HR trends, training zones
- **Activity Analysis**: Step goals, calorie burn, activity classification
- **Sleep Quality**: Duration, efficiency, recovery impact
- **Mental Health**: Mood patterns, symptom correlations
- **Workout Recommendations**: Personalized plans based on your fitness level
- **Nutrition Guidance**: Calorie targets, macros, hydration goals

---

## Getting Started

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
open BeforeYouGo.xcodeproj
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

5. **Update Info.plist**
Add required permissions:
```xml
<key>NSHealthShareUsageDescription</key>
<string>BeforeYouGo needs access to your health data to provide personalized insights and track your wellness journey.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>BeforeYouGo can write health data to help you track your progress.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>BeforeYouGo uses your location to find nearby healthcare providers.</string>

<key>NSCameraUsageDescription</key>
<string>BeforeYouGo needs camera access to scan insurance cards and capture documents.</string>
```

6. **Build and Run**
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

## Team

### BeforeYouGo Development Team

| Role | Name | Responsibilities |
|------|------|-----------------|
| **iOS Development & HealthKit Integration** | Jordi | SwiftUI architecture, HealthKit integration, data sync, app navigation |
| **UI/UX Design** | Krish | Interface design, user flows, design system, accessibility |
| **Backend & AI Integration** | Sam & Harry | Laravel API, AI model integration, OCR, data processing |

---

## Project Structure

```
beforeyougo/
├── app/                               # Laravel backend
│   ├── Http/Controllers/              # API controllers (23 endpoints)
│   ├── Models/                        # Eloquent models
│   └── Services/                      # AI & OCR services
├── beforeyougo/                       # iOS Xcode project
│   ├── App/
│   │   ├── BeforeYouGoApp.swift       # Entry point, LoginView, AppState, LocationManager
│   │   ├── DesignSystem.swift         # Colors, card styles, button styles
│   │   └── MainTabView.swift          # 5-tab navigation
│   ├── Services/
│   │   ├── BackendAPIService.swift    # Laravel API client (all 23 endpoints)
│   │   ├── HealthKitManager.swift     # Apple Health data access
│   │   ├── MedicationManager.swift    # Local med reminders + notifications
│   │   └── OCRService.swift           # Vision framework OCR
│   ├── ViewModels/
│   │   ├── AppointmentViewModel.swift # Appointments + RAG prep + OCR upload
│   │   ├── HealthViewModel.swift      # Health metrics + AI insights
│   │   └── JournalViewModel.swift     # AI journal chat
│   ├── Models/
│   │   └── Models.swift               # All Codable data models
│   ├── Components/
│   │   └── Components.swift           # MetricCard, AppointmentCard, ChatBubble, etc.
│   └── Views/
│       ├── Onboarding/                # 6-step onboarding with PFP + insurance scan
│       ├── Home/                      # Dashboard with conditional HealthKit stats
│       ├── Health/                    # Unified health tab + journal chat
│       ├── Appointments/              # Prep generation + post-visit OCR translation
│       ├── Care/                      # Provider search from backend
│       └── Profile/                   # Settings, meds, conditions, logout
└── database/
    ├── migrations/                    # Schema for all 10+ tables
    └── seeders/                       # 18 real providers near Lowell, MA
```

---

## Data Flow

### Apple Health Data Collection
```
Apple Health → HealthKitManager → BackendAPIService → Laravel API → Database
                    ↓
             Local Display (SwiftUI Views)
```

### AI Health Summary Generation
```
User Request → BackendAPIService
    ↓
Fetch Apple Health Data + Journal Entries + Medications + Conditions
    ↓
GPT-4o Generates Comprehensive Analysis
    ↓
Display in Health Summary View
```

### Appointment Prep Workflow (RAG)
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
GPT-4o Generates Personalized Prep
    ↓
Returns: "What to Mention" + "Questions to Ask" + Summary
    ↓
User Reviews & Shares Before Visit
    ↓
Post-Visit: Camera Capture Doctor Notes
    ↓
GPT-4o Vision OCR + Medical Jargon Translation
    ↓
Displays: "What Doctor Found" + "What This Means" + "What to Do"
```

---

## Future Roadmap

### Phase 1: MVP (Complete)
- [x] Apple Health integration
- [x] Daily AI check-ins
- [x] Appointment management with AI prep
- [x] Post-visit OCR and translation
- [x] AI health insights
- [x] Insurance card scanning
- [x] Medication reminders with notifications
- [x] Provider search with distance + insurance filters
- [x] Login/signup with email
- [x] Profile picture
- [x] Location-based provider search

### Phase 2: Enhanced Features
- [ ] Apple Watch companion app
- [ ] Health data export (PDF reports)
- [ ] Family sharing and care coordination
- [ ] Integration with EHR systems
- [ ] Multi-language support (Spanish, Mandarin)

### Phase 3: Advanced AI
- [ ] Predictive health insights
- [ ] Personalized health goals
- [ ] Symptom checker with differential diagnosis
- [ ] Real-time vitals monitoring

### Phase 4: Platform Expansion
- [ ] iPad optimization
- [ ] Web portal for healthcare providers
- [ ] Telemedicine integration
- [ ] API for third-party integrations

---

**Built with care by the BeforeYouGo Team at ViTAL Hacks 2026**

*Empowering patients, one health insight at a time*

</div>
# BeforeYouGo
