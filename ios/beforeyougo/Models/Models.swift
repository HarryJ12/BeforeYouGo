import Foundation

// MARK: - User
struct UserProfile: Codable {
    var name: String
    var dateOfBirth: Date
    var location: String
    var path: String // "healthkit" or "journal"
    var insuranceInfo: InsuranceInfo?
    var medications: [Medication]
    var conditions: [String]
}

// MARK: - Health Metric
struct HealthMetric: Identifiable {
    let id = UUID()
    let type: MetricType
    let value: Double
    let unit: String
    let trend: Trend
    let status: MetricStatus
    let history: [MetricDataPoint]
    
    enum MetricType: String, CaseIterable {
        case heartRate = "Heart Rate"
        case steps = "Steps"
        case sleep = "Sleep"
        case bloodPressure = "Blood Pressure"
        case weight = "Weight"
        
        var icon: String {
            switch self {
            case .heartRate: return "heart.fill"
            case .steps: return "figure.walk"
            case .sleep: return "moon.fill"
            case .bloodPressure: return "waveform.path.ecg"
            case .weight: return "scalemass.fill"
            }
        }
    }
    
    enum Trend {
        case up, down, stable
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
    }
    
    enum MetricStatus {
        case normal, watch, concerning
        var color: String {
            switch self {
            case .normal: return "byg_success"
            case .watch: return "byg_caution"
            case .concerning: return "byg_urgent"
            }
        }
    }
}

struct MetricDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Appointment
struct Appointment: Identifiable, Codable {
    let id: UUID
    var doctorName: String
    var specialty: String
    var date: Date
    var time: String
    var reason: String
    var location: String
    var isCompleted: Bool
    var prep: AppointmentPrep?
    var postVisitSummary: PostVisitSummary?
    
    init(id: UUID = UUID(), doctorName: String, specialty: String = "", date: Date, time: String, reason: String, location: String = "", isCompleted: Bool = false, prep: AppointmentPrep? = nil, postVisitSummary: PostVisitSummary? = nil) {
        self.id = id
        self.doctorName = doctorName
        self.specialty = specialty
        self.date = date
        self.time = time
        self.reason = reason
        self.location = location
        self.isCompleted = isCompleted
        self.prep = prep
        self.postVisitSummary = postVisitSummary
    }
    
    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }
    
    var isWithinPrepWindow: Bool {
        daysUntil >= 0 && daysUntil <= 7
    }
}

struct AppointmentPrep: Codable {
    var whatToMention: [String]
    var questionsToAsk: [String]
    var summary: String
}

struct PostVisitSummary: Codable {
    var rawText: String
    var whatDoctorFound: String
    var whatThisMeans: String
    var whatToDo: String
}

// MARK: - Journal Entry
struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var mood: String
    var symptoms: [String]
    var activities: [String]
    var notes: String
    var aiSummary: String
    
    init(id: UUID = UUID(), date: Date = Date(), mood: String = "", symptoms: [String] = [], activities: [String] = [], notes: String = "", aiSummary: String = "") {
        self.id = id
        self.date = date
        self.mood = mood
        self.symptoms = symptoms
        self.activities = activities
        self.notes = notes
        self.aiSummary = aiSummary
    }
}

// MARK: - Chat Message
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp: Date
    
    enum Role {
        case user, assistant
    }
    
    init(role: Role, content: String, timestamp: Date = Date()) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - Provider
struct Provider: Identifiable, Codable {
    let id: UUID
    var name: String
    var specialty: String
    var distance: Double
    var rating: Double
    var acceptsInsurance: Bool
    var address: String
    var phone: String
    var latitude: Double
    var longitude: Double
    
    init(id: UUID = UUID(), name: String, specialty: String, distance: Double, rating: Double, acceptsInsurance: Bool, address: String, phone: String, latitude: Double = 0, longitude: Double = 0) {
        self.id = id
        self.name = name
        self.specialty = specialty
        self.distance = distance
        self.rating = rating
        self.acceptsInsurance = acceptsInsurance
        self.address = address
        self.phone = phone
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Insurance
struct InsuranceInfo: Codable {
    var provider: String
    var planName: String
    var memberID: String
    var groupNumber: String
    var frontImageData: Data?
    var backImageData: Data?
}

// MARK: - Medication
struct Medication: Identifiable, Codable {
    let id: UUID
    var name: String
    var dosage: String
    var frequency: String
    var reminderTimes: [Date] // times of day to take it
    var isReminderEnabled: Bool
    
    init(id: UUID = UUID(), name: String, dosage: String, frequency: String, reminderTimes: [Date] = [], isReminderEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.reminderTimes = reminderTimes
        self.isReminderEnabled = isReminderEnabled
    }
    
    /// Next upcoming reminder time today or tomorrow
    var nextReminderDate: Date? {
        let calendar = Calendar.current
        let now = Date()
        
        // Check each reminder time — find the next one that hasn't passed yet today
        let todayDates: [Date] = reminderTimes.compactMap { time in
            let components = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: now)
        }.sorted()
        
        // Find next time today
        if let next = todayDates.first(where: { $0 > now }) {
            return next
        }
        
        // Otherwise first time tomorrow
        if let first = todayDates.first, let tomorrow = calendar.date(byAdding: .day, value: 1, to: first) {
            return tomorrow
        }
        
        return nil
    }
}

// MARK: - AI Insight
struct AIInsight: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let icon: String
    let accentColor: String
}
