import SwiftUI
import Combine

@main
struct BeforeYouGoApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(appState)
            } else {
                OnboardingView()
                    .environmentObject(appState)
            }
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    @Published var userPath: UserPath {
        didSet { UserDefaults.standard.set(userPath.rawValue, forKey: "userPath") }
    }
    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "userName") }
    }
    @Published var userDOB: Date {
        didSet { UserDefaults.standard.set(userDOB, forKey: "userDOB") }
    }
    @Published var userLocation: String {
        didSet { UserDefaults.standard.set(userLocation, forKey: "userLocation") }
    }
    @Published var userGender: String {
        didSet { UserDefaults.standard.set(userGender, forKey: "userGender") }
    }
    @Published var userHeightFeet: Int {
        didSet { UserDefaults.standard.set(userHeightFeet, forKey: "userHeightFeet") }
    }
    @Published var userHeightInches: Int {
        didSet { UserDefaults.standard.set(userHeightInches, forKey: "userHeightInches") }
    }
    @Published var userWeight: Double {
        didSet { UserDefaults.standard.set(userWeight, forKey: "userWeight") }
    }
    @Published var userLifestyle: String {
        didSet { UserDefaults.standard.set(userLifestyle, forKey: "userLifestyle") }
    }
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        let pathRaw = UserDefaults.standard.string(forKey: "userPath") ?? "journal"
        self.userPath = UserPath(rawValue: pathRaw) ?? .journal
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.userDOB = UserDefaults.standard.object(forKey: "userDOB") as? Date ?? Date()
        self.userLocation = UserDefaults.standard.string(forKey: "userLocation") ?? ""
        self.userGender = UserDefaults.standard.string(forKey: "userGender") ?? ""
        self.userHeightFeet = UserDefaults.standard.integer(forKey: "userHeightFeet")
        self.userHeightInches = UserDefaults.standard.integer(forKey: "userHeightInches")
        self.userWeight = UserDefaults.standard.double(forKey: "userWeight")
        self.userLifestyle = UserDefaults.standard.string(forKey: "userLifestyle") ?? ""
    }
    
    func completeOnboarding(name: String, dob: Date, location: String, path: UserPath, gender: String, heightFeet: Int, heightInches: Int, weight: Double, lifestyle: String) {
        self.userName = name
        self.userDOB = dob
        self.userLocation = location
        self.userPath = path
        self.userGender = gender
        self.userHeightFeet = heightFeet
        self.userHeightInches = heightInches
        self.userWeight = weight
        self.userLifestyle = lifestyle
        self.hasCompletedOnboarding = true
    }
    
    var heightDisplay: String {
        if userHeightFeet > 0 {
            return "\(userHeightFeet)'\(userHeightInches)\""
        }
        return "Not set"
    }
    
    var weightDisplay: String {
        userWeight > 0 ? "\(Int(userWeight)) lbs" : "Not set"
    }
}

enum UserPath: String {
    case healthKit = "healthkit"
    case journal = "journal"
}
