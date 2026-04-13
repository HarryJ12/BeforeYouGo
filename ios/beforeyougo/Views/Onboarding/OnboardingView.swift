import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var selectedPath: UserPath? = nil
    @State private var name = ""
    @State private var dob = Calendar.current.date(byAdding: .year, value: -20, to: Date())!
    @State private var location = ""
    @State private var gender = ""
    @State private var heightFeet = 5
    @State private var heightInches = 8
    @State private var weight = ""
    @State private var lifestyle = ""
    
    let genders = ["Male", "Female", "Non-binary", "Prefer not to say"]
    let lifestyles = ["Sedentary", "Lightly active", "Moderately active", "Very active", "Athlete"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress
            ProgressView(value: Double(currentStep), total: 4)
                .tint(.byg_primary)
                .padding(.horizontal)
                .padding(.top, 8)
            
            TabView(selection: $currentStep) {
                welcomeStep.tag(0)
                pathSelectionStep.tag(1)
                profileStep.tag(2)
                bodyStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
        .background(Color.byg_background)
    }
    
    // MARK: - Welcome
    private var welcomeStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundColor(.byg_primary)
            
            VStack(spacing: 12) {
                Text("BeforeYouGo")
                    .font(.largeTitle.bold())
                    .foregroundColor(.byg_textPrimary)
                
                Text("Your health companion.\nUnderstand your body, prepare for visits, take control.")
                    .font(.body)
                    .foregroundColor(.byg_textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button("Get Started") { withAnimation { currentStep = 1 } }
                .buttonStyle(BYGPrimaryButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
        }
        .padding()
    }
    
    // MARK: - Path Selection
    private var pathSelectionStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("How do you track\nyour health?")
                .font(.title.bold())
                .foregroundColor(.byg_textPrimary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                pathOption(
                    icon: "applewatch",
                    title: "I have a wearable",
                    subtitle: "Connect Apple Health for automatic tracking",
                    path: .healthKit
                )
                
                pathOption(
                    icon: "bubble.left.and.text.bubble.right.fill",
                    title: "I don't have a wearable",
                    subtitle: "AI-powered daily check-ins & manual logging",
                    path: .journal
                )
            }
            
            Spacer()
            
            Button("Continue") {
                if selectedPath == .healthKit {
                    Task {
                        try? await HealthKitManager.shared.requestAuthorization()
                    }
                }
                withAnimation { currentStep = 2 }
            }
            .buttonStyle(BYGPrimaryButtonStyle())
            .disabled(selectedPath == nil)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .padding()
    }
    
    private func pathOption(icon: String, title: String, subtitle: String, path: UserPath) -> some View {
        Button(action: { selectedPath = path }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.byg_primary)
                    .frame(width: 48, height: 48)
                    .background(Color.byg_primary.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.byg_textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.byg_textSecondary)
                }
                
                Spacer()
                
                Image(systemName: selectedPath == path ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(selectedPath == path ? .byg_primary : .byg_textTertiary)
            }
            .padding(16)
            .background(Color.byg_cardBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selectedPath == path ? Color.byg_primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Profile (Name, DOB, Location)
    private var profileStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Tell us about yourself")
                .font(.title.bold())
                .foregroundColor(.byg_textPrimary)
            
            VStack(spacing: 16) {
                formField(label: "Name") {
                    TextField("Your name", text: $name)
                        .padding(14)
                        .background(Color.byg_cardBg)
                        .cornerRadius(12)
                }
                
                formField(label: "Date of Birth") {
                    DatePicker("", selection: $dob, displayedComponents: .date)
                        .labelsHidden()
                        .padding(14)
                        .background(Color.byg_cardBg)
                        .cornerRadius(12)
                }
                
                formField(label: "Location") {
                    TextField("City, State", text: $location)
                        .padding(14)
                        .background(Color.byg_cardBg)
                        .cornerRadius(12)
                }
            }
            
            Spacer()
            
            Button("Next") { withAnimation { currentStep = 3 } }
                .buttonStyle(BYGPrimaryButtonStyle())
                .disabled(name.isEmpty)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
        }
        .padding()
    }
    
    // MARK: - Body & Lifestyle (NEW STEP)
    private var bodyStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("A bit more about you")
                    .font(.title.bold())
                    .foregroundColor(.byg_textPrimary)
                    .padding(.top, 20)
                
                Text("This helps us personalize your health insights and appointment prep.")
                    .font(.subheadline)
                    .foregroundColor(.byg_textSecondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    // Gender
                    formField(label: "Gender") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(genders, id: \.self) { g in
                                    Text(g)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(gender == g ? .white : .byg_textSecondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule()
                                                .fill(gender == g ? Color.byg_primary : Color.byg_cardBg)
                                        )
                                        .onTapGesture { gender = g }
                                }
                            }
                        }
                    }
                    
                    // Height
                    formField(label: "Height") {
                        HStack(spacing: 12) {
                            Picker("Feet", selection: $heightFeet) {
                                ForEach(3...7, id: \.self) { ft in
                                    Text("\(ft) ft").tag(ft)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(10)
                            .background(Color.byg_cardBg)
                            .cornerRadius(12)
                            
                            Picker("Inches", selection: $heightInches) {
                                ForEach(0...11, id: \.self) { inch in
                                    Text("\(inch) in").tag(inch)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(10)
                            .background(Color.byg_cardBg)
                            .cornerRadius(12)
                            
                            Spacer()
                        }
                    }
                    
                    // Weight
                    formField(label: "Weight (lbs)") {
                        TextField("e.g., 165", text: $weight)
                            .keyboardType(.numberPad)
                            .padding(14)
                            .background(Color.byg_cardBg)
                            .cornerRadius(12)
                    }
                    
                    // Lifestyle
                    formField(label: "Activity Level") {
                        VStack(spacing: 8) {
                            ForEach(lifestyles, id: \.self) { level in
                                Button(action: { lifestyle = level }) {
                                    HStack {
                                        Text(lifestyleEmoji(level))
                                        Text(level)
                                            .font(.subheadline)
                                            .foregroundColor(lifestyle == level ? .white : .byg_textPrimary)
                                        Spacer()
                                        if lifestyle == level {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .font(.caption.bold())
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(lifestyle == level ? Color.byg_primary : Color.byg_cardBg)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Button("Finish Setup") {
                    appState.completeOnboarding(
                        name: name,
                        dob: dob,
                        location: location,
                        path: selectedPath ?? .journal,
                        gender: gender,
                        heightFeet: heightFeet,
                        heightInches: heightInches,
                        weight: Double(weight) ?? 0,
                        lifestyle: lifestyle
                    )
                }
                .buttonStyle(BYGPrimaryButtonStyle())
                .disabled(name.isEmpty)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .padding()
        }
    }
    
    // MARK: - Helpers
    private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.byg_textSecondary)
            content()
        }
    }
    
    private func lifestyleEmoji(_ level: String) -> String {
        switch level {
        case "Sedentary": return "🪑"
        case "Lightly active": return "🚶"
        case "Moderately active": return "🏃"
        case "Very active": return "💪"
        case "Athlete": return "🏅"
        default: return "🏃"
        }
    }
}
