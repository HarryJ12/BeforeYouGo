import SwiftUI

struct ProfileTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var medManager = MedicationManager.shared
    @State private var conditions: [String] = []
    @State private var showAddMedication = false
    @State private var showAddCondition = false
    @State private var newCondition = ""
    @State private var notificationsEnabled = true
    
    var body: some View {
        NavigationStack {
            List {
                // User Info
                                Section {
                                    HStack(spacing: 16) {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 56))
                                            .foregroundColor(.byg_primary)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(appState.userName.isEmpty ? "User" : appState.userName)
                                                .font(.title3.bold())
                                                .foregroundColor(.byg_textPrimary)
                                            Text(appState.userLocation.isEmpty ? "Location not set" : appState.userLocation)
                                                .font(.subheadline)
                                                .foregroundColor(.byg_textSecondary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    
                                    if !appState.userGender.isEmpty {
                                        HStack {
                                            Text("Gender")
                                            Spacer()
                                            Text(appState.userGender).foregroundColor(.byg_textSecondary)
                                        }
                                    }
                                    HStack {
                                        Text("Height")
                                        Spacer()
                                        Text(appState.heightDisplay).foregroundColor(.byg_textSecondary)
                                    }
                                    HStack {
                                        Text("Weight")
                                        Spacer()
                                        Text(appState.weightDisplay).foregroundColor(.byg_textSecondary)
                                    }
                                    if !appState.userLifestyle.isEmpty {
                                        HStack {
                                            Text("Activity Level")
                                            Spacer()
                                            Text(appState.userLifestyle).foregroundColor(.byg_textSecondary)
                                        }
                                    }
                                }
                
                // Medications with reminders
                Section("My Medications") {
                    ForEach(medManager.medications) { med in
                        MedicationRow(medication: med)
                    }
                    .onDelete { offsets in
                        medManager.removeMedication(at: offsets)
                    }
                    
                    Button(action: { showAddMedication = true }) {
                        Label("Add Medication", systemImage: "plus.circle.fill")
                            .foregroundColor(.byg_primary)
                    }
                }
                
                // Conditions
                Section("My Conditions") {
                    ForEach(conditions, id: \.self) { condition in
                        Text(condition)
                    }
                    .onDelete { indexSet in
                        conditions.remove(atOffsets: indexSet)
                    }
                    
                    Button(action: { showAddCondition = true }) {
                        Label("Add Condition", systemImage: "plus.circle.fill")
                            .foregroundColor(.byg_primary)
                    }
                }
                
                // Settings
                Section("Settings") {
                    Toggle("Notifications", isOn: $notificationsEnabled)
                        .tint(.byg_primary)
                        .onChange(of: notificationsEnabled) { enabled in
                            if enabled {
                                medManager.requestNotificationPermission()
                                medManager.rescheduleAll()
                            } else {
                                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            }
                        }
                    
                    if appState.userPath == .healthKit {
                        NavigationLink("HealthKit Permissions") {
                            Text("Manage HealthKit permissions in Settings > Privacy > Health")
                                .padding()
                        }
                    }
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (MVP)")
                            .foregroundColor(.byg_textSecondary)
                    }
                    
                    HStack {
                        Text("Built at")
                        Spacer()
                        Text("ViTAL Hacks 2026")
                            .foregroundColor(.byg_textSecondary)
                    }
                }
                
                // Reset
                Section {
                    Button(action: {
                        appState.hasCompletedOnboarding = false
                    }) {
                        Text("Reset Onboarding")
                            .foregroundColor(.byg_urgent)
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showAddMedication) {
                AddMedicationSheet()
                    .environmentObject(medManager)
            }
            .alert("Add Condition", isPresented: $showAddCondition) {
                TextField("Condition name", text: $newCondition)
                Button("Add") {
                    if !newCondition.isEmpty {
                        conditions.append(newCondition)
                        newCondition = ""
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                medManager.requestNotificationPermission()
            }
        }
    }
}

// MARK: - Medication Row
struct MedicationRow: View {
    let medication: Medication
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.body.weight(.medium))
                Text("\(medication.dosage) — \(medication.frequency)")
                    .font(.caption)
                    .foregroundColor(.byg_textSecondary)
                
                if !medication.reminderTimes.isEmpty && medication.isReminderEnabled {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundColor(.byg_primary)
                        Text(medication.reminderTimes.map { $0.formatted(date: .omitted, time: .shortened) }.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(.byg_primary)
                    }
                }
            }
            
            Spacer()
            
            if medication.isReminderEnabled && !medication.reminderTimes.isEmpty {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(.byg_primary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Add Medication Sheet
struct AddMedicationSheet: View {
    @EnvironmentObject var medManager: MedicationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = "Once daily"
    @State private var enableReminder = true
    @State private var reminderTimes: [Date] = [defaultMorningTime()]
    
    let frequencies = ["Once daily", "Twice daily", "Three times daily", "As needed", "Weekly"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    TextField("Name (e.g., Ibuprofen)", text: $name)
                    TextField("Dosage (e.g., 200mg)", text: $dosage)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { freq in
                            Text(freq).tag(freq)
                        }
                    }
                    .onChange(of: frequency) { newFreq in
                        adjustTimesForFrequency(newFreq)
                    }
                }
                
                Section("Reminders") {
                    Toggle("Enable Reminders", isOn: $enableReminder)
                        .tint(.byg_primary)
                    
                    if enableReminder {
                        ForEach(Array(reminderTimes.enumerated()), id: \.offset) { index, time in
                            DatePicker(
                                "Dose \(index + 1)",
                                selection: Binding(
                                    get: { reminderTimes[index] },
                                    set: { reminderTimes[index] = $0 }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                        }
                        
                        if reminderTimes.count < 4 {
                            Button(action: {
                                // Add a new time 8 hours after the last one
                                let last = reminderTimes.last ?? Date()
                                let next = Calendar.current.date(byAdding: .hour, value: 8, to: last) ?? Date()
                                reminderTimes.append(next)
                            }) {
                                Label("Add Reminder Time", systemImage: "plus.circle")
                                    .foregroundColor(.byg_primary)
                            }
                        }
                        
                        if reminderTimes.count > 1 {
                            Button(action: { reminderTimes.removeLast() }) {
                                Label("Remove Last Time", systemImage: "minus.circle")
                                    .foregroundColor(.byg_urgent)
                            }
                        }
                    }
                }
                
                Section {
                    Text("You'll receive a push notification at each scheduled time as a reminder to take your medication.")
                        .font(.caption)
                        .foregroundColor(.byg_textSecondary)
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let med = Medication(
                            name: name,
                            dosage: dosage,
                            frequency: frequency,
                            reminderTimes: enableReminder ? reminderTimes : [],
                            isReminderEnabled: enableReminder
                        )
                        medManager.addMedication(med)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func adjustTimesForFrequency(_ freq: String) {
        switch freq {
        case "Once daily":
            reminderTimes = [AddMedicationSheet.defaultMorningTime()]
        case "Twice daily":
            reminderTimes = [
                AddMedicationSheet.defaultMorningTime(),
                AddMedicationSheet.defaultEveningTime()
            ]
        case "Three times daily":
            reminderTimes = [
                AddMedicationSheet.defaultMorningTime(),
                AddMedicationSheet.defaultNoonTime(),
                AddMedicationSheet.defaultEveningTime()
            ]
        default:
            break // keep whatever they have
        }
    }
    
    static func defaultMorningTime() -> Date {
        Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    }
    
    static func defaultNoonTime() -> Date {
        Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date()) ?? Date()
    }
    
    static func defaultEveningTime() -> Date {
        Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    }
}
